#!/bin/bash

# Script de test pour l'API Supabase

# Configuration
SUPABASE_URL="https://your-project.supabase.co/functions/v1"
JWT_TOKEN="your-jwt-token-here"

echo "🧪 Test de l'API Supabase Selah"
echo "================================"

# Test 1: Créer un plan depuis un preset
echo ""
echo "1️⃣ Test création de plan depuis preset..."
curl -X POST "$SUPABASE_URL/plans-from-preset" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{
    "preset_slug": "thompson-compagnie",
    "start_date": "2024-01-01",
    "profile": {
      "minutesPerDay": 15,
      "goals": ["weekend_rest"],
      "level": "beginner"
    }
  }' | jq '.'

# Test 2: Récupérer le plan actif
echo ""
echo "2️⃣ Test récupération du plan actif..."
curl -X GET "$SUPABASE_URL/plans-active" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

# Test 3: Récupérer les jours du plan
echo ""
echo "3️⃣ Test récupération des jours du plan..."
PLAN_ID="your-plan-id-here"
curl -X GET "$SUPABASE_URL/plans-days?from=1&to=7" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" | jq '.'

# Test 4: Marquer un jour comme complété
echo ""
echo "4️⃣ Test mise à jour du progrès..."
curl -X PATCH "$SUPABASE_URL/plans-progress" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{
    "completed": true
  }' | jq '.'

echo ""
echo "✅ Tests terminés!"
echo ""
echo "💡 Pour utiliser ce script:"
echo "1. Remplacez SUPABASE_URL par votre URL de projet"
echo "2. Remplacez JWT_TOKEN par un token valide"
echo "3. Remplacez PLAN_ID par un ID de plan valide"
echo "4. Exécutez: chmod +x test-api.sh && ./test-api.sh"
