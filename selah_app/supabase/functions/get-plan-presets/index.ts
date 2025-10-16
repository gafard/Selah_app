// Edge Function pour récupérer les presets de plans disponibles
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Get Plan Presets Function loaded!")

// CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const category = url.searchParams.get('category') // 'thompson', 'thematic', 'all'
    const theme = url.searchParams.get('theme') // thème Thompson spécifique

    console.log('📋 Get Presets Request:', { category, theme })

    // Créer un client Supabase
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Construire la requête
    let query = supabaseAdmin
      .from('plan_presets')
      .select('*')
      .eq('is_active', true)
      .order('category', { ascending: true })
      .order('name', { ascending: true })

    // Filtrer par catégorie si spécifiée
    if (category && category !== 'all') {
      query = query.eq('category', category)
    }

    // Filtrer par thème si spécifié
    if (theme) {
      query = query.eq('theme', theme)
    }

    const { data: presets, error } = await query

    if (error) {
      console.error('❌ Erreur récupération presets:', error)
      throw new Error(`Erreur lors de la récupération des presets: ${error.message}`)
    }

    console.log('✅ Presets récupérés:', presets?.length || 0)

    // Grouper les presets par catégorie
    const groupedPresets = presets?.reduce((acc, preset) => {
      if (!acc[preset.category]) {
        acc[preset.category] = []
      }
      acc[preset.category].push(preset)
      return acc
    }, {} as Record<string, any[]>) || {}

    return new Response(
      JSON.stringify({ 
        success: true,
        presets: groupedPresets,
        total: presets?.length || 0,
        categories: Object.keys(groupedPresets)
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans get-plan-presets:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

/* 🚀 Edge Function pour récupérer les presets de plans

Cette fonction retourne tous les presets de plans disponibles,
groupés par catégorie:
✅ Presets Thompson (thèmes spirituels)
✅ Presets thématiques (lecture complète, NT, etc.)
✅ Filtrage par catégorie et thème
✅ Tri et organisation

Utilisation depuis Flutter:
GET /functions/v1/get-plan-presets?category=thompson
GET /functions/v1/get-plan-presets?theme=spiritual_demand
GET /functions/v1/get-plan-presets (tous les presets)
*/
