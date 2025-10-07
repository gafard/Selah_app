-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 SCHÉMA SUPABASE COMPLET POUR SELAH APP
-- ═══════════════════════════════════════════════════════════════════════════
-- Version: 2.0 (Offline-First Architecture)
-- Date: 2025-10-07
-- Compatible avec: Flutter Hive + Supabase Sync
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1️⃣ NETTOYAGE PRÉALABLE (Optionnel - seulement si migration)
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: Ordre important - supprimer dans l'ordre inverse des dépendances
-- CASCADE supprime automatiquement les contraintes et policies

-- Supprimer les vues en premier (dépendent des tables)
DROP VIEW IF EXISTS active_plans_with_progress CASCADE;
DROP VIEW IF EXISTS user_quick_stats CASCADE;

-- Supprimer les tables dépendantes en premier
DROP TABLE IF EXISTS public.sync_queue CASCADE;
DROP TABLE IF EXISTS public.notifications_queue CASCADE;
DROP TABLE IF EXISTS public.verse_highlights CASCADE;
DROP TABLE IF EXISTS public.user_progress CASCADE;
DROP TABLE IF EXISTS public.user_analytics CASCADE;
DROP TABLE IF EXISTS public.prayer_subjects CASCADE;
DROP TABLE IF EXISTS public.meditation_journals CASCADE;
DROP TABLE IF EXISTS public.plan_days CASCADE;
DROP TABLE IF EXISTS public.plans CASCADE;
DROP TABLE IF EXISTS public.plan_presets CASCADE;
DROP TABLE IF EXISTS public.bible_versions CASCADE;
DROP TABLE IF EXISTS public.reader_settings CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_current_plan_progress(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_today_reading(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.update_user_streak(UUID) CASCADE;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2️⃣ TABLES PRINCIPALES
-- ═══════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────
-- 👤 TABLE: users
-- Profils utilisateurs (étend auth.users de Supabase Auth)
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.users (
    -- Identité
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    
    -- État du parcours
    is_complete BOOLEAN DEFAULT FALSE,
    has_onboarded BOOLEAN DEFAULT FALSE,
    current_plan_id UUID, -- FK vers plans.id (ajouté plus tard)
    
    -- Préférences utilisateur
    bible_version TEXT DEFAULT 'LSG',
    preferred_time TIME DEFAULT '07:00',
    daily_minutes INTEGER DEFAULT 15,
    goals TEXT[] DEFAULT '{}', -- ['discipline', 'prayer', 'knowledge']
    audio_mode BOOLEAN DEFAULT TRUE,
    
    -- Intelligence : Profil spirituel
    spiritual_level TEXT DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced'
    emotional_state TEXT DEFAULT 'neutral', -- pour relationship intelligence
    meditation_objectives TEXT[] DEFAULT '{}', -- ['peace', 'discipline', 'intimacy']
    
    -- Métadonnées
    preferences JSONB DEFAULT '{}', -- Extensible pour futures préférences
    last_sync_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📖 TABLE: bible_versions
-- Versions de la Bible téléchargées par l'utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.bible_versions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    version_code TEXT NOT NULL, -- 'LSG', 'S21', 'NBS', etc.
    version_name TEXT NOT NULL,
    language TEXT DEFAULT 'fr',
    
    -- Statut
    is_downloaded BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE, -- Version active pour lecture
    download_progress REAL DEFAULT 0.0, -- 0.0 à 1.0
    
    -- Métadonnées
    file_size_mb REAL,
    download_started_at TIMESTAMP WITH TIME ZONE,
    downloaded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, version_code)
);

-- ──────────────────────────────────────────────────────────────────────────
-- ⚙️ TABLE: reader_settings
-- Paramètres de lecture personnalisés par utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.reader_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Apparence
    theme TEXT DEFAULT 'light', -- 'light', 'dark', 'sepia'
    font TEXT DEFAULT 'Inter',
    font_size REAL DEFAULT 16.0,
    brightness REAL DEFAULT 1.0,
    text_alignment TEXT DEFAULT 'Left', -- 'Left', 'Center', 'Right', 'Justify'
    
    -- Fonctionnalités
    is_offline_mode BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    is_search_enabled BOOLEAN DEFAULT TRUE,
    is_transitions_enabled BOOLEAN DEFAULT TRUE,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📋 TABLE: plan_presets
-- Templates de plans prédéfinis (générés par le système)
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.plan_presets (
    id TEXT PRIMARY KEY, -- ex: 'beginner_nt_90', 'psalms_150'
    
    -- Informations de base
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    subtitle TEXT,
    
    -- Configuration
    duration_days INTEGER NOT NULL,
    minutes_per_day INTEGER DEFAULT 15,
    books TEXT NOT NULL, -- 'OT,NT' | 'Psalms' | 'NT'
    specific_books TEXT, -- Livres/chapitres spécifiques
    reading_order TEXT DEFAULT 'traditional', -- 'traditional', 'chronological', 'thematic'
    
    -- Classification
    difficulty TEXT DEFAULT 'Débutant', -- 'Débutant', 'Intermédiaire', 'Avancé'
    recommended_for TEXT[] DEFAULT '{}', -- ['beginner', 'regular', 'leader']
    categories TEXT[] DEFAULT '{}', -- ['Évangiles', 'Sagesse', 'Prophétie']
    
    -- UI/UX
    cover_image TEXT,
    icon TEXT, -- Nom de l'icon Flutter
    color_hex TEXT, -- Couleur principale (hex)
    gradient_colors TEXT[], -- Array de couleurs (hex) pour gradient
    badge TEXT, -- ex: 'Populaire', 'Nouveau'
    
    -- Intelligence enrichie
    spiritual_impact REAL DEFAULT 0.7, -- 0.0 à 1.0
    timing_bonus INTEGER DEFAULT 0, -- Bonus % selon heure optimale
    expected_transformations TEXT[] DEFAULT '{}',
    
    -- Métadonnées
    parameters JSONB DEFAULT '{}', -- Paramètres additionnels extensibles
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📚 TABLE: plans
-- Plans de lecture personnalisés des utilisateurs
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Informations de base
    name TEXT NOT NULL,
    description TEXT,
    
    -- Configuration
    start_date DATE NOT NULL,
    total_days INTEGER NOT NULL,
    minutes_per_day INTEGER DEFAULT 15,
    books TEXT NOT NULL,
    specific_books TEXT,
    reading_order TEXT DEFAULT 'traditional',
    
    -- Statut
    status TEXT DEFAULT 'active', -- 'active', 'completed', 'paused', 'cancelled'
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Progrès
    completed_days INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    
    -- Intelligence
    preset_id TEXT REFERENCES public.plan_presets(id),
    generation_context JSONB DEFAULT '{}', -- Contexte de génération (profil user, timing, etc.)
    
    -- Métadonnées
    parameters JSONB DEFAULT '{}',
    raw_content TEXT, -- HTML brut retourné par API externe (si applicable)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📅 TABLE: plan_days
-- Jours individuels des plans de lecture
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.plan_days (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plan_id UUID REFERENCES public.plans(id) ON DELETE CASCADE,
    
    -- Jour
    day_number INTEGER NOT NULL, -- 1, 2, 3, ..., totalDays
    date DATE NOT NULL,
    
    -- Lectures
    bible_references TEXT[] NOT NULL, -- ['Jean 3:1-16', 'Psaumes 23']
    readings JSONB DEFAULT '[]', -- Array de ReadingRef enrichis
    
    -- Statut
    status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'skipped', 'missed'
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Contenu utilisateur
    notes TEXT,
    reflection TEXT,
    highlighted_verses TEXT[],
    
    -- Temps de lecture
    reading_duration_seconds INTEGER,
    meditation_duration_seconds INTEGER,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(plan_id, day_number)
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📝 TABLE: meditation_journals
-- Entrées du journal de méditation
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.meditation_journals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    plan_day_id UUID REFERENCES public.plan_days(id) ON DELETE SET NULL,
    
    -- Passage médité
    passage_ref TEXT NOT NULL,
    passage_text TEXT,
    
    -- Verset mémorisé
    memory_verse TEXT,
    memory_verse_ref TEXT,
    
    -- Sujets de prière identifiés
    prayer_subjects TEXT[] DEFAULT '{}',
    prayer_notes TEXT[] DEFAULT '{}',
    
    -- Type de méditation
    meditation_type TEXT DEFAULT 'free', -- 'free', 'qcm', 'auto_qcm'
    meditation_data JSONB DEFAULT '{}', -- Réponses, tags, insights
    
    -- Poster/Visuel
    gradient_index INTEGER DEFAULT 0,
    poster_image_url TEXT, -- URL du poster sauvegardé (Supabase Storage)
    
    -- Métadonnées
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 🙏 TABLE: prayer_subjects
-- Sujets de prière extraits des méditations
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.prayer_subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    meditation_journal_id UUID REFERENCES public.meditation_journals(id) ON DELETE SET NULL,
    
    -- Sujet
    subject_text TEXT NOT NULL,
    category TEXT, -- 'actionDeGrace', 'repentance', 'promesse', etc.
    
    -- Prière associée
    prayer_text TEXT,
    
    -- Statut
    is_completed BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    answered_at TIMESTAMP WITH TIME ZONE,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📊 TABLE: user_analytics
-- Événements et statistiques utilisateur (Telemetry)
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.user_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Événement
    event_name TEXT NOT NULL,
    event_properties JSONB DEFAULT '{}',
    
    -- Contexte
    session_id TEXT,
    page_path TEXT,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 🎯 TABLE: user_progress
-- Progrès global et statistiques de l'utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.user_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Streaks
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_meditation_date DATE,
    
    -- Compteurs globaux
    total_meditations INTEGER DEFAULT 0,
    total_prayers INTEGER DEFAULT 0,
    total_reading_minutes INTEGER DEFAULT 0,
    total_days_active INTEGER DEFAULT 0,
    
    -- Livres lus
    books_completed TEXT[] DEFAULT '{}',
    chapters_read JSONB DEFAULT '{}', -- { "Jean": [1,2,3], "Psaumes": [1,23,91] }
    
    -- Versets mémorisés
    memory_verses TEXT[] DEFAULT '{}',
    
    -- Badges/Réalisations
    badges_earned TEXT[] DEFAULT '{}',
    milestones_reached JSONB DEFAULT '{}',
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 📖 TABLE: verse_highlights
-- Versets surlignés/favoris par l'utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.verse_highlights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Verset
    verse_ref TEXT NOT NULL,
    verse_text TEXT NOT NULL,
    
    -- Classification
    highlight_color TEXT DEFAULT 'yellow', -- 'yellow', 'blue', 'green', 'pink'
    tags TEXT[] DEFAULT '{}',
    
    -- Notes
    note TEXT,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, verse_ref)
);

-- ──────────────────────────────────────────────────────────────────────────
-- 🔔 TABLE: notifications_queue
-- Queue de notifications à envoyer (pour système de rappels)
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.notifications_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Notification
    notification_type TEXT NOT NULL, -- 'daily_reminder', 'streak_encouragement', 'missed_day'
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    
    -- Planification
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Statut
    status TEXT DEFAULT 'pending', -- 'pending', 'sent', 'cancelled', 'failed'
    
    -- Métadonnées
    payload JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────
-- 🔄 TABLE: sync_queue
-- Queue de synchronisation pour architecture offline-first
-- ──────────────────────────────────────────────────────────────────────────
CREATE TABLE public.sync_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Opération
    operation_type TEXT NOT NULL, -- 'create', 'update', 'delete'
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    
    -- Données
    data JSONB NOT NULL,
    
    -- Statut
    status TEXT DEFAULT 'pending', -- 'pending', 'syncing', 'completed', 'failed'
    retry_count INTEGER DEFAULT 0,
    last_error TEXT,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    synced_at TIMESTAMP WITH TIME ZONE
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3️⃣ CONTRAINTES ET FOREIGN KEYS
-- ═══════════════════════════════════════════════════════════════════════════

-- Ajouter FK pour current_plan_id (circulaire)
ALTER TABLE public.users 
ADD CONSTRAINT fk_users_current_plan 
FOREIGN KEY (current_plan_id) REFERENCES public.plans(id) 
ON DELETE SET NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4️⃣ INDEX POUR PERFORMANCES
-- ═══════════════════════════════════════════════════════════════════════════

-- Users
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_current_plan ON public.users(current_plan_id) WHERE current_plan_id IS NOT NULL;

-- Plans
CREATE INDEX idx_plans_user_id ON public.plans(user_id);
CREATE INDEX idx_plans_status ON public.plans(status) WHERE status = 'active';
CREATE INDEX idx_plans_preset_id ON public.plans(preset_id) WHERE preset_id IS NOT NULL;

-- Plan Days
CREATE INDEX idx_plan_days_plan_id ON public.plan_days(plan_id);
CREATE INDEX idx_plan_days_date ON public.plan_days(date);
CREATE INDEX idx_plan_days_status ON public.plan_days(status);
CREATE INDEX idx_plan_days_user_date ON public.plan_days(plan_id, date);

-- Meditation Journals
CREATE INDEX idx_meditation_journals_user_id ON public.meditation_journals(user_id);
CREATE INDEX idx_meditation_journals_date ON public.meditation_journals(date DESC);
CREATE INDEX idx_meditation_journals_plan_day ON public.meditation_journals(plan_day_id);

-- Prayer Subjects
CREATE INDEX idx_prayer_subjects_user_id ON public.prayer_subjects(user_id);
CREATE INDEX idx_prayer_subjects_status ON public.prayer_subjects(is_completed, is_archived);

-- Analytics
CREATE INDEX idx_user_analytics_user_id ON public.user_analytics(user_id);
CREATE INDEX idx_user_analytics_event ON public.user_analytics(event_name);
CREATE INDEX idx_user_analytics_created_at ON public.user_analytics(created_at DESC);

-- Bible Versions
CREATE INDEX idx_bible_versions_user_id ON public.bible_versions(user_id);
CREATE INDEX idx_bible_versions_active ON public.bible_versions(user_id, is_active) WHERE is_active = TRUE;

-- Sync Queue
CREATE INDEX idx_sync_queue_user_id ON public.sync_queue(user_id);
CREATE INDEX idx_sync_queue_status ON public.sync_queue(status) WHERE status = 'pending';
CREATE INDEX idx_sync_queue_created_at ON public.sync_queue(created_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- 5️⃣ FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────
-- Trigger automatique pour updated_at
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ──────────────────────────────────────────────────────────────────────────
-- Créer automatiquement un profil utilisateur lors de l'inscription
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Créer le profil utilisateur
  INSERT INTO public.users (id, email, display_name, preferences)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name'),
    '{}'::jsonb
  );
  
  -- Créer les paramètres de lecteur par défaut
  INSERT INTO public.reader_settings (user_id)
  VALUES (NEW.id);
  
  -- Créer le profil de progrès
  INSERT INTO public.user_progress (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ──────────────────────────────────────────────────────────────────────────
-- Obtenir les statistiques d'un utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
    total_plans INTEGER,
    active_plans INTEGER,
    completed_plans INTEGER,
    total_meditations INTEGER,
    current_streak INTEGER,
    longest_streak INTEGER,
    total_reading_minutes INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT p.id)::INTEGER AS total_plans,
        COUNT(DISTINCT CASE WHEN p.status = 'active' THEN p.id END)::INTEGER AS active_plans,
        COUNT(DISTINCT CASE WHEN p.status = 'completed' THEN p.id END)::INTEGER AS completed_plans,
        COUNT(DISTINCT mj.id)::INTEGER AS total_meditations,
        COALESCE(up.current_streak, 0)::INTEGER,
        COALESCE(up.longest_streak, 0)::INTEGER,
        COALESCE(up.total_reading_minutes, 0)::INTEGER
    FROM public.users u
    LEFT JOIN public.plans p ON p.user_id = u.id
    LEFT JOIN public.meditation_journals mj ON mj.user_id = u.id
    LEFT JOIN public.user_progress up ON up.user_id = u.id
    WHERE u.id = p_user_id
    GROUP BY up.current_streak, up.longest_streak, up.total_reading_minutes;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────
-- Obtenir le progrès du plan actuel
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_current_plan_progress(p_user_id UUID)
RETURNS TABLE(
    plan_id UUID,
    plan_name TEXT,
    start_date DATE,
    total_days INTEGER,
    completed_days INTEGER,
    pending_days INTEGER,
    current_day_number INTEGER,
    progress_percentage REAL
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
        COUNT(CASE WHEN pd.status = 'completed' THEN 1 END)::INTEGER AS completed_days,
        COUNT(CASE WHEN pd.status = 'pending' THEN 1 END)::INTEGER AS pending_days,
        (EXTRACT(DAY FROM (CURRENT_DATE - p.start_date)) + 1)::INTEGER AS current_day_number,
        (COUNT(CASE WHEN pd.status = 'completed' THEN 1 END)::REAL / NULLIF(p.total_days, 0) * 100)::REAL AS progress_percentage
    FROM public.plans p
    LEFT JOIN public.plan_days pd ON pd.plan_id = p.id
    JOIN public.users u ON u.current_plan_id = p.id
    WHERE u.id = p_user_id
    AND p.status = 'active'
    GROUP BY p.id, p.name, p.start_date, p.total_days;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────
-- Obtenir la lecture du jour
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_today_reading(p_user_id UUID)
RETURNS TABLE(
    plan_day_id UUID,
    day_number INTEGER,
    date DATE,
    bible_references TEXT[],
    status TEXT,
    notes TEXT,
    has_meditation BOOLEAN
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pd.id,
        pd.day_number,
        pd.date,
        pd.bible_references,
        pd.status,
        pd.notes,
        EXISTS(
            SELECT 1 FROM public.meditation_journals mj 
            WHERE mj.plan_day_id = pd.id
        ) AS has_meditation
    FROM public.plan_days pd
    JOIN public.plans p ON pd.plan_id = p.id
    JOIN public.users u ON u.current_plan_id = p.id
    WHERE u.id = p_user_id 
    AND pd.date = CURRENT_DATE
    LIMIT 1;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────
-- Mettre à jour le streak de l'utilisateur
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_last_date DATE;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
BEGIN
    -- Récupérer les données actuelles
    SELECT last_meditation_date, current_streak, longest_streak
    INTO v_last_date, v_current_streak, v_longest_streak
    FROM public.user_progress
    WHERE user_id = p_user_id;
    
    -- Si pas de méditation aujourd'hui, ne rien faire
    IF NOT EXISTS(
        SELECT 1 FROM public.meditation_journals
        WHERE user_id = p_user_id
        AND date = CURRENT_DATE
    ) THEN
        RETURN;
    END IF;
    
    -- Calculer le nouveau streak
    IF v_last_date = CURRENT_DATE - INTERVAL '1 day' THEN
        -- Continuer le streak
        v_current_streak := v_current_streak + 1;
    ELSIF v_last_date < CURRENT_DATE - INTERVAL '1 day' THEN
        -- Streak cassé, recommencer à 1
        v_current_streak := 1;
    ELSE
        -- Déjà médité aujourd'hui
        RETURN;
    END IF;
    
    -- Mettre à jour le longest_streak si nécessaire
    IF v_current_streak > v_longest_streak THEN
        v_longest_streak := v_current_streak;
    END IF;
    
    -- Sauvegarder
    UPDATE public.user_progress
    SET 
        current_streak = v_current_streak,
        longest_streak = v_longest_streak,
        last_meditation_date = CURRENT_DATE,
        total_meditations = total_meditations + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6️⃣ TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Trigger: Créer profil automatiquement lors de l'inscription
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- Triggers: Mettre à jour updated_at automatiquement
CREATE TRIGGER users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER plans_updated_at BEFORE UPDATE ON public.plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER plan_days_updated_at BEFORE UPDATE ON public.plan_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER meditation_journals_updated_at BEFORE UPDATE ON public.meditation_journals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER prayer_subjects_updated_at BEFORE UPDATE ON public.prayer_subjects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER plan_presets_updated_at BEFORE UPDATE ON public.plan_presets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER reader_settings_updated_at BEFORE UPDATE ON public.reader_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_progress_updated_at BEFORE UPDATE ON public.user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════
-- 7️⃣ ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════

-- Activer RLS sur toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meditation_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prayer_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bible_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reader_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verse_highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_queue ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Users
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can view and update their own profile"
ON public.users FOR ALL
USING (auth.uid() = id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Plan Presets (lecture publique)
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Plan presets are viewable by authenticated users"
ON public.plan_presets FOR SELECT
USING (auth.role() = 'authenticated');

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Plans
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own plans"
ON public.plans FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Plan Days
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage plan days of their own plans"
ON public.plan_days FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.plans 
        WHERE plans.id = plan_days.plan_id 
        AND plans.user_id = auth.uid()
    )
);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Meditation Journals
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own meditation journals"
ON public.meditation_journals FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Prayer Subjects
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own prayer subjects"
ON public.prayer_subjects FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: User Analytics
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can create their own analytics events"
ON public.user_analytics FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own analytics"
ON public.user_analytics FOR SELECT
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Bible Versions
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own bible versions"
ON public.bible_versions FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Reader Settings
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own reader settings"
ON public.reader_settings FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: User Progress
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can view and update their own progress"
ON public.user_progress FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Verse Highlights
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own verse highlights"
ON public.verse_highlights FOR ALL
USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Notifications Queue
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can view their own notifications"
ON public.notifications_queue FOR SELECT
USING (auth.uid() = user_id);

-- Service role peut créer/modifier (pour Edge Functions)
CREATE POLICY "Service role can manage notifications"
ON public.notifications_queue FOR ALL
USING (auth.jwt() ->> 'role' = 'service_role');

-- ──────────────────────────────────────────────────────────────────────────
-- Policies: Sync Queue
-- ──────────────────────────────────────────────────────────────────────────
CREATE POLICY "Users can manage their own sync queue"
ON public.sync_queue FOR ALL
USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 8️⃣ DONNÉES D'EXEMPLE - PLAN PRESETS
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO public.plan_presets (
    id, slug, name, description, duration_days, minutes_per_day, 
    books, reading_order, difficulty, recommended_for, categories,
    badge, color_hex, spiritual_impact
) VALUES 
    -- Plans débutants
    (
        'beginner_nt_90',
        'nouveau-testament-90j',
        'Nouveau Testament',
        'Découvrez le message de Jésus et des apôtres en 90 jours.',
        90,
        10,
        'NT',
        'traditional',
        'Débutant',
        ARRAY['beginner', 'regular'],
        ARRAY['Évangiles', 'Nouveau Testament'],
        'Populaire',
        '#F9A66C',
        0.87
    ),
    (
        'beginner_psalms_150',
        'psaumes-150j',
        'Psaumes',
        'Un voyage de 150 jours à travers les louanges et prières.',
        150,
        5,
        'Psaumes',
        'traditional',
        'Débutant',
        ARRAY['beginner', 'regular', 'leader'],
        ARRAY['Louange', 'Prière', 'Méditation'],
        'Méditation',
        '#6C5CE7',
        0.98
    ),
    (
        'beginner_proverbs_31',
        'proverbes-31j',
        'Proverbes',
        'La sagesse de Salomon en 31 jours.',
        31,
        7,
        'Proverbes',
        'traditional',
        'Débutant',
        ARRAY['beginner', 'regular'],
        ARRAY['Sagesse', 'Vie pratique'],
        'Sagesse',
        '#FFB86C',
        0.89
    ),
    
    -- Plans intermédiaires
    (
        'intermediate_ot_180',
        'ancien-testament-180j',
        'Ancien Testament',
        'L''histoire du peuple de Dieu en 180 jours.',
        180,
        15,
        'OT',
        'chronological',
        'Intermédiaire',
        ARRAY['regular', 'leader'],
        ARRAY['Histoire', 'Prophétie'],
        NULL,
        '#8BE9FD',
        0.82
    ),
    (
        'intermediate_gospels_40',
        'evangiles-40j',
        'Les 4 Évangiles',
        'La vie de Jésus à travers Matthieu, Marc, Luc et Jean.',
        40,
        12,
        'Matthieu,Marc,Luc,Jean',
        'traditional',
        'Intermédiaire',
        ARRAY['beginner', 'regular'],
        ARRAY['Évangiles', 'Vie de Jésus'],
        'Fondamental',
        '#50FA7B',
        0.95
    ),
    
    -- Plans avancés
    (
        'advanced_bible_365',
        'bible-complete-365j',
        'Bible Complète',
        'Toute la Bible en une année avec un plan chronologique.',
        365,
        20,
        'OT,NT',
        'chronological',
        'Avancé',
        ARRAY['leader'],
        ARRAY['Chronologique', 'Bible complète'],
        'Challenge',
        '#FF79C6',
        0.92
    ),
    (
        'advanced_thematic_120',
        'thematique-120j',
        'Étude Thématique',
        'Parcours thématiques approfondis sur 120 jours.',
        120,
        25,
        'OT,NT',
        'thematic',
        'Avancé',
        ARRAY['leader'],
        ARRAY['Thématique', 'Théologie'],
        NULL,
        '#BD93F9',
        0.91
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- 9️⃣ VUES UTILES (Optionnel - pour faciliter les requêtes)
-- ═══════════════════════════════════════════════════════════════════════════

-- Vue: Plans actifs avec progrès
CREATE OR REPLACE VIEW active_plans_with_progress AS
SELECT 
    p.id,
    p.user_id,
    p.name,
    p.start_date,
    p.total_days,
    p.minutes_per_day,
    COUNT(pd.id) AS total_plan_days,
    COUNT(CASE WHEN pd.status = 'completed' THEN 1 END) AS completed_days,
    COUNT(CASE WHEN pd.status = 'pending' THEN 1 END) AS pending_days,
    (COUNT(CASE WHEN pd.status = 'completed' THEN 1 END)::REAL / NULLIF(p.total_days, 0) * 100)::REAL AS progress_percentage,
    p.created_at,
    p.updated_at
FROM public.plans p
LEFT JOIN public.plan_days pd ON pd.plan_id = p.id
WHERE p.status = 'active'
GROUP BY p.id;

-- Vue: Statistiques utilisateur rapides
CREATE OR REPLACE VIEW user_quick_stats AS
SELECT 
    u.id AS user_id,
    u.display_name,
    up.current_streak,
    up.longest_streak,
    up.total_meditations,
    up.total_prayers,
    up.total_reading_minutes,
    COUNT(DISTINCT p.id) AS total_plans,
    COUNT(DISTINCT CASE WHEN p.status = 'active' THEN p.id END) AS active_plans
FROM public.users u
LEFT JOIN public.user_progress up ON up.user_id = u.id
LEFT JOIN public.plans p ON p.user_id = u.id
GROUP BY u.id, u.display_name, up.current_streak, up.longest_streak, 
         up.total_meditations, up.total_prayers, up.total_reading_minutes;

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔟 DONNÉES DE TEST (Optionnel - à supprimer en production)
-- ═══════════════════════════════════════════════════════════════════════════

-- Créer un utilisateur de test (si besoin)
-- INSERT INTO auth.users (id, email) VALUES ('...uuid...', 'test@selah.app');

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ SCHÉMA TERMINÉ
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- 📊 Tables créées (13) :
--   1. users                  - Profils utilisateurs
--   2. bible_versions         - Versions Bible téléchargées
--   3. reader_settings        - Paramètres de lecture
--   4. plan_presets           - Templates de plans
--   5. plans                  - Plans personnalisés
--   6. plan_days              - Jours individuels
--   7. meditation_journals    - Journaux de méditation
--   8. prayer_subjects        - Sujets de prière
--   9. user_analytics         - Événements telemetry
--  10. user_progress          - Progrès et stats
--  11. verse_highlights       - Versets favoris
--  12. notifications_queue    - Rappels planifiés
--  13. sync_queue             - Queue offline-first
--
-- 🔧 Fonctions créées (5) :
--   • update_updated_at()
--   • handle_new_user()
--   • get_user_stats()
--   • get_current_plan_progress()
--   • get_today_reading()
--   • update_user_streak()
--
-- 🛡️ Sécurité :
--   • RLS activé sur toutes les tables
--   • Policies pour isoler les données utilisateur
--   • Service role pour Edge Functions
--
-- 🚀 Performance :
--   • 20+ indexes stratégiques
--   • Vues pré-calculées
--   • Contraintes d'unicité
--
-- 🔄 Offline-First :
--   • sync_queue pour synchronisation
--   • last_sync_at sur users
--   • Optimistic updates compatibles
--
-- 📈 Extensibilité :
--   • Colonnes JSONB pour futures features
--   • Structure modulaire
--   • Facile d'ajouter tables/colonnes
--
-- ═══════════════════════════════════════════════════════════════════════════
