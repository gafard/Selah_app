-- Migration adaptative pour mettre à jour la structure des tables
-- Cette migration s'adapte à la structure existante

-- 1. Mettre à jour la table plans
DO $$ 
BEGIN
    -- Ajouter les colonnes manquantes à la table plans
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE plans ADD COLUMN is_active boolean NOT NULL DEFAULT false;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'total_days'
    ) THEN
        ALTER TABLE plans ADD COLUMN total_days int;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'start_date'
    ) THEN
        ALTER TABLE plans ADD COLUMN start_date date;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'name'
    ) THEN
        ALTER TABLE plans ADD COLUMN name text;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE plans ADD COLUMN user_id uuid;
    END IF;
    
    -- Ajouter les colonnes de timestamp si elles n'existent pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE plans ADD COLUMN created_at timestamptz DEFAULT now();
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plans' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE plans ADD COLUMN updated_at timestamptz DEFAULT now();
    END IF;
END $$;

-- 2. Mettre à jour la table plan_days
DO $$ 
BEGIN
    -- Ajouter les colonnes manquantes à la table plan_days
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'day_index'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN day_index int;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'date'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN date date;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'readings'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN readings jsonb;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'completed'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN completed boolean NOT NULL DEFAULT false;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'plan_id'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN plan_id uuid;
    END IF;
    
    -- Ajouter les colonnes de timestamp si elles n'existent pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN created_at timestamptz DEFAULT now();
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'plan_days' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE plan_days ADD COLUMN updated_at timestamptz DEFAULT now();
    END IF;
END $$;

-- 3. Créer les index (ignorer les erreurs si ils existent déjà)
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_is_active ON plans(is_active);
CREATE INDEX IF NOT EXISTS idx_plan_days_plan_id ON plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_days_day_index ON plan_days(day_index);

-- 4. Activer RLS
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_days ENABLE ROW LEVEL SECURITY;

-- 5. Créer les politiques RLS pour plans
DROP POLICY IF EXISTS "Users can view their own plans" ON plans;
CREATE POLICY "Users can view their own plans" ON plans
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own plans" ON plans;
CREATE POLICY "Users can insert their own plans" ON plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own plans" ON plans;
CREATE POLICY "Users can update their own plans" ON plans
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own plans" ON plans;
CREATE POLICY "Users can delete their own plans" ON plans
    FOR DELETE USING (auth.uid() = user_id);

-- 6. Créer les politiques RLS pour plan_days
DROP POLICY IF EXISTS "Users can view their own plan days" ON plan_days;
CREATE POLICY "Users can view their own plan days" ON plan_days
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own plan days" ON plan_days;
CREATE POLICY "Users can insert their own plan days" ON plan_days
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own plan days" ON plan_days;
CREATE POLICY "Users can update their own plan days" ON plan_days
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own plan days" ON plan_days;
CREATE POLICY "Users can delete their own plan days" ON plan_days
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM plans 
            WHERE plans.id = plan_days.plan_id 
            AND plans.user_id = auth.uid()
        )
    );

-- 7. Créer les triggers pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour plans
DROP TRIGGER IF EXISTS update_plans_updated_at ON plans;
CREATE TRIGGER update_plans_updated_at
    BEFORE UPDATE ON plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour plan_days
DROP TRIGGER IF EXISTS update_plan_days_updated_at ON plan_days;
CREATE TRIGGER update_plan_days_updated_at
    BEFORE UPDATE ON plan_days
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
