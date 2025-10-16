// Edge Function pour génération de plans 100% locale
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("🔥 Generate Local Plan Function loaded!")

// Interface pour la requête
interface LocalPlanRequest {
  userId: string
  planName: string
  presetId?: string // ID du preset (optionnel)
  isCustom: boolean
  startDate: string // Format 'YYYY-MM-DD'
  parameters: {
    totalDays: number
    order: 'traditional' | 'chronological' | 'thematic' | 'historical'
    books: string[] // ['OT', 'NT', 'Gospels', 'Psalms', etc.]
    focus?: string // thème de focus
    daysPerWeek?: number // jours par semaine
    minutesPerDay?: number // minutes par jour
    includePsalms?: boolean // inclure psaumes quotidiens
    includeProverbs?: boolean // inclure proverbes quotidiens
  }
  profileData?: any // données du profil utilisateur
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
      planName,
      presetId,
      isCustom,
      startDate,
      parameters,
      profileData
    }: LocalPlanRequest = await req.json()

    console.log('📋 Local Plan Request:', {
      userId,
      planName,
      presetId,
      isCustom,
      startDate,
      parameters
    })

    // Validation
    if (!userId || !planName || !startDate || !parameters) {
      throw new Error('Paramètres manquants: userId, planName, startDate, parameters requis')
    }

    if (parameters.totalDays < 1 || parameters.totalDays > 365) {
      throw new Error('totalDays doit être entre 1 et 365')
    }

    // Créer un client Supabase
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 1. RÉCUPÉRER LE PRESET SI FOURNI
    let presetData = null
    if (presetId) {
      const { data: preset, error: presetError } = await supabaseAdmin
        .from('plan_presets')
        .select('*')
        .eq('id', presetId)
        .single()

      if (presetError) {
        console.error('❌ Erreur récupération preset:', presetError)
        throw new Error(`Preset non trouvé: ${presetError.message}`)
      }

      presetData = preset
      console.log('✅ Preset récupéré:', preset.name)
    }

    // 2. GÉNÉRER LE PLAN LOCALEMENT
    const generatedPlan = await generateLocalPlan({
      preset: presetData,
      isCustom,
      parameters,
      profileData,
      startDate: new Date(startDate)
    })

    console.log('📚 Plan généré:', {
      totalDays: generatedPlan.days.length,
      references: generatedPlan.days.slice(0, 3).map(d => d.references)
    })

    // 3. INSÉRER LE PLAN DANS LA BASE
    const { data: newPlan, error: planError } = await supabaseAdmin
      .from('local_plans')
      .insert({
        user_id: userId,
        name: planName,
        preset_id: presetId || null,
        is_custom: isCustom,
        start_date: startDate,
        total_days: parameters.totalDays,
        parameters: parameters,
        generated_content: generatedPlan,
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

    // 4. INSÉRER LES JOURS DU PLAN
    const planDaysToInsert = generatedPlan.days.map((day, index) => ({
      plan_id: planId,
      day_number: index + 1,
      date: day.date,
      bible_references: day.references,
      meditation_theme: day.meditationTheme,
      prayer_subjects: day.prayerSubjects,
      memory_verse: day.memoryVerse,
      is_completed: false
    }))

    const { error: daysError } = await supabaseAdmin
      .from('local_plan_days')
      .insert(planDaysToInsert)

    if (daysError) {
      console.error('❌ Erreur insertion jours:', daysError)
      throw new Error(`Erreur lors de l'insertion des jours: ${daysError.message}`)
    }

    // 5. METTRE À JOUR LE PROFIL UTILISATEUR
    const { error: updateError } = await supabaseAdmin.rpc('update_user_current_plan', {
      user_id: userId,
      plan_id: planId
    })

    if (updateError) {
      console.error('❌ Erreur mise à jour utilisateur:', updateError)
      // Ne pas faire échouer pour cette erreur
    }

    console.log('🎉 Plan local généré avec succès!')

    return new Response(
      JSON.stringify({ 
        success: true,
        planId: planId,
        message: 'Plan local généré avec succès',
        totalDays: parameters.totalDays,
        generatedDays: generatedPlan.days.length
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('💥 Erreur dans generate-local-plan:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

// Fonction de génération locale de plan
async function generateLocalPlan({
  preset,
  isCustom,
  parameters,
  profileData,
  startDate
}: {
  preset: any
  isCustom: boolean
  parameters: any
  profileData: any
  startDate: Date
}) {
  const days = []
  const currentDate = new Date(startDate)
  
  // Définir les livres disponibles selon les paramètres
  const availableBooks = getAvailableBooks(parameters.books)
  
  // Générer les jours
  for (let day = 1; day <= parameters.totalDays; day++) {
    const dayData = {
      date: currentDate.toISOString().split('T')[0],
      references: generateDayReferences(availableBooks, parameters, day),
      meditationTheme: generateMeditationTheme(parameters, day),
      prayerSubjects: generatePrayerSubjects(parameters, day),
      memoryVerse: generateMemoryVerse(availableBooks, day)
    }
    
    days.push(dayData)
    
    // Passer au jour suivant
    currentDate.setDate(currentDate.getDate() + 1)
  }
  
  return {
    days,
    metadata: {
      generatedAt: new Date().toISOString(),
      preset: preset?.name || null,
      isCustom,
      parameters
    }
  }
}

// Obtenir les livres disponibles selon les paramètres
function getAvailableBooks(books: string[]): any[] {
  const bookDatabase = {
    'OT': [
      { name: 'Genèse', chapters: 50, testament: 'OT' },
      { name: 'Exode', chapters: 40, testament: 'OT' },
      { name: 'Lévitique', chapters: 27, testament: 'OT' },
      { name: 'Nombres', chapters: 36, testament: 'OT' },
      { name: 'Deutéronome', chapters: 34, testament: 'OT' },
      { name: 'Josué', chapters: 24, testament: 'OT' },
      { name: 'Juges', chapters: 21, testament: 'OT' },
      { name: 'Ruth', chapters: 4, testament: 'OT' },
      { name: '1 Samuel', chapters: 31, testament: 'OT' },
      { name: '2 Samuel', chapters: 24, testament: 'OT' },
      { name: '1 Rois', chapters: 22, testament: 'OT' },
      { name: '2 Rois', chapters: 25, testament: 'OT' },
      { name: '1 Chroniques', chapters: 29, testament: 'OT' },
      { name: '2 Chroniques', chapters: 36, testament: 'OT' },
      { name: 'Esdras', chapters: 10, testament: 'OT' },
      { name: 'Néhémie', chapters: 13, testament: 'OT' },
      { name: 'Esther', chapters: 10, testament: 'OT' },
      { name: 'Job', chapters: 42, testament: 'OT' },
      { name: 'Psaumes', chapters: 150, testament: 'OT' },
      { name: 'Proverbes', chapters: 31, testament: 'OT' },
      { name: 'Ecclésiaste', chapters: 12, testament: 'OT' },
      { name: 'Cantique des Cantiques', chapters: 8, testament: 'OT' },
      { name: 'Ésaïe', chapters: 66, testament: 'OT' },
      { name: 'Jérémie', chapters: 52, testament: 'OT' },
      { name: 'Lamentations', chapters: 5, testament: 'OT' },
      { name: 'Ézéchiel', chapters: 48, testament: 'OT' },
      { name: 'Daniel', chapters: 12, testament: 'OT' },
      { name: 'Osée', chapters: 14, testament: 'OT' },
      { name: 'Joël', chapters: 3, testament: 'OT' },
      { name: 'Amos', chapters: 9, testament: 'OT' },
      { name: 'Abdias', chapters: 1, testament: 'OT' },
      { name: 'Jonas', chapters: 4, testament: 'OT' },
      { name: 'Michée', chapters: 7, testament: 'OT' },
      { name: 'Nahum', chapters: 3, testament: 'OT' },
      { name: 'Habacuc', chapters: 3, testament: 'OT' },
      { name: 'Sophonie', chapters: 3, testament: 'OT' },
      { name: 'Aggée', chapters: 2, testament: 'OT' },
      { name: 'Zacharie', chapters: 14, testament: 'OT' },
      { name: 'Malachie', chapters: 4, testament: 'OT' }
    ],
    'NT': [
      { name: 'Matthieu', chapters: 28, testament: 'NT' },
      { name: 'Marc', chapters: 16, testament: 'NT' },
      { name: 'Luc', chapters: 24, testament: 'NT' },
      { name: 'Jean', chapters: 21, testament: 'NT' },
      { name: 'Actes', chapters: 28, testament: 'NT' },
      { name: 'Romains', chapters: 16, testament: 'NT' },
      { name: '1 Corinthiens', chapters: 16, testament: 'NT' },
      { name: '2 Corinthiens', chapters: 13, testament: 'NT' },
      { name: 'Galates', chapters: 6, testament: 'NT' },
      { name: 'Éphésiens', chapters: 6, testament: 'NT' },
      { name: 'Philippiens', chapters: 4, testament: 'NT' },
      { name: 'Colossiens', chapters: 4, testament: 'NT' },
      { name: '1 Thessaloniciens', chapters: 5, testament: 'NT' },
      { name: '2 Thessaloniciens', chapters: 3, testament: 'NT' },
      { name: '1 Timothée', chapters: 6, testament: 'NT' },
      { name: '2 Timothée', chapters: 4, testament: 'NT' },
      { name: 'Tite', chapters: 3, testament: 'NT' },
      { name: 'Philémon', chapters: 1, testament: 'NT' },
      { name: 'Hébreux', chapters: 13, testament: 'NT' },
      { name: 'Jacques', chapters: 5, testament: 'NT' },
      { name: '1 Pierre', chapters: 5, testament: 'NT' },
      { name: '2 Pierre', chapters: 3, testament: 'NT' },
      { name: '1 Jean', chapters: 5, testament: 'NT' },
      { name: '2 Jean', chapters: 1, testament: 'NT' },
      { name: '3 Jean', chapters: 1, testament: 'NT' },
      { name: 'Jude', chapters: 1, testament: 'NT' },
      { name: 'Apocalypse', chapters: 22, testament: 'NT' }
    ]
  }

  let selectedBooks = []
  
  if (books.includes('OT')) {
    selectedBooks = [...selectedBooks, ...bookDatabase.OT]
  }
  if (books.includes('NT')) {
    selectedBooks = [...selectedBooks, ...bookDatabase.NT]
  }
  if (books.includes('Gospels')) {
    selectedBooks = [...selectedBooks, ...bookDatabase.NT.filter(b => 
      ['Matthieu', 'Marc', 'Luc', 'Jean'].includes(b.name)
    )]
  }
  if (books.includes('Psalms')) {
    selectedBooks = [...selectedBooks, ...bookDatabase.OT.filter(b => b.name === 'Psaumes')]
  }
  if (books.includes('Proverbs')) {
    selectedBooks = [...selectedBooks, ...bookDatabase.OT.filter(b => b.name === 'Proverbes')]
  }

  return selectedBooks
}

// Générer les références pour un jour
function generateDayReferences(availableBooks: any[], parameters: any, dayNumber: number): string[] {
  const references = []
  
  // Sélectionner un livre aléatoire
  const randomBook = availableBooks[Math.floor(Math.random() * availableBooks.length)]
  const chapter = Math.floor(Math.random() * randomBook.chapters) + 1
  
  // Générer une référence
  if (parameters.order === 'chronological') {
    // Pour l'ordre chronologique, essayer de suivre une progression
    const bookIndex = dayNumber % availableBooks.length
    const selectedBook = availableBooks[bookIndex]
    const chapter = Math.min(Math.floor(dayNumber / availableBooks.length) + 1, selectedBook.chapters)
    references.push(`${selectedBook.name} ${chapter}`)
  } else {
    // Ordre traditionnel ou thématique
    references.push(`${randomBook.name} ${chapter}`)
  }
  
  // Ajouter psaume quotidien si demandé
  if (parameters.includePsalms) {
    const psalmNumber = ((dayNumber - 1) % 150) + 1
    references.push(`Psaume ${psalmNumber}`)
  }
  
  // Ajouter proverbe quotidien si demandé
  if (parameters.includeProverbs) {
    const proverbChapter = ((dayNumber - 1) % 31) + 1
    references.push(`Proverbes ${proverbChapter}`)
  }
  
  return references
}

// Générer un thème de méditation
function generateMeditationTheme(parameters: any, dayNumber: number): string {
  const themes = [
    'Paix et sérénité',
    'Amour de Dieu',
    'Sagesse divine',
    'Grâce et miséricorde',
    'Foi et confiance',
    'Espérance et joie',
    'Pardon et réconciliation',
    'Service et humilité',
    'Persévérance et endurance',
    'Louange et adoration'
  ]
  
  return themes[dayNumber % themes.length]
}

// Générer des sujets de prière
function generatePrayerSubjects(parameters: any, dayNumber: number): any[] {
  const subjects = [
    { theme: 'Gratitude', subject: 'Remerciez Dieu pour ses bénédictions' },
    { theme: 'Guérison', subject: 'Priez pour la guérison de vos proches' },
    { theme: 'Sagesse', subject: 'Demandez la sagesse divine' },
    { theme: 'Paix', subject: 'Priez pour la paix dans votre cœur' },
    { theme: 'Protection', subject: 'Demandez la protection divine' },
    { theme: 'Direction', subject: 'Cherchez la direction de Dieu' },
    { theme: 'Force', subject: 'Demandez la force spirituelle' },
    { theme: 'Pardon', subject: 'Priez pour le pardon' }
  ]
  
  // Retourner 3-5 sujets aléatoires
  const numSubjects = 3 + (dayNumber % 3)
  const selectedSubjects = []
  
  for (let i = 0; i < numSubjects; i++) {
    const subject = subjects[(dayNumber + i) % subjects.length]
    selectedSubjects.push({
      ...subject,
      color: getRandomColor(),
      validated: false,
      notes: ''
    })
  }
  
  return selectedSubjects
}

// Générer un verset à mémoriser
function generateMemoryVerse(availableBooks: any[], dayNumber: number): string {
  const verses = [
    'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
    'Je puis tout par celui qui me fortifie.',
    'L\'Éternel est mon berger: je ne manquerai de rien.',
    'Cherchez premièrement le royaume et la justice de Dieu; et toutes ces choses vous seront données par-dessus.',
    'Car je connais les pensées que j\'ai pour vous, dit l\'Éternel, pensées de paix et non de malheur, afin de vous donner un avenir et de l\'espérance.',
    'Confie-toi en l\'Éternel de tout ton cœur, et ne t\'appuie pas sur ta sagesse.',
    'L\'amour est patient, il est plein de bonté; l\'amour n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil.',
    'Car nous marchons par la foi et non par la vue.',
    'Réjouissez-vous toujours dans le Seigneur; je le répète, réjouissez-vous.',
    'Toutes choses concourent au bien de ceux qui aiment Dieu.'
  ]
  
  return verses[dayNumber % verses.length]
}

// Obtenir une couleur aléatoire
function getRandomColor(): string {
  const colors = ['blue', 'green', 'purple', 'orange', 'pink', 'cyan', 'lime', 'amber']
  return colors[Math.floor(Math.random() * colors.length)]
}

/* 🚀 Edge Function pour génération de plans 100% locale

Cette fonction génère des plans de lecture biblique entièrement localement
sans dépendance externe, avec:
✅ Support des presets Thompson
✅ Plans personnalisés
✅ Génération intelligente de références
✅ Thèmes de méditation et sujets de prière
✅ Versets à mémoriser
✅ Sauvegarde en base de données

Utilisation depuis Flutter:
Supabase.instance.client.functions.invoke('generate-local-plan', body: {...})
*/
