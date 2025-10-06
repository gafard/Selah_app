-- ===========================
-- Selah: Lecture Plans v2
-- ===========================

-- Extensions utiles
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- Types forts
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_type_enum') THEN
    CREATE TYPE task_type_enum AS ENUM ('reading','meditation','prayer','note','quiz','other');
  END IF;
END$$;

-- ===========================
-- Tables
-- ===========================

-- Plans
CREATE TABLE IF NOT EXISTS plans (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  duration_days INTEGER NOT NULL CHECK (duration_days BETWEEN 1 AND 10000),
  start_date  DATE NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT FALSE,
  metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Jours du plan
CREATE TABLE IF NOT EXISTS plan_days (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id       UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  day_number    INTEGER NOT NULL CHECK (day_number >= 1),
  date          DATE NOT NULL,
  is_completed  BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_plan_days_number UNIQUE (plan_id, day_number),
  CONSTRAINT uq_plan_days_date   UNIQUE (plan_id, date)
);

-- Tâches d'un jour de plan
CREATE TABLE IF NOT EXISTS plan_tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_day_id     UUID NOT NULL REFERENCES plan_days(id) ON DELETE CASCADE,
  task_type       task_type_enum NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  book            TEXT,  -- optionnel, pour 'reading'
  chapter_start   INTEGER CHECK (chapter_start IS NULL OR chapter_start >= 1),
  chapter_end     INTEGER CHECK (chapter_end   IS NULL OR chapter_end   >= 1),
  verse_start     INTEGER CHECK (verse_start   IS NULL OR verse_start   >= 1),
  verse_end       INTEGER CHECK (verse_end     IS NULL OR verse_end     >= 1),
  estimated_minutes INTEGER NOT NULL DEFAULT 15 CHECK (estimated_minutes BETWEEN 1 AND 600),
  is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at    TIMESTAMPTZ,
  order_index     INTEGER NOT NULL DEFAULT 0 CHECK (order_index >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_task_order_per_day UNIQUE (plan_day_id, order_index),
  CONSTRAINT chk_ref_bounds CHECK (
    -- si chapitre fin est renseigné, il doit être >= début (idem versets)
    (chapter_end IS NULL OR chapter_start IS NULL OR chapter_end >= chapter_start)
    AND
    (verse_end   IS NULL OR verse_start   IS NULL OR verse_end   >= verse_start)
  )
);

-- ===========================
-- Index
-- ===========================

-- Plans
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_active   ON plans(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_plans_start_date ON plans(start_date);
CREATE INDEX IF NOT EXISTS idx_plans_metadata_gin ON plans USING GIN (metadata);

-- Plan days
CREATE INDEX IF NOT EXISTS idx_plan_days_plan_id ON plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_days_date    ON plan_days(date);
CREATE INDEX IF NOT EXISTS idx_plan_days_completed ON plan_days(is_completed) WHERE is_completed = TRUE;

-- Plan tasks
CREATE INDEX IF NOT EXISTS idx_plan_tasks_plan_day_id ON plan_tasks(plan_day_id);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_completed   ON plan_tasks(is_completed) WHERE is_completed = TRUE;

-- ===========================
-- Triggers updated_at
-- ===========================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_plans_updated_at') THEN
    CREATE TRIGGER update_plans_updated_at
      BEFORE UPDATE ON plans
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_plan_days_updated_at') THEN
    CREATE TRIGGER update_plan_days_updated_at
      BEFORE UPDATE ON plan_days
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_plan_tasks_updated_at') THEN
    CREATE TRIGGER update_plan_tasks_updated_at
      BEFORE UPDATE ON plan_tasks
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END$$;

-- ===========================
-- Triggers de sûreté user_id
-- ===========================

-- Forcer user_id = auth.uid() à l'INSERT sur plans
CREATE OR REPLACE FUNCTION enforce_plan_user_id()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null';
  END IF;
  NEW.user_id := auth.uid();
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'plans_set_user_id') THEN
    CREATE TRIGGER plans_set_user_id
      BEFORE INSERT ON plans
      FOR EACH ROW EXECUTE FUNCTION enforce_plan_user_id();
  END IF;
END$$;

-- Empêcher la modification de user_id
CREATE OR REPLACE FUNCTION prevent_plan_user_id_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'user_id is immutable';
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'plans_user_id_immutable') THEN
    CREATE TRIGGER plans_user_id_immutable
      BEFORE UPDATE ON plans
      FOR EACH ROW EXECUTE FUNCTION prevent_plan_user_id_update();
  END IF;
END$$;

-- ===========================
-- RLS
-- ===========================

ALTER TABLE plans      ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_days  ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_tasks ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes pour éviter les conflits
DROP POLICY IF EXISTS "Users can view their own plans" ON plans;
DROP POLICY IF EXISTS "Users can insert their own plans" ON plans;
DROP POLICY IF EXISTS "Users can update their own plans" ON plans;
DROP POLICY IF EXISTS "Users can delete their own plans" ON plans;

DROP POLICY IF EXISTS "Users can view their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can insert their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can update their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can delete their own plan days" ON plan_days;

DROP POLICY IF EXISTS "Users can view their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can insert their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can update their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can delete their own plan tasks" ON plan_tasks;

-- Politiques pour plans
CREATE POLICY "Users can view their own plans" ON plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plans" ON plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans" ON plans
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans" ON plans
    FOR DELETE USING (auth.uid() = user_id);

-- Politiques pour plan_days
CREATE POLICY "Users can view their own plan days" ON plan_days
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own plan days" ON plan_days
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own plan days" ON plan_days
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own plan days" ON plan_days
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

-- Politiques pour plan_tasks
CREATE POLICY "Users can view their own plan tasks" ON plan_tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM plan_days 
            JOIN plans ON plans.id = plan_days.plan_id
            WHERE plan_days.id = plan_tasks.plan_day_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own plan tasks" ON plan_tasks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM plan_days 
            JOIN plans ON plans.id = plan_days.plan_id
            WHERE plan_days.id = plan_tasks.plan_day_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own plan tasks" ON plan_tasks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM plan_days 
            JOIN plans ON plans.id = plan_days.plan_id
            WHERE plan_days.id = plan_tasks.plan_day_id 
            AND plans.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own plan tasks" ON plan_tasks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM plan_days 
            JOIN plans ON plans.id = plan_days.plan_id
            WHERE plan_days.id = plan_tasks.plan_day_id 
            AND plans.user_id = auth.uid()
        )
    );
