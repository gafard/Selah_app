// Edge Function pour mettre à jour le progrès d'un plan
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Update Plan Progress Function loaded!")

// Interface pour la requête
interface UpdateProgressRequest {
  userId: string
  planId: string
  dayNumber: number
  isCompleted: boolean
  notes?: string
  completedAt?: string // Format ISO
}

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
    const {
      userId,
      planId,
      dayNumber,
      isCompleted,
      notes,
      completedAt
    }: UpdateProgressRequest = await req.json()

    console.log('📋 Update Progress Request:', {
      userId,
      planId,
      dayNumber,
      isCompleted,
      notes: notes ? 'présent' : 'absent'
    })

    // Validation
    if (!userId || !planId || !dayNumber) {
      throw new Error('Paramètres manquants: userId, planId, dayNumber requis')
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

    // Mettre à jour le jour du plan
    const updateData: any = {
      is_completed: isCompleted
    }

    if (notes !== undefined) {
      updateData.notes = notes
    }

    if (isCompleted) {
      updateData.completed_at = completedAt || new Date().toISOString()
    } else {
      updateData.completed_at = null
    }

    const { data: updatedDay, error: updateError } = await supabaseAdmin
      .from('local_plan_days')
      .update(updateData)
      .eq('plan_id', planId)
      .eq('day_number', dayNumber)
      .select()
      .single()

    if (updateError) {
      console.error('❌ Erreur mise à jour jour:', updateError)
      throw new Error(`Erreur lors de la mise à jour: ${updateError.message}`)
    }

    console.log('✅ Jour mis à jour:', updatedDay.day_number)

    // Vérifier si le plan est maintenant complété
    const { data: allDays, error: daysError } = await supabaseAdmin
      .from('local_plan_days')
      .select('is_completed')
      .eq('plan_id', planId)

    if (daysError) {
      console.error('❌ Erreur vérification complétion:', daysError)
    } else {
      const totalDays = allDays?.length || 0
      const completedDays = allDays?.filter(d => d.is_completed).length || 0
      
      // Si tous les jours sont complétés, marquer le plan comme terminé
      if (completedDays >= totalDays && totalDays > 0) {
        const { error: planUpdateError } = await supabaseAdmin
          .from('local_plans')
          .update({ 
            status: 'completed',
            updated_at: new Date().toISOString()
          })
          .eq('id', planId)

        if (planUpdateError) {
          console.error('❌ Erreur mise à jour statut plan:', planUpdateError)
        } else {
          console.log('🎉 Plan marqué comme terminé!')
        }
      }
    }

    // Récupérer les statistiques mises à jour
    const { data: stats, error: statsError } = await supabaseAdmin
      .from('local_plan_days')
      .select('is_completed')
      .eq('plan_id', planId)

    const totalDays = stats?.length || 0
    const completedDays = stats?.filter(d => d.is_completed).length || 0
    const progressPercentage = totalDays > 0 ? Math.round((completedDays / totalDays) * 100) : 0

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Progrès mis à jour avec succès',
        day: updatedDay,
        stats: {
          totalDays,
          completedDays,
          remainingDays: totalDays - completedDays,
          progressPercentage,
          isCompleted: completedDays >= totalDays
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans update-plan-progress:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

/* 🚀 Edge Function pour mettre à jour le progrès d'un plan

Cette fonction met à jour le statut d'un jour de plan avec:
✅ Vérification des permissions utilisateur
✅ Mise à jour du statut de complétion
✅ Gestion des notes
✅ Mise à jour automatique du statut du plan
✅ Calcul des statistiques de progression

Utilisation depuis Flutter:
POST /functions/v1/update-plan-progress
{
  "userId": "xxx",
  "planId": "xxx", 
  "dayNumber": 1,
  "isCompleted": true,
  "notes": "Lecture terminée"
}
*/
