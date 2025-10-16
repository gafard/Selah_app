#!/bin/bash

# Script de déploiement pour Supabase Edge Functions (Système 100% Local)

echo "🚀 Déploiement des Edge Functions Supabase (Système Local)..."

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI n'est pas installé. Installez-le avec:"
    echo "npm install -g supabase"
    exit 1
fi

# Vérifier que l'utilisateur est connecté
if ! supabase projects list &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Supabase. Connectez-vous avec:"
    echo "supabase login"
    exit 1
fi

# Déployer les migrations
echo "📊 Déploiement des migrations (Système Local)..."
supabase db push

# Déployer les nouvelles Edge Functions pour le système local
echo "⚡ Déploiement des Edge Functions (Système Local)..."

# Function: generate-local-plan
echo "  - generate-local-plan"
supabase functions deploy generate-local-plan

# Function: get-plan-presets
echo "  - get-plan-presets"
supabase functions deploy get-plan-presets

# Function: get-user-plans
echo "  - get-user-plans"
supabase functions deploy get-user-plans

# Function: get-plan-days
echo "  - get-plan-days"
supabase functions deploy get-plan-days

# Function: update-plan-progress
echo "  - update-plan-progress"
supabase functions deploy update-plan-progress

# Déployer les anciennes fonctions (pour compatibilité)
echo "🔄 Déploiement des fonctions de compatibilité..."

# Function: create-reading-plan
echo "  - create-reading-plan"
supabase functions deploy create-reading-plan

# Function: create-custom-plan
echo "  - create-custom-plan"
supabase functions deploy create-custom-plan

echo "✅ Déploiement terminé!"
echo ""
echo "📋 Nouveaux Endpoints (Système Local):"
echo "  - POST /functions/v1/generate-local-plan"
echo "  - GET  /functions/v1/get-plan-presets"
echo "  - GET  /functions/v1/get-user-plans"
echo "  - GET  /functions/v1/get-plan-days"
echo "  - POST /functions/v1/update-plan-progress"
echo ""
echo "📋 Endpoints de Compatibilité:"
echo "  - POST /functions/v1/create-reading-plan"
echo "  - POST /functions/v1/create-custom-plan"
echo ""
echo "📊 Tables créées:"
echo "  - plan_presets (presets de plans)"
echo "  - local_plans (plans générés localement)"
echo "  - local_plan_days (jours des plans)"
echo "  - user_profiles_extended (profils utilisateur étendus)"
echo ""
echo "🔧 Pour obtenir l'URL de votre projet:"
echo "supabase status"
