-- Migration pour système de génération de plans 100% local
-- Date: 2024-12-01
-- Description: Support des presets et plans personnalisés générés localement

-- Table des presets de plans (templates)
CREATE TABLE IF NOT EXISTS plan_presets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- 'thompson', 'custom', 'thematic'
  theme TEXT, -- thème Thompson associé
  parameters JSONB NOT NULL, -- paramètres de génération
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des plans générés localement
CREATE TABLE IF NOT EXISTS local_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  preset_id UUID REFERENCES plan_presets(id), -- null si plan personnalisé
  is_custom BOOLEAN DEFAULT false,
  start_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  parameters JSONB NOT NULL, -- paramètres utilisés pour la génération
  generated_content JSONB, -- contenu généré (références, versets, etc.)
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'archived')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des jours de plan (générés localement)
CREATE TABLE IF NOT EXISTS local_plan_days (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID REFERENCES local_plans(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL,
  date DATE NOT NULL,
  bible_references TEXT[] NOT NULL, -- références bibliques du jour
  meditation_theme TEXT, -- thème de méditation
  prayer_subjects JSONB, -- sujets de prière générés
  memory_verse TEXT, -- verset à mémoriser
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, day_number)
);

-- Table des profils utilisateur étendus
CREATE TABLE IF NOT EXISTS user_profiles_extended (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_plan_id UUID REFERENCES local_plans(id),
  profile_data JSONB NOT NULL, -- données du profil complet
  preferences JSONB, -- préférences de lecture
  statistics JSONB, -- statistiques de progression
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_local_plans_user_id ON local_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_local_plans_status ON local_plans(status);
CREATE INDEX IF NOT EXISTS idx_local_plan_days_plan_id ON local_plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_local_plan_days_date ON local_plan_days(date);
CREATE INDEX IF NOT EXISTS idx_plan_presets_category ON plan_presets(category);
CREATE INDEX IF NOT EXISTS idx_plan_presets_theme ON plan_presets(theme);

-- RLS (Row Level Security)
ALTER TABLE plan_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE local_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE local_plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles_extended ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
-- Presets: lecture publique, modification admin
CREATE POLICY "Presets are publicly readable" ON plan_presets
  FOR SELECT USING (true);

CREATE POLICY "Only admins can modify presets" ON plan_presets
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Plans: utilisateur ne voit que ses propres plans
CREATE POLICY "Users can view their own plans" ON local_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own plans" ON local_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans" ON local_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans" ON local_plans
  FOR DELETE USING (auth.uid() = user_id);

-- Jours de plan: même logique
CREATE POLICY "Users can view their plan days" ON local_plan_days
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM local_plans 
      WHERE local_plans.id = local_plan_days.plan_id 
      AND local_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their plan days" ON local_plan_days
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM local_plans 
      WHERE local_plans.id = local_plan_days.plan_id 
      AND local_plans.user_id = auth.uid()
    )
  );

-- Profils étendus: utilisateur ne voit que son profil
CREATE POLICY "Users can view their own profile" ON user_profiles_extended
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own profile" ON user_profiles_extended
  FOR ALL USING (auth.uid() = user_id);

-- Fonctions utilitaires
CREATE OR REPLACE FUNCTION update_user_current_plan(user_id UUID, plan_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_profiles_extended 
  SET current_plan_id = plan_id, updated_at = NOW()
  WHERE user_profiles_extended.user_id = update_user_current_plan.user_id;
  
  -- Si le profil n'existe pas, le créer
  IF NOT FOUND THEN
    INSERT INTO user_profiles_extended (user_id, current_plan_id)
    VALUES (update_user_current_plan.user_id, plan_id);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir le plan actif d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_active_plan(user_id UUID)
RETURNS TABLE (
  plan_id UUID,
  plan_name TEXT,
  start_date DATE,
  total_days INTEGER,
  current_day INTEGER,
  progress_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    lp.id,
    lp.name,
    lp.start_date,
    lp.total_days,
    COALESCE(
      (SELECT COUNT(*)::INTEGER 
       FROM local_plan_days lpd 
       WHERE lpd.plan_id = lp.id AND lpd.is_completed = true
      ), 0
    ) as current_day,
    ROUND(
      (SELECT COUNT(*)::NUMERIC 
       FROM local_plan_days lpd 
       WHERE lpd.plan_id = lp.id AND lpd.is_completed = true
      ) * 100.0 / lp.total_days, 2
    ) as progress_percentage
  FROM local_plans lp
  JOIN user_profiles_extended upe ON upe.current_plan_id = lp.id
  WHERE upe.user_id = get_user_active_plan.user_id
  AND lp.status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insérer des presets par défaut
INSERT INTO plan_presets (name, slug, description, category, theme, parameters) VALUES
-- Presets Thompson
('Exigence Spirituelle', 'thompson-spiritual-demand', 'Plan pour approfondir sa spiritualité', 'thompson', 'spiritual_demand', '{"totalDays": 90, "order": "chronological", "books": ["NT"], "focus": "spiritual_growth"}'),
('Paix du Cœur', 'thompson-no-worry', 'Plan pour trouver la paix intérieure', 'thompson', 'no_worry', '{"totalDays": 40, "order": "thematic", "books": ["Gospels", "Psalms"], "focus": "peace"}'),
('Communion Fraternelle', 'thompson-companionship', 'Plan pour la vie communautaire', 'thompson', 'companionship', '{"totalDays": 60, "order": "traditional", "books": ["OT", "NT"], "focus": "community"}'),
('Mariage selon Dieu', 'thompson-marriage', 'Plan pour les couples', 'thompson', 'marriage_duties', '{"totalDays": 30, "order": "thematic", "books": ["Gospels", "Psalms", "Proverbs"], "focus": "marriage"}'),
('Vie de Prière', 'thompson-prayer', 'Plan pour développer la prière', 'thompson', 'prayer_life', '{"totalDays": 50, "order": "traditional", "books": ["Psalms"], "focus": "prayer"}'),
('Pardon & Guérison', 'thompson-forgiveness', 'Plan pour le pardon et la guérison', 'thompson', 'forgiveness', '{"totalDays": 21, "order": "chronological", "books": ["NT"], "focus": "forgiveness"}'),
('Foi dans l''Épreuve', 'thompson-faith-trials', 'Plan pour les temps difficiles', 'thompson', 'faith_trials', '{"totalDays": 70, "order": "historical", "books": ["OT", "NT"], "focus": "faith"}'),
('Sagesse Pratique', 'thompson-common-errors', 'Plan pour éviter les erreurs communes', 'thompson', 'common_errors', '{"totalDays": 45, "order": "traditional", "books": ["Proverbs", "James"], "focus": "wisdom"}'),

-- Presets thématiques
('Lecture Complète', 'thematic-complete', 'Lecture de toute la Bible en un an', 'thematic', 'complete', '{"totalDays": 365, "order": "traditional", "books": ["OT", "NT"], "focus": "complete_reading"}'),
('Nouveau Testament', 'thematic-new-testament', 'Focus sur le Nouveau Testament', 'thematic', 'new_testament', '{"totalDays": 90, "order": "chronological", "books": ["NT"], "focus": "new_testament"}'),
('Psaumes & Proverbes', 'thematic-psalms-proverbs', 'Sagesse et louange quotidienne', 'thematic', 'wisdom', '{"totalDays": 150, "order": "traditional", "books": ["Psalms", "Proverbs"], "focus": "wisdom_praise"}'),
('Évangiles', 'thematic-gospels', 'Focus sur les 4 Évangiles', 'thematic', 'gospels', '{"totalDays": 60, "order": "chronological", "books": ["Gospels"], "focus": "gospels"}');

-- Triggers pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_plan_presets_updated_at 
  BEFORE UPDATE ON plan_presets 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_local_plans_updated_at 
  BEFORE UPDATE ON local_plans 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_extended_updated_at 
  BEFORE UPDATE ON user_profiles_extended 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
