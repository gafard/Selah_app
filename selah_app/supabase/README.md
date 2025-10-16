# API Supabase pour Selah (Système 100% Local)

Cette API fournit tous les endpoints nécessaires pour gérer les plans de lecture biblique générés localement dans l'application Selah, avec support des presets Thompson et plans personnalisés.

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
- `plan_presets` : Presets de plans (Thompson, thématiques)
- `local_plans` : Plans générés localement
- `local_plan_days` : Jours individuels avec lectures
- `user_profiles_extended` : Profils utilisateur étendus

### Sécurité
- Row Level Security (RLS) activé
- Politiques pour que chaque utilisateur ne voit que ses propres plans
- Authentification requise pour tous les endpoints
- Presets en lecture publique, modification admin uniquement

## ⚡ Edge Functions (Système Local)

### 1. `generate-local-plan`
**POST** `/functions/v1/generate-local-plan`

Génère un plan de lecture 100% localement (preset ou personnalisé).

**Body:**
```json
{
  "userId": "uuid",
  "planName": "Mon Plan Spirituel",
  "presetId": "uuid", // optionnel
  "isCustom": false,
  "startDate": "2024-01-01",
  "parameters": {
    "totalDays": 30,
    "order": "traditional",
    "books": ["OT", "NT"],
    "focus": "spiritual_growth",
    "daysPerWeek": 7,
    "minutesPerDay": 15,
    "includePsalms": true,
    "includeProverbs": false
  },
  "profileData": { /* données du profil utilisateur */ }
}
```

**Response:**
```json
{
  "success": true,
  "planId": "uuid",
  "message": "Plan local généré avec succès",
  "totalDays": 30,
  "generatedDays": 30
}
```

### 2. `get-plan-presets`
**GET** `/functions/v1/get-plan-presets`

Récupère tous les presets disponibles.

**Query params:**
- `category`: 'thompson', 'thematic', 'all'
- `theme`: thème Thompson spécifique

**Response:**
```json
{
  "success": true,
  "presets": {
    "thompson": [
      {
        "id": "uuid",
        "name": "Exigence Spirituelle",
        "slug": "thompson-spiritual-demand",
        "description": "Plan pour approfondir sa spiritualité",
        "theme": "spiritual_demand",
        "parameters": { /* paramètres du preset */ }
      }
    ]
  },
  "total": 12,
  "categories": ["thompson", "thematic"]
}
```

### 3. `get-user-plans`
**GET** `/functions/v1/get-user-plans`

Récupère tous les plans d'un utilisateur.

**Query params:**
- `userId`: ID de l'utilisateur
- `status`: 'active', 'completed', 'all'
- `includeDays`: true/false

**Response:**
```json
{
  "success": true,
  "plans": [
    {
      "id": "uuid",
      "name": "Mon Plan Spirituel",
      "start_date": "2024-01-01",
      "total_days": 30,
      "status": "active",
      "stats": {
        "totalDays": 30,
        "completedDays": 5,
        "remainingDays": 25,
        "progressPercentage": 17,
        "isCompleted": false
      },
      "days": [ /* jours du plan si includeDays=true */ ]
    }
  ],
  "total": 1,
  "activePlans": 1,
  "completedPlans": 0
}
```

### 4. `get-plan-days`
**GET** `/functions/v1/get-plan-days`

Récupère les jours d'un plan.

**Query params:**
- `planId`: ID du plan
- `userId`: ID de l'utilisateur
- `fromDay`: Jour de début (optionnel)
- `toDay`: Jour de fin (optionnel)
- `date`: Date spécifique (optionnel)

**Response:**
```json
{
  "success": true,
  "plan": {
    "id": "uuid",
    "name": "Mon Plan Spirituel",
    "status": "active"
  },
  "days": [
    {
      "id": "uuid",
      "day_number": 1,
      "date": "2024-01-01",
      "bible_references": ["Jean 1", "Psaume 1"],
      "meditation_theme": "Paix et sérénité",
      "prayer_subjects": [ /* sujets de prière */ ],
      "memory_verse": "Car Dieu a tant aimé le monde...",
      "is_completed": false
    }
  ],
  "stats": {
    "totalDays": 30,
    "completedDays": 5,
    "remainingDays": 25,
    "progressPercentage": 17,
    "currentDayNumber": 6,
    "isCompleted": false
  }
}
```

### 5. `update-plan-progress`
**POST** `/functions/v1/update-plan-progress`

Met à jour le progrès d'un jour de plan.

**Body:**
```json
{
  "userId": "uuid",
  "planId": "uuid",
  "dayNumber": 1,
  "isCompleted": true,
  "notes": "Lecture terminée avec méditation"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Progrès mis à jour avec succès",
  "day": { /* jour mis à jour */ },
  "stats": {
    "totalDays": 30,
    "completedDays": 6,
    "remainingDays": 24,
    "progressPercentage": 20,
    "isCompleted": false
  }
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
