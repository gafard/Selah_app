#!/bin/bash

# Script de déploiement pour Supabase Edge Functions

echo "🚀 Déploiement des Edge Functions Supabase..."

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
echo "📊 Déploiement des migrations..."
supabase db push

# Déployer les Edge Functions
echo "⚡ Déploiement des Edge Functions..."

# Function: plans-from-preset
echo "  - plans-from-preset"
supabase functions deploy plans-from-preset

# Function: plans-import
echo "  - plans-import"
supabase functions deploy plans-import

# Function: plans-active
echo "  - plans-active"
supabase functions deploy plans-active

# Function: plans-days
echo "  - plans-days"
supabase functions deploy plans-days

# Function: plans-set-active
echo "  - plans-set-active"
supabase functions deploy plans-set-active

# Function: plans-progress
echo "  - plans-progress"
supabase functions deploy plans-progress

echo "✅ Déploiement terminé!"
echo ""
echo "📋 URLs des endpoints:"
echo "  - POST /functions/v1/plans-from-preset"
echo "  - POST /functions/v1/plans-import"
echo "  - GET  /functions/v1/plans-active"
echo "  - GET  /functions/v1/plans-days"
echo "  - POST /functions/v1/plans-set-active"
echo "  - PATCH /functions/v1/plans-progress"
echo ""
echo "🔧 Pour obtenir l'URL de votre projet:"
echo "supabase status"
