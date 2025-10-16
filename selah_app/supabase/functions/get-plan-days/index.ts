// Edge Function pour récupérer les jours d'un plan
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Get Plan Days Function loaded!")

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
    const planId = url.searchParams.get('planId')
    const userId = url.searchParams.get('userId')
    const fromDay = url.searchParams.get('fromDay')
    const toDay = url.searchParams.get('toDay')
    const date = url.searchParams.get('date') // date spécifique (YYYY-MM-DD)

    console.log('📋 Get Plan Days Request:', { planId, userId, fromDay, toDay, date })

    if (!planId || !userId) {
      throw new Error('planId et userId sont requis')
    }

    // Créer un client Supabase
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Vérifier que l'utilisateur a accès à ce plan
    const { data: plan, error: planError } = await supabaseAdmin
      .from('local_plans')
      .select('id, user_id, name, status')
      .eq('id', planId)
      .eq('user_id', userId)
      .single()

    if (planError || !plan) {
      console.error('❌ Plan non trouvé ou accès refusé:', planError)
      throw new Error('Plan non trouvé ou accès refusé')
    }

    console.log('✅ Plan vérifié:', plan.name)

    // Construire la requête pour les jours
    let query = supabaseAdmin
      .from('local_plan_days')
      .select('*')
      .eq('plan_id', planId)
      .order('day_number', { ascending: true })

    // Filtrer par jour si spécifié
    if (fromDay) {
      query = query.gte('day_number', parseInt(fromDay))
    }
    if (toDay) {
      query = query.lte('day_number', parseInt(toDay))
    }

    // Filtrer par date si spécifiée
    if (date) {
      query = query.eq('date', date)
    }

    const { data: days, error: daysError } = await query

    if (daysError) {
      console.error('❌ Erreur récupération jours:', daysError)
      throw new Error(`Erreur lors de la récupération des jours: ${daysError.message}`)
    }

    console.log('✅ Jours récupérés:', days?.length || 0)

    // Calculer les statistiques
    const totalDays = days?.length || 0
    const completedDays = days?.filter(d => d.is_completed).length || 0
    const progressPercentage = totalDays > 0 ? Math.round((completedDays / totalDays) * 100) : 0

    // Trouver le jour actuel (premier jour non complété)
    const currentDay = days?.find(d => !d.is_completed)
    const currentDayNumber = currentDay?.day_number || (totalDays > 0 ? totalDays : 1)

    return new Response(
      JSON.stringify({ 
        success: true,
        plan: {
          id: plan.id,
          name: plan.name,
          status: plan.status
        },
        days: days || [],
        stats: {
          totalDays,
          completedDays,
          remainingDays: totalDays - completedDays,
          progressPercentage,
          currentDayNumber,
          isCompleted: completedDays >= totalDays
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans get-plan-days:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

/* 🚀 Edge Function pour récupérer les jours d'un plan

Cette fonction retourne les jours d'un plan avec:
✅ Vérification des permissions utilisateur
✅ Filtrage par jour (fromDay, toDay)
✅ Filtrage par date spécifique
✅ Statistiques de progression
✅ Jour actuel (premier non complété)

Utilisation depuis Flutter:
GET /functions/v1/get-plan-days?planId=xxx&userId=xxx&fromDay=1&toDay=7
GET /functions/v1/get-plan-days?planId=xxx&userId=xxx&date=2024-12-01
*/
