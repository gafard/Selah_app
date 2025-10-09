# 📚 GUIDE COMPLET - Schéma Supabase Selah App

## 🎯 Vue d'Ensemble

Le schéma Supabase de Selah App est conçu pour une **architecture offline-first** avec synchronisation intelligente.

### Principes Clés
1. **Offline-First** : Tout fonctionne localement (Hive) d'abord
2. **Sync Intelligente** : Synchronisation en arrière-plan quand online
3. **Extensibilité** : Facile d'ajouter de nouvelles fonctionnalités
4. **Performance** : Indexes stratégiques pour requêtes rapides
5. **Sécurité** : RLS (Row Level Security) sur toutes les tables

---

## 📊 Tables Principales (13)

### 1️⃣ Core Tables (Utilisateurs & Auth)

#### `users`
**But** : Profil utilisateur complet

**Colonnes clés** :
- `id` : UUID (lié à auth.users)
- `display_name` : Nom affiché
- `is_complete` : Profil complété ?
- `has_onboarded` : Onboarding terminé ?
- `current_plan_id` : Plan actif (FK vers plans.id)
- `bible_version` : Version Bible préférée
- `preferred_time` : Heure préférée méditation
- `daily_minutes` : Minutes quotidiennes
- `goals` : Array d'objectifs spirituels
- `spiritual_level` : Niveau spirituel ('beginner', 'intermediate', 'advanced')
- `meditation_objectives` : Array d'objectifs méditation
- `preferences` : JSONB extensible

**Quand synchroniser** :
- À la création du compte
- Après modification profil
- Après complete_profile_page
- Après changement de plan

**Exemple** :
```sql
SELECT * FROM users WHERE id = 'user-uuid';
```

---

#### `reader_settings`
**But** : Paramètres de lecture personnalisés

**Colonnes clés** :
- `theme` : 'light', 'dark', 'sepia'
- `font` : 'Inter', 'Lato', 'PlayfairDisplay'
- `font_size` : Taille de police
- `text_alignment` : Alignement texte
- `is_offline_mode` : Mode hors-ligne activé

**Quand synchroniser** :
- Après changement dans reader_settings_page

**Exemple** :
```sql
SELECT * FROM reader_settings WHERE user_id = 'user-uuid';
```

---

#### `user_progress`
**But** : Progrès global et statistiques

**Colonnes clés** :
- `current_streak` : Série en cours
- `longest_streak` : Meilleure série
- `total_meditations` : Total méditations
- `total_prayers` : Total prières
- `books_completed` : Array livres terminés
- `memory_verses` : Array versets mémorisés
- `badges_earned` : Array badges obtenus

**Mise à jour automatique** :
- Trigger après chaque méditation complétée
- Fonction `update_user_streak()` à appeler

**Exemple** :
```sql
SELECT * FROM user_progress WHERE user_id = 'user-uuid';
```

---

### 2️⃣ Plans & Lectures

#### `plan_presets`
**But** : Templates de plans (générés par l'intelligence)

**Colonnes clés** :
- `slug` : Identifiant unique
- `name` : Nom du preset
- `duration_days` : Durée en jours
- `books` : Livres à lire
- `recommended_for` : Array de niveaux recommandés
- `spiritual_impact` : Impact spirituel (0.0 - 1.0)
- `timing_bonus` : Bonus % selon heure
- `expected_transformations` : Array de transformations attendues

**Quand ajouter** :
- Nouveaux presets générés par intelligent_local_preset_generator
- Mise à jour avec nouvelles intelligences

**Exemple** :
```sql
SELECT * FROM plan_presets 
WHERE 'beginner' = ANY(recommended_for)
AND spiritual_impact > 0.9
ORDER BY spiritual_impact DESC;
```

---

#### `plans`
**But** : Plans personnalisés des utilisateurs

**Colonnes clés** :
- `user_id` : Propriétaire
- `name` : Nom du plan
- `start_date` : Date de début
- `total_days` : Durée totale
- `status` : 'active', 'completed', 'paused'
- `completed_days` : Jours complétés
- `current_streak` : Série actuelle
- `preset_id` : FK vers plan_presets (si basé sur preset)
- `generation_context` : JSONB avec contexte de génération

**Quand synchroniser** :
- Création depuis goals_page
- Changement de statut
- Mise à jour progrès

**Exemple** :
```sql
SELECT * FROM plans 
WHERE user_id = 'user-uuid' 
AND status = 'active'
LIMIT 1;
```

---

#### `plan_days`
**But** : Jours individuels d'un plan

**Colonnes clés** :
- `plan_id` : FK vers plans
- `day_number` : Numéro du jour (1, 2, 3...)
- `date` : Date réelle
- `bible_references` : Array de références
- `status` : 'pending', 'completed', 'skipped'
- `notes` : Notes utilisateur
- `reading_duration_seconds` : Temps de lecture

**Quand synchroniser** :
- Marqué comme complété
- Ajout de notes
- Changement de statut

**Exemple** :
```sql
SELECT * FROM plan_days 
WHERE plan_id = 'plan-uuid' 
AND date = CURRENT_DATE;
```

---

### 3️⃣ Méditation & Prière

#### `meditation_journals`
**But** : Journaux de méditation quotidienne

**Colonnes clés** :
- `user_id` : Propriétaire
- `plan_day_id` : Lié au jour du plan (optionnel)
- `passage_ref` : Référence du passage médité
- `passage_text` : Texte du passage
- `memory_verse` : Verset mémorisé
- `prayer_subjects` : Array de sujets de prière
- `meditation_type` : 'free', 'qcm', 'auto_qcm'
- `meditation_data` : JSONB avec réponses, tags, insights
- `poster_image_url` : URL du poster (Supabase Storage)

**Quand synchroniser** :
- Fin de méditation (meditation_free/qcm/auto_qcm)
- Création de poster
- Sauvegarde dans journal

**Exemple** :
```sql
SELECT * FROM meditation_journals 
WHERE user_id = 'user-uuid' 
ORDER BY date DESC 
LIMIT 30;
```

---

#### `prayer_subjects`
**But** : Sujets de prière extraits des méditations

**Colonnes clés** :
- `user_id` : Propriétaire
- `meditation_journal_id` : Lié au journal (optionnel)
- `subject_text` : Texte du sujet
- `category` : Catégorie de prière
- `prayer_text` : Prière formulée
- `is_completed` : Prière exaucée ?
- `answered_at` : Date de réponse

**Quand synchroniser** :
- Création depuis prayer_subjects_page
- Marqué comme exaucé
- Archivage

**Exemple** :
```sql
SELECT * FROM prayer_subjects 
WHERE user_id = 'user-uuid' 
AND is_completed = FALSE
ORDER BY created_at DESC;
```

---

### 4️⃣ Analytics & Système

#### `user_analytics`
**But** : Événements de telemetry et analytics

**Colonnes clés** :
- `user_id` : Utilisateur
- `event_name` : Nom de l'événement
- `event_properties` : JSONB avec propriétés
- `session_id` : ID de session
- `page_path` : Page actuelle

**Quand créer** :
- Chaque action utilisateur trackée
- Navigation entre pages
- Téléchargement Bible
- Actions importantes

**Exemple** :
```sql
SELECT event_name, COUNT(*) 
FROM user_analytics 
WHERE user_id = 'user-uuid'
AND created_at > NOW() - INTERVAL '7 days'
GROUP BY event_name;
```

---

#### `sync_queue`
**But** : Queue de synchronisation offline-first

**Colonnes clés** :
- `user_id` : Utilisateur
- `operation_type` : 'create', 'update', 'delete'
- `table_name` : Table concernée
- `record_id` : ID de l'enregistrement
- `data` : JSONB avec données à synchroniser
- `status` : 'pending', 'syncing', 'completed', 'failed'
- `retry_count` : Nombre de tentatives

**Utilisation** :
- Remplie automatiquement par `LocalStorageService.markForSync()`
- Drainée par Edge Function ou client quand online
- Permet de ne rien perdre même offline

**Exemple** :
```sql
SELECT * FROM sync_queue 
WHERE user_id = 'user-uuid' 
AND status = 'pending'
ORDER BY created_at ASC;
```

---

### 5️⃣ Autres Tables

#### `bible_versions`
- Versions Bible téléchargées
- Progrès de téléchargement
- Version active

#### `verse_highlights`
- Versets surlignés/favoris
- Couleurs de surlignage
- Notes personnelles

#### `notifications_queue`
- Rappels planifiés
- Encouragements automatiques
- Notifications intelligentes

---

## 🔧 Fonctions Utilitaires

### `get_user_stats(user_id UUID)`
Retourne les statistiques globales d'un utilisateur.

**Retour** :
```
total_plans | active_plans | completed_plans | total_meditations | current_streak | longest_streak | total_reading_minutes
```

**Usage** :
```sql
SELECT * FROM get_user_stats('user-uuid');
```

---

### `get_current_plan_progress(user_id UUID)`
Retourne le progrès détaillé du plan actuel.

**Retour** :
```
plan_id | plan_name | start_date | total_days | completed_days | pending_days | current_day_number | progress_percentage
```

**Usage** :
```sql
SELECT * FROM get_current_plan_progress('user-uuid');
```

---

### `get_today_reading(user_id UUID)`
Retourne la lecture du jour.

**Retour** :
```
plan_day_id | day_number | date | bible_references | status | notes | has_meditation
```

**Usage** :
```sql
SELECT * FROM get_today_reading('user-uuid');
```

---

### `update_user_streak(user_id UUID)`
Met à jour automatiquement le streak de l'utilisateur.

**Utilisation** :
- À appeler après chaque méditation complétée
- Calcule automatiquement les streaks
- Met à jour `user_progress`

**Usage** :
```sql
SELECT update_user_streak('user-uuid');
```

---

## 🚀 Comment Étendre le Schéma

### Ajouter une Nouvelle Table

**Exemple** : Table pour les groupes communautaires

```sql
-- 1. Créer la table
CREATE TABLE public.community_groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES public.users(id),
    members_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Activer RLS
ALTER TABLE public.community_groups ENABLE ROW LEVEL SECURITY;

-- 3. Créer les policies
CREATE POLICY "Users can view public groups"
ON public.community_groups FOR SELECT
USING (is_public = TRUE OR owner_id = auth.uid());

-- 4. Ajouter indexes
CREATE INDEX idx_community_groups_owner ON public.community_groups(owner_id);
CREATE INDEX idx_community_groups_public ON public.community_groups(is_public) WHERE is_public = TRUE;

-- 5. Ajouter trigger updated_at
CREATE TRIGGER community_groups_updated_at 
BEFORE UPDATE ON public.community_groups
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

### Ajouter une Colonne à une Table Existante

**Exemple** : Ajouter `phone_number` à `users`

```sql
-- 1. Ajouter la colonne
ALTER TABLE public.users 
ADD COLUMN phone_number TEXT;

-- 2. Ajouter index si nécessaire
CREATE INDEX idx_users_phone ON public.users(phone_number) 
WHERE phone_number IS NOT NULL;

-- 3. Ajouter contrainte si nécessaire
ALTER TABLE public.users 
ADD CONSTRAINT users_phone_unique UNIQUE (phone_number);
```

---

### Ajouter une Nouvelle Intelligence

**Exemple** : Intelligence pour recommander des versets

```sql
-- 1. Créer une table pour stocker les recommandations
CREATE TABLE public.verse_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    verse_ref TEXT NOT NULL,
    recommendation_score REAL DEFAULT 0.0, -- 0.0 à 1.0
    recommendation_reason TEXT,
    context JSONB DEFAULT '{}', -- { "goal": "peace", "time": "morning" }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Ajouter colonnes aux tables existantes si besoin
ALTER TABLE public.plan_presets 
ADD COLUMN verse_recommendation_score REAL DEFAULT 0.0;

-- 3. Créer une fonction d'intelligence
CREATE OR REPLACE FUNCTION get_recommended_verses(
    p_user_id UUID,
    p_context JSONB
)
RETURNS TABLE(
    verse_ref TEXT,
    score REAL,
    reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Logique d'intelligence ici
    RETURN QUERY
    SELECT 
        vr.verse_ref,
        vr.recommendation_score,
        vr.recommendation_reason
    FROM public.verse_recommendations vr
    WHERE vr.user_id = p_user_id
    ORDER BY vr.recommendation_score DESC
    LIMIT 10;
END;
$$;
```

---

## 🔄 Workflow Offline-First

### Création de Données

**1. Côté Client (Flutter)** :
```dart
// 1. Créer localement (Hive) avec UUID
final newPlan = Plan(
  id: Uuid().v4(),
  userId: currentUser.id,
  name: 'Mon nouveau plan',
  // ...
);
await LocalStorageService.savePlan(newPlan);

// 2. Marquer pour sync
await LocalStorageService.markForSync('plans', newPlan.id);

// 3. Si online, synchroniser immédiatement
if (await ConnectivityService.instance.isOnline) {
  await _syncToSupabase(newPlan);
}
```

**2. Côté Supabase** :
```sql
-- La sync queue va créer l'enregistrement
INSERT INTO public.plans (id, user_id, name, ...)
VALUES ('uuid', 'user-uuid', 'Mon nouveau plan', ...);

-- Et mettre à jour la queue
UPDATE public.sync_queue 
SET status = 'completed', synced_at = NOW()
WHERE record_id = 'uuid';
```

---

### Mise à Jour de Données

**1. Côté Client** :
```dart
// 1. Update optimiste local
final updatedPlan = plan.copyWith(status: 'completed');
await LocalStorageService.updatePlan(updatedPlan);

// 2. Notifier UI immédiatement (Optimistic UI)
notifyListeners();

// 3. Sync en arrière-plan
await LocalStorageService.markForSync('plans', plan.id);
```

**2. Côté Supabase** :
```sql
-- Sync quand online
UPDATE public.plans 
SET status = 'completed', updated_at = NOW()
WHERE id = 'plan-uuid';
```

---

## 📈 Requêtes Utiles

### Obtenir le Dashboard d'un Utilisateur

```sql
WITH user_stats AS (
    SELECT * FROM get_user_stats('user-uuid')
),
current_plan AS (
    SELECT * FROM get_current_plan_progress('user-uuid')
),
today_reading AS (
    SELECT * FROM get_today_reading('user-uuid')
),
recent_meditations AS (
    SELECT * FROM meditation_journals
    WHERE user_id = 'user-uuid'
    ORDER BY date DESC
    LIMIT 7
)
SELECT 
    (SELECT row_to_json(user_stats.*) FROM user_stats) AS stats,
    (SELECT row_to_json(current_plan.*) FROM current_plan) AS plan,
    (SELECT row_to_json(today_reading.*) FROM today_reading) AS today,
    (SELECT json_agg(row_to_json(recent_meditations.*)) FROM recent_meditations) AS recent
;
```

---

### Obtenir les Meilleurs Presets pour un Utilisateur

```sql
SELECT 
    pp.*,
    -- Calculer un score personnalisé
    (
        pp.spiritual_impact * 0.5 +
        CASE 
            WHEN 'beginner' = ANY(pp.recommended_for) THEN 0.3
            WHEN 'regular' = ANY(pp.recommended_for) THEN 0.2
            ELSE 0.1
        END +
        (pp.timing_bonus::REAL / 100) * 0.2
    ) AS personalized_score
FROM public.plan_presets pp
WHERE pp.is_active = TRUE
ORDER BY personalized_score DESC
LIMIT 5;
```

---

### Nettoyer la Sync Queue

```sql
-- Supprimer les entrées complétées de plus de 7 jours
DELETE FROM public.sync_queue
WHERE status = 'completed'
AND synced_at < NOW() - INTERVAL '7 days';

-- Réessayer les entrées failed avec retry_count < 3
UPDATE public.sync_queue
SET status = 'pending', retry_count = retry_count + 1
WHERE status = 'failed'
AND retry_count < 3
AND created_at > NOW() - INTERVAL '24 hours';
```

---

## 🛡️ Sécurité (RLS)

### Principe
Chaque utilisateur **ne voit que ses propres données**.

### Tester les Policies

```sql
-- Se connecter en tant qu'utilisateur test
SET request.jwt.claim.sub = 'user-uuid';

-- Essayer de voir les plans d'un autre utilisateur
SELECT * FROM plans WHERE user_id != 'user-uuid';
-- Résultat : 0 lignes (bloqué par RLS)

-- Voir ses propres plans
SELECT * FROM plans WHERE user_id = 'user-uuid';
-- Résultat : Ses plans uniquement
```

---

## 🔮 Futures Extensions Possibles

### 1. Communauté & Partage

```sql
-- Tables pour fonctionnalités communautaires
CREATE TABLE community_posts (...);
CREATE TABLE community_comments (...);
CREATE TABLE user_follows (...);
```

### 2. Gamification Avancée

```sql
-- Tables pour badges et achievements
CREATE TABLE achievements (...);
CREATE TABLE user_achievements (...);
CREATE TABLE leaderboards (...);
```

### 3. Contenu Premium

```sql
-- Tables pour contenu premium
CREATE TABLE premium_content (...);
CREATE TABLE user_subscriptions (...);
CREATE TABLE payment_history (...);
```

### 4. IA & Personnalisation

```sql
-- Tables pour recommandations IA
CREATE TABLE ai_recommendations (...);
CREATE TABLE user_behavior_patterns (...);
CREATE TABLE content_embeddings (...);
```

### 5. Bible Interactive

```sql
-- Tables pour annotations et études
CREATE TABLE verse_notes (...);
CREATE TABLE cross_references (...);
CREATE TABLE study_groups (...);
```

---

## 🎯 Checklist de Déploiement

### Avant de Déployer

- [ ] Exécuter le script SQL dans Supabase Dashboard
- [ ] Vérifier que toutes les tables sont créées
- [ ] Tester les policies RLS
- [ ] Insérer les plan_presets
- [ ] Créer un utilisateur de test
- [ ] Tester les fonctions RPC

### Après Déploiement

- [ ] Configurer les permissions Edge Functions
- [ ] Activer Realtime si nécessaire
- [ ] Configurer Supabase Storage pour posters
- [ ] Monitorer les performances (indexes)
- [ ] Configurer les backups automatiques

---

## 📝 Maintenance Régulière

### Hebdomadaire
```sql
-- Nettoyer sync_queue
DELETE FROM sync_queue WHERE status = 'completed' AND synced_at < NOW() - INTERVAL '7 days';

-- Archiver vieilles analytics
-- (ou configurer table partitioning)
```

### Mensuelle
```sql
-- Vérifier la croissance des tables
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Analyser les indexes
ANALYZE public.plans;
ANALYZE public.plan_days;
ANALYZE public.meditation_journals;
```

---

## 🎊 Conclusion

Ce schéma est :
- ✅ **Complet** : Couvre toutes les fonctionnalités actuelles
- ✅ **Extensible** : JSONB et structure modulaire
- ✅ **Performant** : Indexes stratégiques
- ✅ **Sécurisé** : RLS sur toutes les tables
- ✅ **Offline-First** : Compatible avec Hive + sync
- ✅ **Évolutif** : Facile d'ajouter de nouvelles fonctionnalités

**Prêt pour la production et l'évolution future ! 🚀**

