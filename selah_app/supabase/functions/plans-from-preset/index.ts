import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, idempotency-key',
}

interface PresetRequest {
  preset_slug: string
  start_date: string
  profile: Record<string, any>
}

interface ReadingRef {
  book: string
  range: string
  url?: string
}

interface PlanDay {
  day_index: number
  date: string
  readings: ReadingRef[]
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { preset_slug, start_date, profile }: PresetRequest = await req.json()

    // Deactivate current active plan
    await supabaseClient
      .from('plans')
      .update({ is_active: false })
      .eq('user_id', user.id)
      .eq('is_active', true)

    // Generate plan based on preset and profile
    const planData = await generatePlanFromPreset(preset_slug, start_date, profile)

    // Create the plan
    const { data: plan, error: planError } = await supabaseClient
      .from('plans')
      .insert({
        user_id: user.id,
        name: planData.name,
        start_date: start_date,
        total_days: planData.days.length,
        is_active: true
      })
      .select()
      .single()

    if (planError) {
      throw new Error(`Failed to create plan: ${planError.message}`)
    }

    // Create plan days
    const planDays = planData.days.map((day: PlanDay) => ({
      plan_id: plan.id,
      day_index: day.day_index,
      date: day.date,
      readings: day.readings
    }))

    const { error: daysError } = await supabaseClient
      .from('plan_days')
      .insert(planDays)

    if (daysError) {
      throw new Error(`Failed to create plan days: ${daysError.message}`)
    }

    return new Response(
      JSON.stringify(plan),
      { 
        status: 201, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in plans-from-preset:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function generatePlanFromPreset(
  presetSlug: string, 
  startDate: string, 
  profile: Record<string, any>
): Promise<{ name: string; days: PlanDay[] }> {
  
  // Parse start date
  const start = new Date(startDate)
  
  // Get preset configuration
  const preset = getPresetConfig(presetSlug, profile)
  
  // Generate days
  const days: PlanDay[] = []
  let currentDate = new Date(start)
  
  for (let i = 1; i <= preset.totalDays; i++) {
    // Skip rest days if configured
    if (preset.restDays && preset.restDays.includes(currentDate.getDay())) {
      currentDate.setDate(currentDate.getDate() + 1)
      continue
    }
    
    // Generate readings for this day
    const readings = generateReadingsForDay(i, preset, profile)
    
    days.push({
      day_index: i,
      date: currentDate.toISOString().split('T')[0],
      readings
    })
    
    currentDate.setDate(currentDate.getDate() + 1)
  }
  
  return {
    name: preset.name,
    days
  }
}

function getPresetConfig(slug: string, profile: Record<string, any>) {
  const presets: Record<string, any> = {
    'thompson-compagnie': {
      name: 'Compagnie avec Dieu',
      totalDays: profile.minutesPerDay > 30 ? 90 : 60,
      books: ['Jean', '1 Jean', '2 Jean', '3 Jean'],
      restDays: profile.goals?.includes('weekend_rest') ? [0, 6] : null
    },
    'thompson-exigence': {
      name: 'Exigence Spirituelle',
      totalDays: profile.minutesPerDay > 30 ? 120 : 80,
      books: ['Matthieu', 'Marc', 'Luc', 'Jean'],
      restDays: null
    },
    'thompson-erreurs': {
      name: 'Erreurs Courantes',
      totalDays: profile.minutesPerDay > 30 ? 100 : 70,
      books: ['Romains', '1 Corinthiens', '2 Corinthiens', 'Galates'],
      restDays: profile.goals?.includes('weekend_rest') ? [0, 6] : null
    },
    'thompson-inquietude': {
      name: 'Inquiétude Interdite',
      totalDays: profile.minutesPerDay > 30 ? 75 : 50,
      books: ['Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens'],
      restDays: null
    },
    'thompson-liens': {
      name: 'Liens Conjugaux',
      totalDays: profile.minutesPerDay > 30 ? 60 : 40,
      books: ['Ephésiens', '1 Timothée', '2 Timothée', 'Tite'],
      restDays: profile.goals?.includes('weekend_rest') ? [0, 6] : null
    }
  }
  
  return presets[slug] || presets['thompson-compagnie']
}

function generateReadingsForDay(
  dayIndex: number, 
  preset: any, 
  profile: Record<string, any>
): ReadingRef[] {
  
  const readings: ReadingRef[] = []
  const minutesPerDay = profile.minutesPerDay || 15
  
  // Calculate how many chapters to read based on available time
  const chaptersPerDay = Math.max(1, Math.floor(minutesPerDay / 10))
  
  // Simple round-robin through books
  const bookIndex = (dayIndex - 1) % preset.books.length
  const book = preset.books[bookIndex]
  
  // Generate chapter ranges
  for (let i = 0; i < chaptersPerDay; i++) {
    const chapter = Math.floor((dayIndex - 1) / preset.books.length) + 1 + i
    
    readings.push({
      book,
      range: `${chapter}:1-${chapter}:50`, // Simplified range
      url: `https://www.biblegateway.com/passage/?search=${book}+${chapter}&version=LSG`
    })
  }
  
  return readings
}
