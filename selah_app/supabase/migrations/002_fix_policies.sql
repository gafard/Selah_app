-- Migration pour corriger les politiques RLS existantes
-- Supprime les politiques existantes et les recrée pour éviter les conflits

-- Supprimer les politiques existantes pour les plans
DROP POLICY IF EXISTS "Users can view their own plans" ON plans;
DROP POLICY IF EXISTS "Users can insert their own plans" ON plans;
DROP POLICY IF EXISTS "Users can update their own plans" ON plans;
DROP POLICY IF EXISTS "Users can delete their own plans" ON plans;

-- Supprimer les politiques existantes pour les plan_days
DROP POLICY IF EXISTS "Users can view their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can insert their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can update their own plan days" ON plan_days;
DROP POLICY IF EXISTS "Users can delete their own plan days" ON plan_days;

-- Supprimer les politiques existantes pour les plan_tasks
DROP POLICY IF EXISTS "Users can view their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can insert their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can update their own plan tasks" ON plan_tasks;
DROP POLICY IF EXISTS "Users can delete their own plan tasks" ON plan_tasks;

-- Recréer les politiques pour les plans
CREATE POLICY "Users can view their own plans" ON plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plans" ON plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans" ON plans
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans" ON plans
    FOR DELETE USING (auth.uid() = user_id);

-- Recréer les politiques pour les plan_days
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

-- Recréer les politiques pour les plan_tasks
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
