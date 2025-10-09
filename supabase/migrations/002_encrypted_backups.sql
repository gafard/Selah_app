-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 002 - Table encrypted_backups pour backups cloud chiffrés
-- ═══════════════════════════════════════════════════════════════════════════
-- Date: 2025-10-09
-- Fonctionnalité: Backup cloud chiffré zero-knowledge

-- ───────────────────────────────────────────────────────────────────────────
-- Table: encrypted_backups
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.encrypted_backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Type de backup
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'user', 'plans', 'progress')),
  
  -- Données chiffrées (zero-knowledge)
  encrypted_data TEXT NOT NULL,
  encryption_iv TEXT NOT NULL,
  data_hash TEXT NOT NULL,
  
  -- Métadonnées
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

-- ───────────────────────────────────────────────────────────────────────────
-- Indexes pour performance
-- ───────────────────────────────────────────────────────────────────────────
CREATE INDEX idx_encrypted_backups_user_id 
  ON public.encrypted_backups(user_id);

CREATE INDEX idx_encrypted_backups_created_at 
  ON public.encrypted_backups(created_at DESC);

CREATE INDEX idx_encrypted_backups_user_type 
  ON public.encrypted_backups(user_id, backup_type);

-- ───────────────────────────────────────────────────────────────────────────
-- Row Level Security (RLS)
-- ───────────────────────────────────────────────────────────────────────────
ALTER TABLE public.encrypted_backups ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent gérer leurs propres backups
CREATE POLICY "Users can manage their own backups"
  ON public.encrypted_backups
  FOR ALL
  USING (auth.uid() = user_id);

-- Policy: Insertion seulement pour utilisateurs authentifiés
CREATE POLICY "Authenticated users can create backups"
  ON public.encrypted_backups
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Lecture seulement de ses propres backups
CREATE POLICY "Users can read their own backups"
  ON public.encrypted_backups
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Suppression seulement de ses propres backups
CREATE POLICY "Users can delete their own backups"
  ON public.encrypted_backups
  FOR DELETE
  USING (auth.uid() = user_id);

-- ───────────────────────────────────────────────────────────────────────────
-- Fonction: Nettoyer les anciens backups (> 90 jours)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION cleanup_old_backups()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Supprimer les backups de plus de 90 jours
  DELETE FROM public.encrypted_backups
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$;

-- Commentaire sur la fonction
COMMENT ON FUNCTION cleanup_old_backups() IS 
  'Supprime automatiquement les backups de plus de 90 jours pour économiser l''espace';

-- ───────────────────────────────────────────────────────────────────────────
-- Fonction: Obtenir le dernier backup d'un utilisateur
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_latest_backup(p_user_id UUID, p_backup_type TEXT DEFAULT 'full')
RETURNS TABLE(
  id UUID,
  backup_type TEXT,
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.backup_type,
    b.device_id,
    b.created_at,
    b.metadata
  FROM public.encrypted_backups b
  WHERE b.user_id = p_user_id
    AND (p_backup_type IS NULL OR b.backup_type = p_backup_type)
  ORDER BY b.created_at DESC
  LIMIT 1;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Fonction: Statistiques des backups par utilisateur
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_backup_stats(p_user_id UUID)
RETURNS TABLE(
  total_backups INTEGER,
  last_backup_date TIMESTAMP WITH TIME ZONE,
  backup_types JSONB,
  total_size_estimate INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER AS total_backups,
    MAX(created_at) AS last_backup_date,
    jsonb_object_agg(backup_type, count) AS backup_types,
    SUM(LENGTH(encrypted_data))::INTEGER AS total_size_estimate
  FROM (
    SELECT 
      backup_type,
      COUNT(*) as count,
      created_at,
      encrypted_data
    FROM public.encrypted_backups
    WHERE user_id = p_user_id
    GROUP BY backup_type, created_at, encrypted_data
  ) subquery;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Trigger: Limiter le nombre de backups par utilisateur (max 10)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION limit_backups_per_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  backup_count INTEGER;
  oldest_backup_id UUID;
BEGIN
  -- Compter les backups de l'utilisateur
  SELECT COUNT(*) INTO backup_count
  FROM public.encrypted_backups
  WHERE user_id = NEW.user_id;
  
  -- Si plus de 10 backups, supprimer le plus ancien
  IF backup_count >= 10 THEN
    SELECT id INTO oldest_backup_id
    FROM public.encrypted_backups
    WHERE user_id = NEW.user_id
    ORDER BY created_at ASC
    LIMIT 1;
    
    DELETE FROM public.encrypted_backups
    WHERE id = oldest_backup_id;
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_limit_backups
  AFTER INSERT ON public.encrypted_backups
  FOR EACH ROW
  EXECUTE FUNCTION limit_backups_per_user();

-- ───────────────────────────────────────────────────────────────────────────
-- Vue: Résumé des backups par utilisateur
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW user_backups_summary AS
SELECT 
  user_id,
  COUNT(*) as total_backups,
  MAX(created_at) as last_backup_date,
  MIN(created_at) as first_backup_date,
  array_agg(DISTINCT backup_type) as backup_types,
  array_agg(DISTINCT device_id) as devices
FROM public.encrypted_backups
GROUP BY user_id;

-- ───────────────────────────────────────────────────────────────────────────
-- Commentaires pour documentation
-- ───────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE public.encrypted_backups IS 
  'Backups chiffrés des données utilisateur (zero-knowledge encryption)';

COMMENT ON COLUMN public.encrypted_backups.encrypted_data IS 
  'Données chiffrées AES-256 - Supabase ne peut pas les déchiffrer';

COMMENT ON COLUMN public.encrypted_backups.encryption_iv IS 
  'Initialization Vector pour AES-CBC';

COMMENT ON COLUMN public.encrypted_backups.data_hash IS 
  'Hash SHA-256 pour vérification d''intégrité';

COMMENT ON COLUMN public.encrypted_backups.metadata IS 
  'Métadonnées non chiffrées (version app, plateforme, etc.)';

-- ───────────────────────────────────────────────────────────────────────────
-- Données de test (optionnel - à supprimer en production)
-- ───────────────────────────────────────────────────────────────────────────
-- INSERT INTO public.encrypted_backups (user_id, backup_type, encrypted_data, encryption_iv, data_hash, device_id, metadata)
-- VALUES (
--   auth.uid(),
--   'full',
--   'encrypted_data_base64...',
--   'iv_base64...',
--   'sha256_hash...',
--   'iPhone 15 Pro',
--   '{"app_version": "1.0.0", "platform": "iOS"}'
-- );

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DE LA MIGRATION
-- ═══════════════════════════════════════════════════════════════════════════

