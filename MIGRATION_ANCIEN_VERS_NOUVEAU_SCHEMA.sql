-- ═══════════════════════════════════════════════════════════════════════════
-- 🔄 MIGRATION: Ancien Schéma → Nouveau Schéma V2
-- ═══════════════════════════════════════════════════════════════════════════
-- Ce script migre les données de l'ancien schéma vers le nouveau
-- À exécuter APRÈS avoir créé le nouveau schéma
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1️⃣ SAUVEGARDES PRÉALABLES (IMPORTANT !)
-- ═══════════════════════════════════════════════════════════════════════════

-- Créer des tables de backup
CREATE TABLE backup_users_old AS SELECT * FROM public.users;
CREATE TABLE backup_plans_old AS SELECT * FROM public.plans;
CREATE TABLE backup_plan_days_old AS SELECT * FROM public.plan_days;
CREATE TABLE backup_plan_presets_old AS SELECT * FROM public.plan_presets;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2️⃣ MIGRATION DES DONNÉES
-- ═══════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────
-- Migrer users
-- ──────────────────────────────────────────────────────────────────────────
-- Option A: Si table users existe déjà
DO $$
BEGIN
    -- Ajouter nouvelles colonnes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_complete') THEN
        ALTER TABLE public.users ADD COLUMN is_complete BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'spiritual_level') THEN
        ALTER TABLE public.users ADD COLUMN spiritual_level TEXT DEFAULT 'beginner';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'meditation_objectives') THEN
        ALTER TABLE public.users ADD COLUMN meditation_objectives TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'emotional_state') THEN
        ALTER TABLE public.users ADD COLUMN emotional_state TEXT DEFAULT 'neutral';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'bible_version') THEN
        ALTER TABLE public.users ADD COLUMN bible_version TEXT DEFAULT 'LSG';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'preferred_time') THEN
        ALTER TABLE public.users ADD COLUMN preferred_time TIME DEFAULT '07:00';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'daily_minutes') THEN
        ALTER TABLE public.users ADD COLUMN daily_minutes INTEGER DEFAULT 15;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'goals') THEN
        ALTER TABLE public.users ADD COLUMN goals TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'audio_mode') THEN
        ALTER TABLE public.users ADD COLUMN audio_mode BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'last_sync_at') THEN
        ALTER TABLE public.users ADD COLUMN last_sync_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- ──────────────────────────────────────────────────────────────────────────
-- Migrer plans
-- ──────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'minutes_per_day') THEN
        ALTER TABLE public.plans ADD COLUMN minutes_per_day INTEGER DEFAULT 15;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'books') THEN
        ALTER TABLE public.plans ADD COLUMN books TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'specific_books') THEN
        ALTER TABLE public.plans ADD COLUMN specific_books TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'reading_order') THEN
        ALTER TABLE public.plans ADD COLUMN reading_order TEXT DEFAULT 'traditional';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'completed_days') THEN
        ALTER TABLE public.plans ADD COLUMN completed_days INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'current_streak') THEN
        ALTER TABLE public.plans ADD COLUMN current_streak INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'longest_streak') THEN
        ALTER TABLE public.plans ADD COLUMN longest_streak INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'preset_id') THEN
        ALTER TABLE public.plans ADD COLUMN preset_id TEXT REFERENCES public.plan_presets(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'generation_context') THEN
        ALTER TABLE public.plans ADD COLUMN generation_context JSONB DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'completed_at') THEN
        ALTER TABLE public.plans ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plans' AND column_name = 'is_active') THEN
        ALTER TABLE public.plans ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- ──────────────────────────────────────────────────────────────────────────
-- Migrer plan_days
-- ──────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'readings') THEN
        ALTER TABLE public.plan_days ADD COLUMN readings JSONB DEFAULT '[]';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'completed') THEN
        ALTER TABLE public.plan_days ADD COLUMN completed BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'reflection') THEN
        ALTER TABLE public.plan_days ADD COLUMN reflection TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'highlighted_verses') THEN
        ALTER TABLE public.plan_days ADD COLUMN highlighted_verses TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'reading_duration_seconds') THEN
        ALTER TABLE public.plan_days ADD COLUMN reading_duration_seconds INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_days' AND column_name = 'meditation_duration_seconds') THEN
        ALTER TABLE public.plan_days ADD COLUMN meditation_duration_seconds INTEGER;
    END IF;
END $$;

-- ──────────────────────────────────────────────────────────────────────────
-- Migrer plan_presets
-- ──────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'slug') THEN
        ALTER TABLE public.plan_presets ADD COLUMN slug TEXT;
        -- Générer slug depuis id si nécessaire
        UPDATE public.plan_presets SET slug = id WHERE slug IS NULL;
        ALTER TABLE public.plan_presets ALTER COLUMN slug SET NOT NULL;
        CREATE UNIQUE INDEX IF NOT EXISTS idx_plan_presets_slug ON public.plan_presets(slug);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'subtitle') THEN
        ALTER TABLE public.plan_presets ADD COLUMN subtitle TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'books') THEN
        ALTER TABLE public.plan_presets ADD COLUMN books TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'specific_books') THEN
        ALTER TABLE public.plan_presets ADD COLUMN specific_books TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'reading_order') THEN
        ALTER TABLE public.plan_presets ADD COLUMN reading_order TEXT DEFAULT 'traditional';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'recommended_for') THEN
        ALTER TABLE public.plan_presets ADD COLUMN recommended_for TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'categories') THEN
        ALTER TABLE public.plan_presets ADD COLUMN categories TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'cover_image') THEN
        ALTER TABLE public.plan_presets ADD COLUMN cover_image TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'icon') THEN
        ALTER TABLE public.plan_presets ADD COLUMN icon TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'color_hex') THEN
        ALTER TABLE public.plan_presets ADD COLUMN color_hex TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'gradient_colors') THEN
        ALTER TABLE public.plan_presets ADD COLUMN gradient_colors TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'badge') THEN
        ALTER TABLE public.plan_presets ADD COLUMN badge TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'spiritual_impact') THEN
        ALTER TABLE public.plan_presets ADD COLUMN spiritual_impact REAL DEFAULT 0.7;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'timing_bonus') THEN
        ALTER TABLE public.plan_presets ADD COLUMN timing_bonus INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'expected_transformations') THEN
        ALTER TABLE public.plan_presets ADD COLUMN expected_transformations TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'plan_presets' AND column_name = 'minutes_per_day') THEN
        ALTER TABLE public.plan_presets ADD COLUMN minutes_per_day INTEGER DEFAULT 15;
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 3️⃣ MIGRATION DES DONNÉES EXISTANTES
-- ═══════════════════════════════════════════════════════════════════════════

-- Migrer les préférences des users depuis JSONB vers colonnes dédiées
UPDATE public.users
SET 
    bible_version = COALESCE(preferences->>'bible_version', 'LSG'),
    preferred_time = COALESCE((preferences->>'preferred_time')::TIME, '07:00'::TIME),
    daily_minutes = COALESCE((preferences->>'daily_minutes')::INTEGER, 15),
    goals = COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(preferences->'goals')),
        ARRAY['discipline']::TEXT[]
    ),
    audio_mode = COALESCE((preferences->>'audio_mode')::BOOLEAN, TRUE)
WHERE preferences IS NOT NULL;

-- Marquer tous les utilisateurs existants comme "à synchroniser"
UPDATE public.users
SET last_sync_at = NOW()
WHERE last_sync_at IS NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4️⃣ VALIDATION POST-MIGRATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Vérifier nombre d'utilisateurs
DO $$
DECLARE
    v_user_count INTEGER;
    v_backup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_user_count FROM public.users;
    SELECT COUNT(*) INTO v_backup_count FROM backup_users_old;
    
    IF v_user_count != v_backup_count THEN
        RAISE EXCEPTION 'Migration users failed: count mismatch (% vs %)', v_user_count, v_backup_count;
    END IF;
    
    RAISE NOTICE '✅ Users migration OK: % users', v_user_count;
END $$;

-- Vérifier nombre de plans
DO $$
DECLARE
    v_plan_count INTEGER;
    v_backup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_plan_count FROM public.plans;
    SELECT COUNT(*) INTO v_backup_count FROM backup_plans_old;
    
    IF v_plan_count != v_backup_count THEN
        RAISE EXCEPTION 'Migration plans failed: count mismatch (% vs %)', v_plan_count, v_backup_count;
    END IF;
    
    RAISE NOTICE '✅ Plans migration OK: % plans', v_plan_count;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5️⃣ NETTOYAGE POST-MIGRATION (Optionnel)
-- ═══════════════════════════════════════════════════════════════════════════

-- Supprimer les backups après validation (ATTENTION : irréversible !)
-- DROP TABLE backup_users_old;
-- DROP TABLE backup_plans_old;
-- DROP TABLE backup_plan_days_old;
-- DROP TABLE backup_plan_presets_old;

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ MIGRATION TERMINÉE
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Prochaines étapes :
-- 1. Vérifier que l'application fonctionne correctement
-- 2. Tester création/modification de données
-- 3. Vérifier la synchronisation offline-first
-- 4. Monitorer les performances
-- 5. Supprimer les backups après 7 jours si tout va bien
--
-- ═══════════════════════════════════════════════════════════════════════════

