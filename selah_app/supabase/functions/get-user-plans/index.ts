// Edge Function pour récupérer les plans d'un utilisateur
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Get User Plans Function loaded!")

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
    const userId = url.searchParams.get('userId')
    const status = url.searchParams.get('status') // 'active', 'completed', 'all'
    const includeDays = url.searchParams.get('includeDays') === 'true'

    console.log('📋 Get User Plans Request:', { userId, status, includeDays })

    if (!userId) {
      throw new Error('userId est requis')
    }

    // Créer un client Supabase
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Construire la requête pour les plans
    let query = supabaseAdmin
      .from('local_plans')
      .select(`
        *,
        plan_presets(name, slug, description, category, theme)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    // Filtrer par statut si spécifié
    if (status && status !== 'all') {
      query = query.eq('status', status)
    }

    const { data: plans, error: plansError } = await query

    if (plansError) {
      console.error('❌ Erreur récupération plans:', plansError)
      throw new Error(`Erreur lors de la récupération des plans: ${plansError.message}`)
    }

    console.log('✅ Plans récupérés:', plans?.length || 0)

    // Si demandé, récupérer les jours pour chaque plan
    let plansWithDays = plans
    if (includeDays && plans && plans.length > 0) {
      const planIds = plans.map(p => p.id)
      
      const { data: days, error: daysError } = await supabaseAdmin
        .from('local_plan_days')
        .select('*')
        .in('plan_id', planIds)
        .order('day_number', { ascending: true })

      if (daysError) {
        console.error('❌ Erreur récupération jours:', daysError)
        // Ne pas faire échouer pour cette erreur
      } else {
        // Grouper les jours par plan
        const daysByPlan = days?.reduce((acc, day) => {
          if (!acc[day.plan_id]) {
            acc[day.plan_id] = []
          }
          acc[day.plan_id].push(day)
          return acc
        }, {} as Record<string, any[]>) || {}

        // Ajouter les jours aux plans
        plansWithDays = plans?.map(plan => ({
          ...plan,
          days: daysByPlan[plan.id] || []
        }))
      }
    }

    // Calculer les statistiques pour chaque plan
    const plansWithStats = plansWithDays?.map(plan => {
      const totalDays = plan.total_days
      const completedDays = plan.days?.filter(d => d.is_completed).length || 0
      const progressPercentage = totalDays > 0 ? Math.round((completedDays / totalDays) * 100) : 0
      
      return {
        ...plan,
        stats: {
          totalDays,
          completedDays,
          remainingDays: totalDays - completedDays,
          progressPercentage,
          isCompleted: completedDays >= totalDays
        }
      }
    })

    return new Response(
      JSON.stringify({ 
        success: true,
        plans: plansWithStats || [],
        total: plans?.length || 0,
        activePlans: plans?.filter(p => p.status === 'active').length || 0,
        completedPlans: plans?.filter(p => p.status === 'completed').length || 0
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans get-user-plans:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

/* 🚀 Edge Function pour récupérer les plans utilisateur

Cette fonction retourne tous les plans d'un utilisateur avec:
✅ Informations du plan (nom, dates, paramètres)
✅ Informations du preset utilisé (si applicable)
✅ Statistiques de progression
✅ Jours du plan (optionnel)
✅ Filtrage par statut

Utilisation depuis Flutter:
GET /functions/v1/get-user-plans?userId=xxx&status=active&includeDays=true
*/
