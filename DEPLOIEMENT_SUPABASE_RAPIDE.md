# 🚀 DÉPLOIEMENT RAPIDE - Schéma Supabase

## ⚡ En 5 Minutes

### Étape 1 : Ouvrir Supabase Dashboard
1. Aller sur https://app.supabase.com
2. Sélectionner votre projet Selah
3. Cliquer sur **SQL Editor** dans le menu gauche

### Étape 2 : Créer Nouvelle Query
1. Cliquer sur **+ New query**
2. Nommer : "Schema Selah V2"

### Étape 3 : Copier le Script
1. Ouvrir `SCHEMA_SUPABASE_COMPLET_V2.sql`
2. **Copier TOUT le contenu** (Cmd+A, Cmd+C)
3. **Coller** dans l'éditeur Supabase (Cmd+V)

### Étape 4 : Exécuter
1. Cliquer sur **RUN** (ou Cmd+Enter)
2. Attendre ~10-15 secondes
3. Vérifier : **Success. No rows returned**

### Étape 5 : Vérifier
```sql
-- Copier et exécuter cette requête
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Vous devriez voir 13 tables** :
- bible_versions
- meditation_journals
- notifications_queue
- plan_days
- plan_presets
- plans
- prayer_subjects
- reader_settings
- sync_queue
- user_analytics
- user_progress
- users
- verse_highlights

---

## ✅ Validation Rapide

### Vérifier les Fonctions
```sql
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
ORDER BY routine_name;
```

**Vous devriez voir 6 fonctions** :
- get_current_plan_progress
- get_today_reading
- get_user_stats
- handle_new_user
- update_updated_at
- update_user_streak

---

### Vérifier les Triggers
```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

**Vous devriez voir 9 triggers** (tous avec `_updated_at`)

---

### Vérifier les Policies RLS
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

**Vous devriez voir 13+ policies**

---

## ⚠️ En Cas d'Erreur

### Erreur : "relation already exists"
**Solution** : C'est normal si vous réexécutez le script
- Les `DROP TABLE IF EXISTS` suppriment d'abord
- Puis recréent tout
- Pas de problème !

### Erreur : "permission denied"
**Solution** : Vérifiez que vous êtes bien connecté à Supabase
- Rechargez la page
- Reconnectez-vous si nécessaire

### Erreur : "syntax error"
**Solution** : Assurez-vous d'avoir copié TOUT le script
- Vérifiez qu'il n'y a pas de caractères manquants
- Réessayez la copie

---

## 🎯 Après le Déploiement

### 1. Tester avec un Compte Test
```sql
-- Dans SQL Editor
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
VALUES (
  gen_random_uuid(),
  'test@selah.app',
  crypt('password123', gen_salt('bf')),
  NOW()
);
```

**Note** : Le trigger `handle_new_user()` va automatiquement créer :
- Une entrée dans `users`
- Une entrée dans `reader_settings`  
- Une entrée dans `user_progress`

### 2. Vérifier la Création Automatique
```sql
SELECT * FROM users WHERE email = 'test@selah.app';
SELECT * FROM reader_settings WHERE user_id = (SELECT id FROM users WHERE email = 'test@selah.app');
SELECT * FROM user_progress WHERE user_id = (SELECT id FROM users WHERE email = 'test@selah.app');
```

### 3. Tester avec l'Application
1. Lancer l'app Flutter
2. Créer un compte
3. Vérifier dans Supabase Dashboard → **Table Editor**
4. Voir les données apparaître en temps réel

---

## 📊 Monitoring

### Dashboard Rapide
```sql
-- Nombre total d'utilisateurs
SELECT COUNT(*) AS total_users FROM users;

-- Nombre de plans actifs
SELECT COUNT(*) AS active_plans FROM plans WHERE status = 'active';

-- Méditations aujourd'hui
SELECT COUNT(*) AS meditations_today 
FROM meditation_journals 
WHERE date = CURRENT_DATE;

-- Sync queue en attente
SELECT COUNT(*) AS pending_sync 
FROM sync_queue 
WHERE status = 'pending';
```

---

## 🎊 C'est Terminé !

Votre base de données Selah est maintenant prête ! ✅

**Prochaine étape** : Tester avec l'application Flutter

---

**Temps total : ~5-10 minutes**

