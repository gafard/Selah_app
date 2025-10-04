// Supabase Edge Function pour créer des plans de lecture biblique
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Create Reading Plan Function loaded!")

// Interface pour le corps de la requête entrante
interface RequestBody {
  userId: string
  planName: string
  parameters: {
    order?: string
    books?: string[]
    categories?: string[]
    totalDays?: number
    daysOfWeek?: number[]
  }
  startDate: string // Format 'YYYY-MM-DD'
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
    const { userId, planName, parameters, startDate }: RequestBody = await req.json()
    console.log('📋 Requête reçue:', { userId, planName, parameters, startDate })

    if (!userId || !planName || !parameters || !startDate) {
      throw new Error('Paramètres manquants.')
    }

    // 1. CRÉER UN CLIENT SUPABASE AVEC LA CLÉ SERVICE ROLE
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 2. CONSTRUIRE L'URL AVEC LES BONS PARAMÈTRES
    const baseUrl = 'https://www.biblereadingplangenerator.com/'
    const urlParams = new URLSearchParams({
      start: startDate,
      total: (parameters.totalDays || 365).toString(),
      format: 'list',
      lang: 'fr',
      logic: 'words',
      daysofweek: parameters.daysOfWeek?.join(',') || '1,2,3,4,5,6,7',
      books: mapBooksToApiFormat(parameters.books || []),
      order: parameters.order || 'traditional'
    })

    const fullUrl = `${baseUrl}?${urlParams.toString()}`
    console.log('🌐 URL API:', fullUrl)

    // 3. APPELER L'API RÉELLE ET PARSER LE HTML
    const htmlResponse = await fetch(fullUrl, {
      headers: { 'User-Agent': 'Selah-App/1.0' }
    })
    
    if (!htmlResponse.ok) {
      throw new Error('Échec de la récupération du plan depuis le générateur.')
    }

    const html = await htmlResponse.text()
    console.log('📄 HTML reçu (taille):', html.length, 'caractères')
    
    // 4. PARSER LE HTML POUR EXTRAIRE LES LECTURES
    const readings = parseHtmlReadings(html)
    console.log('📚 Lectures extraites:', readings.length)
    
    if (readings.length === 0) {
      throw new Error('Aucune lecture trouvée dans le HTML retourné.')
    }

    // 5. INSÉRER LE PLAN DANS LA BASE DE DONNÉES
    const { data: newPlan, error: planError } = await supabaseAdmin
      .from('plans')
      .insert({
        user_id: userId,
        name: planName,
        start_date: startDate,
        total_days: readings.length,
        raw_content: html,
        parameters: parameters,
        status: 'active'
      })
      .select()
      .single()

    if (planError) {
      console.error('❌ Erreur insertion plan:', planError)
      throw new Error(`Erreur lors de la création du plan: ${planError.message}`)
    }

    const planId = newPlan.id
    console.log('✅ Plan créé avec ID:', planId)

    // 6. INSÉRER LES JOURS DU PLAN
    const planDaysToInsert = readings.map((reference, index) => ({
      plan_id: planId,
      day_number: index + 1,
      date: new Date(new Date(startDate).getTime() + index * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      bible_references: [reference],
      status: 'pending',
    }))

    const { error: daysError } = await supabaseAdmin
      .from('plan_days')
      .insert(planDaysToInsert)

    if (daysError) {
      console.error('❌ Erreur insertion jours:', daysError)
      throw new Error(`Erreur lors de l'insertion des jours: ${daysError.message}`)
    }

    // 7. METTRE À JOUR L'UTILISATEUR VIA LA FONCTION RPC
    const { error: updateError } = await supabaseAdmin.rpc('update_user_current_plan', {
      user_id: userId,
      plan_id: planId
    })

    if (updateError) {
      console.error('❌ Erreur mise à jour utilisateur:', updateError)
      throw new Error(`Erreur lors de la mise à jour utilisateur: ${updateError.message}`)
    }

    console.log('🎉 Plan créé avec succès!')

    return new Response(
      JSON.stringify({ 
        success: true,
        planId: planId,
        message: 'Plan de lecture créé avec succès',
        totalDays: readings.length
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans create-reading-plan:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

// Mapper les livres vers le format de l'API
function mapBooksToApiFormat(books: string[]): string {
  if (!books || books.length === 0) return 'OT,NT'
  
  const hasOT = books.some(book => 
    ['Genèse', 'Exode', 'Psaumes', 'Proverbes', 'Ésaïe', 'OT'].includes(book)
  )
  const hasNT = books.some(book => 
    ['Matthieu', 'Marc', 'Luc', 'Jean', 'Romains', 'Actes', 'NT'].includes(book)
  )
  
  if (hasOT && hasNT) return 'OT,NT'
  if (hasOT) return 'OT'
  if (hasNT) return 'NT'
  return 'OT,NT'
}

// Parser le HTML pour extraire les lectures bibliques
function parseHtmlReadings(html: string): string[] {
  const readings: string[] = []
  
  try {
    // Méthode 1: Chercher les liens vers BibleGateway
    const linkRegex = /<a[^>]*href="[^"]*\/passage\/\?search=([^"&]+)"[^>]*>([^<]+)<\/a>/gi
    let match
    
    while ((match = linkRegex.exec(html)) !== null) {
      const reference = decodeURIComponent(match[1]).replace(/\+/g, ' ')
      if (reference && !readings.includes(reference)) {
        readings.push(reference)
      }
    }
    
    // Méthode 2: Si pas de liens, chercher des patterns de références bibliques
    if (readings.length === 0) {
      const refRegex = /\b(\d?\s*[A-Za-z]+\s+\d+(?::\d+)?(?:-\d+(?::\d+)?)?(?:;\s*\d+(?::\d+)?(?:-\d+(?::\d+)?)?)*)\b/g
      const matches = html.match(refRegex) || []
      
      matches.forEach(ref => {
        const cleanRef = ref.trim()
        if (cleanRef.length > 3 && !readings.includes(cleanRef)) {
          readings.push(cleanRef)
        }
      })
    }
    
    // Méthode 3: Pattern simple pour "Day X: Reference"
    if (readings.length === 0) {
      const dayPattern = /Day\s+\d+:\s*([^\n\r<]+)/gi
      
      while ((match = dayPattern.exec(html)) !== null) {
        const reference = match[1].trim()
        if (reference && !readings.includes(reference)) {
          readings.push(reference)
        }
      }
    }
    
  } catch (error) {
    console.error('Erreur lors du parsing HTML:', error)
  }
  
  return readings.slice(0, 365) // Limiter à 365 jours maximum
}

/* 🚀 Version simplifiée et optimisée pour Selah App

Cette Edge Function:
✅ Appelle l'API réelle de génération de plans bibliques
✅ Parse le HTML retourné pour extraire les lectures
✅ Insère le plan et les jours dans Supabase
✅ Met à jour l'utilisateur avec son nouveau plan actif
✅ Gère les erreurs de manière robuste

Pour tester:
1. Déployer: supabase functions deploy create-reading-plan
2. Utiliser depuis Flutter via: Supabase.instance.client.functions.invoke('create-reading-plan', ...)
*/