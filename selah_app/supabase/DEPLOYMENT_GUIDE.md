# Guide de déploiement Supabase pour Selah

## 📋 Prérequis

1. **Supabase CLI installé** :
   ```bash
   npm install -g supabase
   ```

2. **Connexion à votre projet** :
   ```bash
   supabase login
   supabase link --project-ref rvwwgvzuwlxnnzumsqvg
   ```

## 🗄️ 1. Déployer le schéma de base de données

```bash
# Naviguer vers le dossier supabase
cd selah_app/supabase

# Appliquer les migrations (dans l'ordre)
supabase db push

# Ou si vous préférez utiliser l'interface web :
# 1. Aller sur https://supabase.com/dashboard/project/rvwwgvzuwlxnnzumsqvg/sql
# 2. Copier le contenu de migrations/003_enhanced_schema.sql (recommandé)
# 3. L'exécuter dans l'éditeur SQL
```

**Recommandation** : Utilisez la migration `003_enhanced_schema.sql` qui contient :
- ✅ **Types ENUM** pour les tâches (`reading`, `meditation`, `prayer`, etc.)
- ✅ **Contraintes de validation** robustes
- ✅ **Triggers de sécurité** pour `user_id`
- ✅ **Index optimisés** pour les performances
- ✅ **Politiques RLS** complètes et sécurisées

## ⚡ 2. Déployer les Edge Functions

```bash
# Déployer toutes les fonctions
supabase functions deploy plans-from-preset
supabase functions deploy plans-active
supabase functions deploy plans-import

# Ou déployer toutes en une fois
supabase functions deploy
```

## 🔧 3. Configurer les variables d'environnement

Les Edge Functions utilisent automatiquement les variables d'environnement de Supabase :
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Ces variables sont automatiquement disponibles dans les Edge Functions.

## 🧪 4. Tester les endpoints

### Tester `/plans/from-preset` :
```bash
curl -X POST 'https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/from-preset' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "presetSlug": "thompson:1234567890",
    "startDate": "2025-01-15",
    "profile": {
      "level": "Nouveau converti",
      "goal": "Discipline quotidienne",
      "minutesPerDay": 30,
      "totalDays": 21
    }
  }'
```

### Tester `/plans/active` :
```bash
curl -X GET 'https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/active' \
  -H 'Authorization: Bearer YOUR_ANON_KEY'
```

### Tester `/plans/import` :
```bash
curl -X POST 'https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/import' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "icsUrl": "https://example.com/plan.ics",
    "startDate": "2025-01-15",
    "profile": {
      "level": "Intermédiaire",
      "minutesPerDay": 45
    }
  }'
```

## 🔐 5. Vérifier les permissions

1. **Aller sur** : https://supabase.com/dashboard/project/rvwwgvzuwlxnnzumsqvg/auth/policies
2. **Vérifier** que les politiques RLS sont actives pour les tables :
   - `plans`
   - `plan_days` 
   - `plan_tasks`

## 📱 6. Mettre à jour l'application Flutter

Une fois les endpoints déployés, l'application Flutter pourra les utiliser. Les URLs seront :
- `https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/from-preset`
- `https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/active`
- `https://rvwwgvzuwlxnnzumsqvg.supabase.co/functions/v1/plans/import`

## 🐛 7. Debugging

### Voir les logs des Edge Functions :
```bash
supabase functions logs plans-from-preset
supabase functions logs plans-active
supabase functions logs plans-import
```

### Tester localement :
```bash
supabase functions serve
```

## ✅ 8. Vérification finale

1. **Base de données** : Vérifier que les tables sont créées
2. **Edge Functions** : Vérifier qu'elles sont déployées et fonctionnelles
3. **Permissions** : Vérifier que les utilisateurs peuvent créer/consulter leurs plans
4. **Application** : Tester la création de plan depuis l'app

## 🔄 9. Mise à jour future

Pour mettre à jour les fonctions :
```bash
# Modifier le code dans supabase/functions/
# Puis redéployer
supabase functions deploy
```

Pour mettre à jour le schéma :
```bash
# Créer une nouvelle migration
supabase migration new add_new_feature
# Modifier le fichier de migration
# Puis appliquer
supabase db push
```
