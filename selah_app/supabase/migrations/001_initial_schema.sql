-- Migration initiale pour les plans de lecture
-- Création des tables nécessaires pour l'application Selah

-- Table des plans
CREATE TABLE IF NOT EXISTS plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    duration_days INTEGER NOT NULL,
    start_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Table des jours de plan
CREATE TABLE IF NOT EXISTS plan_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES plans(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(plan_id, day_number)
);

-- Table des tâches de lecture
CREATE TABLE IF NOT EXISTS plan_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_day_id UUID REFERENCES plan_days(id) ON DELETE CASCADE,
    task_type TEXT NOT NULL, -- 'reading', 'meditation', 'prayer', etc.
    title TEXT NOT NULL,
    description TEXT,
    book TEXT,
    chapter_start INTEGER,
    chapter_end INTEGER,
    verse_start INTEGER,
    verse_end INTEGER,
    estimated_minutes INTEGER DEFAULT 15,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_active ON plans(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_plan_days_plan_id ON plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_days_date ON plan_days(date);
CREATE INDEX IF NOT EXISTS idx_plan_tasks_plan_day_id ON plan_tasks(plan_day_id);

-- RLS (Row Level Security) policies
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_tasks ENABLE ROW LEVEL SECURITY;

-- Policies pour les plans
CREATE POLICY "Users can view their own plans" ON plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plans" ON plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans" ON plans
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans" ON plans
    FOR DELETE USING (auth.uid() = user_id);

-- Policies pour les plan_days
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

-- Policies pour les plan_tasks
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

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour updated_at
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plan_days_updated_at BEFORE UPDATE ON plan_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plan_tasks_updated_at BEFORE UPDATE ON plan_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
