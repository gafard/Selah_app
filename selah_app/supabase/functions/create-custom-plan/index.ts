// Supabase Edge Function pour créer des plans de lecture biblique personnalisés
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Create Custom Plan Function loaded!")

// Interface pour le corps de la requête entrante
interface CustomPlanRequest {
  userId: string
  planName: string
  startDate: string // Format 'YYYY-MM-DD'
  totalDays: number
  readingOrder: string // 'traditional' | 'chronological' | 'thematic'
  selectedBooks: string[] // ['OT', 'NT'] ou livres spécifiques
  selectedDays: number[] // [1,2,3,4,5,6,7] pour tous les jours
  overlapOtNt?: boolean // Permettre le chevauchement AT/NT
  reverseOrder?: boolean // Ordre inverse
  showStats?: boolean // Afficher les statistiques
  dailyPsalm?: boolean // Psaume quotidien
  dailyProverb?: boolean // Proverbe quotidien
}

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
      planName,
      startDate,
      totalDays,
      readingOrder,
      selectedBooks,
      selectedDays,
      overlapOtNt = false,
      reverseOrder = false,
      showStats = false,
      dailyPsalm = false,
      dailyProverb = false
    }: CustomPlanRequest = await req.json()

    console.log('📋 Custom Plan Request:', {
      userId,
      planName,
      startDate,
      totalDays,
      readingOrder,
      selectedBooks,
      selectedDays
    })

    // Validation des paramètres
    if (!userId || !planName || !startDate || !totalDays || !selectedBooks || !selectedDays) {
      throw new Error('Paramètres manquants: userId, planName, startDate, totalDays, selectedBooks, selectedDays requis')
    }

    if (totalDays < 1 || totalDays > 365) {
      throw new Error('totalDays doit être entre 1 et 365')
    }

    // Créer un client Supabase avec privilèges administrateur
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 1. CONSTRUIRE L'URL AVEC LES PARAMÈTRES PERSONNALISÉS
    const baseUrl = 'https://www.biblereadingplangenerator.com/'
    const urlParams = new URLSearchParams({
      start: startDate,
      total: totalDays.toString(),
      format: 'list',
      lang: 'fr',
      logic: 'words',
      daysofweek: selectedDays.join(','),
      books: mapBooksToApiFormat(selectedBooks),
      order: readingOrder || 'traditional'
    })

    // Paramètres optionnels
    if (overlapOtNt) urlParams.append('otntoverlap', '1')
    if (reverseOrder) urlParams.append('reverse', '1')
    if (showStats) urlParams.append('stats', '1')
    if (dailyPsalm) urlParams.append('dailypsalm', '1')
    if (dailyProverb) urlParams.append('dailyproverb', '1')

    const fullUrl = `${baseUrl}?${urlParams.toString()}`
    console.log('🌐 Custom Plan URL:', fullUrl)

    // 2. APPELER L'API EXTERNE ET PARSER LE HTML
    const htmlResponse = await fetch(fullUrl, {
      headers: { 'User-Agent': 'Selah-App/1.0' }
    })
    
    if (!htmlResponse.ok) {
      throw new Error(`Échec de la récupération du plan: ${htmlResponse.status} ${htmlResponse.statusText}`)
    }

    const html = await htmlResponse.text()
    console.log('📄 HTML reçu (taille):', html.length, 'caractères')
    
    // 3. PARSER LE HTML POUR EXTRAIRE LES LECTURES
    const readings = parseHtmlReadings(html)
    console.log('📚 Lectures extraites:', readings.length)
    
    if (readings.length === 0) {
      throw new Error('Aucune lecture trouvée dans le HTML retourné. Vérifiez vos paramètres.')
    }

    // 4. INSÉRER LE PLAN PERSONNALISÉ DANS LA BASE DE DONNÉES
    const { data: newPlan, error: planError } = await supabaseAdmin
      .from('plans')
      .insert({
        user_id: userId,
        name: planName,
        start_date: startDate,
        total_days: readings.length,
        raw_content: html,
        parameters: {
          readingOrder,
          selectedBooks,
          selectedDays,
          overlapOtNt,
          reverseOrder,
          showStats,
          dailyPsalm,
          dailyProverb,
          isCustomPlan: true
        },
        status: 'active'
      })
      .select()
      .single()

    if (planError) {
      console.error('❌ Erreur insertion plan:', planError)
      throw new Error(`Erreur lors de la création du plan: ${planError.message}`)
    }

    const planId = newPlan.id
    console.log('✅ Plan personnalisé créé avec ID:', planId)

    // 5. INSÉRER LES JOURS DU PLAN
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

    // 6. METTRE À JOUR L'UTILISATEUR VIA LA FONCTION RPC
    const { error: updateError } = await supabaseAdmin.rpc('update_user_current_plan', {
      user_id: userId,
      plan_id: planId
    })

    if (updateError) {
      console.error('❌ Erreur mise à jour utilisateur:', updateError)
      throw new Error(`Erreur lors de la mise à jour utilisateur: ${updateError.message}`)
    }

    console.log('🎉 Plan personnalisé créé avec succès!')

    return new Response(
      JSON.stringify({ 
        success: true,
        planId: planId,
        message: 'Plan personnalisé créé avec succès',
        totalDays: readings.length,
        generatedUrl: fullUrl
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans create-custom-plan:', error.message)
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
  
  // Si les livres contiennent directement OT/NT
  if (books.includes('OT') && books.includes('NT')) return 'OT,NT'
  if (books.includes('OT')) return 'OT'
  if (books.includes('NT')) return 'NT'
  
  // Sinon, mapper les livres spécifiques
  const hasOT = books.some(book => 
    ['Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome', 'Josué', 'Juges', 
     'Ruth', 'Samuel', 'Rois', 'Chroniques', 'Esdras', 'Néhémie', 'Esther', 
     'Job', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique', 'Ésaïe', 
     'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos', 
     'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie', 'Aggée', 
     'Zacharie', 'Malachie'].includes(book)
  )
  
  const hasNT = books.some(book => 
    ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', 'Corinthiens', 
     'Galates', 'Éphésiens', 'Philippiens', 'Colossiens', 'Thessaloniciens', 
     'Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques', 'Pierre', 'Jean', 
     'Jude', 'Apocalypse'].includes(book)
  )
  
  if (hasOT && hasNT) return 'OT,NT'
  if (hasOT) return 'OT'
  if (hasNT) return 'NT'
  return 'OT,NT' // Par défaut
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

/* 🚀 Edge Function pour plans personnalisés de Selah App

Cette fonction permet aux utilisateurs de créer des plans de lecture biblique
entièrement personnalisés avec:
✅ Choix des livres (AT, NT, ou livres spécifiques)
✅ Ordre de lecture (traditionnel, chronologique, thématique)
✅ Jours de la semaine sélectionnables
✅ Options avancées (chevauchement, ordre inverse, statistiques)
✅ Psaumes et Proverbes quotidiens optionnels

Utilisation depuis Flutter:
Supabase.instance.client.functions.invoke('create-custom-plan', body: {...})
*/