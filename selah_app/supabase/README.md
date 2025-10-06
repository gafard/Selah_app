# API Supabase pour Selah

Cette API fournit tous les endpoints nécessaires pour gérer les plans de lecture biblique dans l'application Selah.

## 🚀 Déploiement

### Prérequis
- [Supabase CLI](https://supabase.com/docs/guides/cli) installé
- Compte Supabase créé
- Projet Supabase initialisé

### Installation
```bash
# Installer Supabase CLI
npm install -g supabase

# Se connecter à Supabase
supabase login

# Initialiser le projet (si pas déjà fait)
supabase init

# Lier le projet local au projet distant
supabase link --project-ref YOUR_PROJECT_REF
```

### Déploiement
```bash
# Déployer tout (migrations + functions)
./deploy.sh

# Ou manuellement:
supabase db push
supabase functions deploy plans-from-preset
supabase functions deploy plans-import
supabase functions deploy plans-active
supabase functions deploy plans-days
supabase functions deploy plans-set-active
supabase functions deploy plans-progress
```

## 📊 Base de données

### Tables
- `plans` : Plans de lecture biblique
- `plan_days` : Jours individuels avec lectures

### Sécurité
- Row Level Security (RLS) activé
- Politiques pour que chaque utilisateur ne voit que ses propres plans
- Authentification requise pour tous les endpoints

## ⚡ Edge Functions

### 1. `plans-from-preset`
**POST** `/functions/v1/plans-from-preset`

Crée un plan à partir d'un preset Thompson 21.

**Body:**
```json
{
  "preset_slug": "thompson-compagnie",
  "start_date": "2024-01-01",
  "profile": {
    "minutesPerDay": 15,
    "goals": ["weekend_rest"],
    "level": "beginner"
  }
}
```

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "Compagnie avec Dieu",
  "start_date": "2024-01-01",
  "total_days": 60,
  "is_active": true
}
```

### 2. `plans-import`
**POST** `/functions/v1/plans-import`

Importe un plan depuis un fichier ICS (biblereadingplangenerator.com).

**Body:**
```json
{
  "name": "Plan personnalisé",
  "ics_url": "https://biblereadingplangenerator.com/plan.ics"
}
```

### 3. `plans-active`
**GET** `/functions/v1/plans-active`

Récupère le plan actif de l'utilisateur.

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "Compagnie avec Dieu",
  "start_date": "2024-01-01",
  "total_days": 60,
  "is_active": true
}
```

### 4. `plans-days`
**GET** `/functions/v1/plans-days`

Récupère les jours d'un plan.

**Query params:**
- `from`: Jour de début (optionnel)
- `to`: Jour de fin (optionnel)

**Response:**
```json
[
  {
    "id": "uuid",
    "plan_id": "uuid",
    "day_index": 1,
    "date": "2024-01-01",
    "readings": [
      {
        "book": "Jean",
        "range": "1:1-50",
        "url": "https://biblegateway.com/..."
      }
    ],
    "completed": false
  }
]
```

### 5. `plans-set-active`
**POST** `/functions/v1/plans-set-active`

Active un plan (désactive les autres).

**Response:**
```json
{
  "success": true
}
```

### 6. `plans-progress`
**PATCH** `/functions/v1/plans-progress`

Met à jour le statut de complétion d'un jour.

**Body:**
```json
{
  "completed": true
}
```

## 🔧 Configuration

### Variables d'environnement
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Headers requis
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
Idempotency-Key: <uuid> (pour les opérations de création)
```

## 🧪 Test local

```bash
# Démarrer Supabase localement
supabase start

# Tester les functions
curl -X POST http://localhost:54321/functions/v1/plans-from-preset \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"preset_slug": "thompson-compagnie", "start_date": "2024-01-01", "profile": {}}'
```

## 📝 Logs

```bash
# Voir les logs des functions
supabase functions logs plans-from-preset
supabase functions logs plans-import
# etc.
```

## 🔄 Intégration avec l'app Flutter

L'application Flutter utilise `PlanServiceHttp` qui fait des appels à ces endpoints avec :
- Cache Hive pour l'offline-first
- Queue de sync pour les opérations offline
- Idempotency keys pour éviter les doublons
- Gestion d'erreurs gracieuse
