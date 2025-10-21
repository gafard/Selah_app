-- Migration 004: Table users et trigger handle_new_user
-- Création de la table users et du trigger pour créer automatiquement un profil utilisateur

-- ═══════════════════════════════════════════════════════════════════════════
-- Table: users
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  is_complete BOOLEAN DEFAULT false,
  has_onboarded BOOLEAN DEFAULT false,
  current_plan_id UUID REFERENCES public.plans(id),
  bible_version TEXT DEFAULT 'LSG',
  preferred_time TIME DEFAULT '07:00:00',
  daily_minutes INTEGER DEFAULT 15,
  goals TEXT[] DEFAULT '{}',
  audio_mode BOOLEAN DEFAULT true,
  spiritual_level TEXT DEFAULT 'beginner',
  emotional_state TEXT DEFAULT 'neutral',
  meditation_objectives TEXT[] DEFAULT '{}',
  preferences JSONB DEFAULT '{}',
  last_sync_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  onboarded_at TIMESTAMP WITH TIME ZONE
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Indexes pour performance
-- ═══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_current_plan ON public.users(current_plan_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view their own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Users can update their own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Les utilisateurs peuvent insérer leur propre profil
CREATE POLICY "Users can insert their own profile"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ═══════════════════════════════════════════════════════════════════════════
-- Fonction: Créer un profil utilisateur automatiquement
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    display_name,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- Trigger: Créer automatiquement un profil utilisateur
-- ═══════════════════════════════════════════════════════════════════════════
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════════════════════
-- Fonction: Mettre à jour updated_at automatiquement
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.update_users_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Trigger pour updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_users_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════
-- Fonction: Mettre à jour le plan actuel de l'utilisateur
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.update_user_current_plan(
  user_id UUID,
  plan_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Désactiver tous les autres plans de l'utilisateur
  UPDATE public.plans 
  SET is_active = false, updated_at = NOW()
  WHERE user_id = user_id AND id != plan_id;
  
  -- Activer le nouveau plan
  UPDATE public.plans 
  SET is_active = true, updated_at = NOW()
  WHERE id = plan_id;
  
  -- Mettre à jour le current_plan_id de l'utilisateur
  UPDATE public.users 
  SET current_plan_id = plan_id, updated_at = NOW()
  WHERE id = user_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- Commentaires pour documentation
-- ═══════════════════════════════════════════════════════════════════════════
COMMENT ON TABLE public.users IS 'Profils utilisateur étendus avec préférences et progression';
COMMENT ON FUNCTION public.handle_new_user() IS 'Crée automatiquement un profil utilisateur lors de l''inscription';
COMMENT ON FUNCTION public.update_user_current_plan(UUID, UUID) IS 'Met à jour le plan actuel de l''utilisateur et désactive les autres';





