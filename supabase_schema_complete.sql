-- ===================================================
-- SCHÉMA SUPABASE COMPLET POUR SELAH APP
-- ===================================================
-- À exécuter dans le SQL Editor de votre dashboard Supabase
-- ===================================================

-- ===================================================
-- 1. NETTOYAGE PRÉALABLE (optionnel si tables existent)
-- ===================================================

-- Supprimer toutes les tables existantes
DROP TABLE IF EXISTS public.reading_sessions CASCADE;
DROP TABLE IF EXISTS public.plan_days CASCADE;
DROP TABLE IF EXISTS public.plans CASCADE;
DROP TABLE IF EXISTS public.plan_presets CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Supprimer les fonctions existantes
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_current_plan(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;

-- Supprimer les triggers existants
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- ===================================================
-- 2. CRÉATION DES TABLES
-- ===================================================

-- Table des utilisateurs (extension de auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    has_onboarded BOOLEAN DEFAULT FALSE,
    current_plan_id UUID, -- Sera lié à plans.id plus tard
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des presets de plans (templates prédéfinis)
CREATE TABLE public.plan_presets (
    id TEXT PRIMARY KEY, -- TEXT pour les IDs comme 'demo_1', 'advanced_1'
    name TEXT NOT NULL,
    short_desc TEXT NOT NULL,
    duration_days INTEGER NOT NULL,
    difficulty TEXT NOT NULL, -- 'Débutant', 'Intermédiaire', 'Avancé'
    parameters JSONB NOT NULL DEFAULT '{}', -- Paramètres pour l'API externe
    has_bp_videos BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des plans générés pour les utilisateurs
CREATE TABLE public.plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    total_days INTEGER NOT NULL,
    raw_content TEXT, -- HTML brut retourné par l'API externe
    parameters JSONB DEFAULT '{}', -- Paramètres utilisés pour générer ce plan
    status TEXT DEFAULT 'active', -- 'active', 'completed', 'paused'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des jours individuels du plan
CREATE TABLE public.plan_days (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plan_id UUID REFERENCES public.plans(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL, -- Jour 1, 2, 3, etc.
    date DATE NOT NULL, -- Date réelle (start_date + day_number - 1)
    bible_references TEXT[] NOT NULL, -- Array des références bibliques
    status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'skipped'
    notes TEXT, -- Notes personnelles de l'utilisateur
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index pour améliorer les performances
    UNIQUE(plan_id, day_number)
);

-- Table des sessions de lecture quotidienne
CREATE TABLE public.reading_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plan_day_id UUID REFERENCES public.plan_days(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    read_content TEXT, -- Contenu lu/réflexions
    is_completed BOOLEAN DEFAULT FALSE,
    notes TEXT, -- Notes de session
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================================
-- 3. FONCTIONS UTILITAIRES
-- ===================================================

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fonction RPC pour mettre à jour le plan actuel d'un utilisateur
-- (Nécessaire pour l'Edge Function car elle contourne RLS)
CREATE OR REPLACE FUNCTION update_user_current_plan(user_id UUID, plan_id UUID)
RETURNS void
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.users
    SET current_plan_id = plan_id,
        updated_at = NOW()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer automatiquement un profil utilisateur
-- lors de l'inscription via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$;

-- ===================================================
-- 4. TRIGGERS
-- ===================================================

-- Trigger pour mettre à jour updated_at sur users
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger pour mettre à jour updated_at sur plans
CREATE TRIGGER plans_updated_at
    BEFORE UPDATE ON public.plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger pour créer automatiquement un profil utilisateur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- ===================================================
-- 5. SÉCURITÉ ROW LEVEL SECURITY (RLS)
-- ===================================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;

-- Politique pour users : chaque utilisateur ne voit que ses données
CREATE POLICY "users_policy" ON public.users 
    FOR ALL USING (auth.uid() = id);

-- Politique pour plan_presets : lecture seule pour tous les utilisateurs connectés
CREATE POLICY "plan_presets_policy" ON public.plan_presets 
    FOR SELECT USING (auth.role() = 'authenticated');

-- Politique pour plans : chaque utilisateur ne voit que ses plans
CREATE POLICY "plans_policy" ON public.plans 
    FOR ALL USING (auth.uid() = user_id);

-- Politique pour plan_days : accès via le plan associé
CREATE POLICY "plan_days_policy" ON public.plan_days 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

-- Politique pour reading_sessions : chaque utilisateur ne voit que ses sessions
CREATE POLICY "reading_sessions_policy" ON public.reading_sessions 
    FOR ALL USING (auth.uid() = user_id);

-- ===================================================
-- 6. CONTRAINTES DE CLÉ ÉTRANGÈRE
-- ===================================================

-- Ajouter la contrainte de clé étrangère pour current_plan_id
-- (doit être ajoutée après la création des tables)
ALTER TABLE public.users 
ADD CONSTRAINT fk_users_current_plan 
FOREIGN KEY (current_plan_id) REFERENCES public.plans(id) 
ON DELETE SET NULL;

-- ===================================================
-- 7. INDEX POUR OPTIMISATION
-- ===================================================

-- Index pour améliorer les performances des requêtes fréquentes
CREATE INDEX idx_plans_user_id ON public.plans(user_id);
CREATE INDEX idx_plan_days_plan_id ON public.plan_days(plan_id);
CREATE INDEX idx_plan_days_date ON public.plan_days(date);
CREATE INDEX idx_reading_sessions_user_id ON public.reading_sessions(user_id);
CREATE INDEX idx_reading_sessions_plan_day_id ON public.reading_sessions(plan_day_id);

-- ===================================================
-- 8. DONNÉES D'EXEMPLE (PLAN PRESETS)
-- ===================================================

INSERT INTO public.plan_presets (id, name, short_desc, duration_days, difficulty, parameters, has_bp_videos) 
VALUES 
    -- Plans pour débutants
    ('demo_1', 'Découverte spirituelle', 'Un parcours de 30 jours pour découvrir les fondements de la foi chrétienne.', 30, 'Débutant', '{"categories": ["Découverte", "Spiritualité"], "books": ["Genèse", "Jean", "Romains"], "order": "traditional"}', false),
    
    ('beginner_1', 'Nouveau Testament en 90 jours', 'Découvrez le message de Jésus en 3 mois.', 90, 'Débutant', '{"categories": ["Évangiles", "Lettres"], "books": ["NT"], "order": "traditional"}', false),
    
    -- Plans intermédiaires
    ('demo_2', 'Sagesse des Proverbes', 'Explorez la sagesse pratique de Salomon en 31 jours.', 31, 'Intermédiaire', '{"categories": ["Sagesse", "Proverbes"], "books": ["Proverbes"], "order": "chronological"}', true),
    
    ('demo_3', 'Les Psaumes de David', 'Un voyage de 60 jours à travers les louanges et prières de David.', 60, 'Intermédiaire', '{"categories": ["Louange", "Prière"], "books": ["Psaumes"], "order": "traditional"}', true),
    
    ('intermediate_1', 'Ancien Testament en 180 jours', 'Parcourez l''histoire du peuple de Dieu en 6 mois.', 180, 'Intermédiaire', '{"categories": ["Histoire", "Prophétie"], "books": ["OT"], "order": "chronological"}', true),
    
    -- Plans avancés
    ('advanced_1', 'Bible complète en 365 jours', 'Parcourez toute la Bible en une année avec un plan structuré.', 365, 'Avancé', '{"categories": ["Chronologique"], "books": ["OT", "NT"], "order": "chronological"}', true),
    
    ('advanced_2', 'Étude thématique approfondie', 'Plan de 120 jours sur des thèmes bibliques spécifiques.', 120, 'Avancé', '{"categories": ["Thématique", "Théologie"], "books": ["OT", "NT"], "order": "thematic"}', true);

-- ===================================================
-- 9. FONCTIONS D'AIDE POUR L'APPLICATION
-- ===================================================

-- Fonction pour obtenir le plan actuel d'un utilisateur avec ses détails
CREATE OR REPLACE FUNCTION get_user_current_plan(user_id UUID)
RETURNS TABLE(
    plan_id UUID,
    plan_name TEXT,
    start_date DATE,
    total_days INTEGER,
    completed_days INTEGER,
    current_day INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.start_date,
        p.total_days,
        (SELECT COUNT(*) FROM public.plan_days pd WHERE pd.plan_id = p.id AND pd.status = 'completed')::INTEGER,
        (EXTRACT(DAY FROM (CURRENT_DATE - p.start_date)) + 1)::INTEGER
    FROM public.plans p
    JOIN public.users u ON u.current_plan_id = p.id
    WHERE u.id = user_id;
END;
$$;

-- Fonction pour obtenir les lectures du jour pour un utilisateur
CREATE OR REPLACE FUNCTION get_today_readings(user_id UUID)
RETURNS TABLE(
    plan_day_id UUID,
    day_number INTEGER,
    bible_references TEXT[],
    status TEXT,
    notes TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pd.id,
        pd.day_number,
        pd.bible_references,
        pd.status,
        pd.notes
    FROM public.plan_days pd
    JOIN public.plans p ON pd.plan_id = p.id
    JOIN public.users u ON u.current_plan_id = p.id
    WHERE u.id = user_id 
    AND pd.date = CURRENT_DATE;
END;
$$;

-- ===================================================
-- SCRIPT TERMINÉ
-- ===================================================
-- Votre base de données Selah est maintenant prête !
-- 
-- Tables créées :
-- - users (profils utilisateurs)
-- - plan_presets (templates de plans)
-- - plans (plans générés)
-- - plan_days (jours individuels)
-- - reading_sessions (sessions de lecture)
--
-- Fonctionnalités :
-- ✅ Authentification automatique
-- ✅ Sécurité RLS
-- ✅ Triggers automatiques
-- ✅ Données d'exemple
-- ✅ Fonctions utilitaires
-- ✅ Index optimisés
-- ===================================================
