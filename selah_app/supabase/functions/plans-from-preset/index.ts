import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PlanPresetRequest {
  presetSlug: string
  startDate: string
  profile: {
    level?: string
    goal?: string
    minutesPerDay?: number
    totalDays?: number
    [key: string]: any
  }
}

interface PlanTask {
  task_type: string
  title: string
  description?: string
  book?: string
  chapter_start?: number
  chapter_end?: number
  verse_start?: number
  verse_end?: number
  estimated_minutes: number
  order_index: number
}

interface PlanDay {
  day_number: number
  date: string
  tasks: PlanTask[]
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the current user
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse request body
    const { presetSlug, startDate, profile }: PlanPresetRequest = await req.json()

    if (!presetSlug || !startDate) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: presetSlug, startDate' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Generate plan based on preset
    const planData = await generatePlanFromPreset(presetSlug, startDate, profile)

    // Create the plan in database
    const { data: plan, error: planError } = await supabaseClient
      .from('plans')
      .insert({
        user_id: user.id,
        title: planData.title,
        description: planData.description,
        duration_days: planData.duration_days,
        start_date: startDate,
        is_active: true,
        metadata: {
          preset_slug: presetSlug,
          profile: profile,
          generated_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (planError) {
      console.error('Error creating plan:', planError)
      return new Response(
        JSON.stringify({ error: 'Failed to create plan', details: planError.message }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Deactivate other plans for this user
    await supabaseClient
      .from('plans')
      .update({ is_active: false })
      .eq('user_id', user.id)
      .neq('id', plan.id)

    // Create plan days and tasks
    const planDays = []
    for (const dayData of planData.days) {
      // Create plan day
      const { data: planDay, error: dayError } = await supabaseClient
        .from('plan_days')
        .insert({
          plan_id: plan.id,
          day_number: dayData.day_number,
          date: dayData.date,
          is_completed: false
        })
        .select()
        .single()

      if (dayError) {
        console.error('Error creating plan day:', dayError)
        continue
      }

      // Create tasks for this day
      const tasks = []
      for (let i = 0; i < dayData.tasks.length; i++) {
        const taskData = dayData.tasks[i]
        const { data: task, error: taskError } = await supabaseClient
          .from('plan_tasks')
          .insert({
            plan_day_id: planDay.id,
            task_type: taskData.task_type,
            title: taskData.title,
            description: taskData.description,
            book: taskData.book,
            chapter_start: taskData.chapter_start,
            chapter_end: taskData.chapter_end,
            verse_start: taskData.verse_start,
            verse_end: taskData.verse_end,
            estimated_minutes: taskData.estimated_minutes,
            order_index: taskData.order_index,
            is_completed: false
          })
          .select()
          .single()

        if (taskError) {
          console.error('Error creating task:', taskError)
        } else {
          tasks.push(task)
        }
      }

      planDays.push({
        ...planDay,
        tasks
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        plan: {
          ...plan,
          days: planDays
        }
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Function to generate plan data based on preset
async function generatePlanFromPreset(presetSlug: string, startDate: string, profile: any) {
  const start = new Date(startDate)
  
  // Parse preset slug to extract theme and ID
  const [theme, id] = presetSlug.split(':')
  
  // Default plan configuration
  let title = 'Plan de lecture personnalisé'
  let description = 'Un plan de lecture adapté à vos besoins'
  let durationDays = profile.totalDays || 21
  let minutesPerDay = profile.minutesPerDay || 30
  
  // Generate plan based on theme
  switch (theme) {
    case 'thompson':
      title = generateThompsonTitle(profile)
      description = generateThompsonDescription(profile)
      break
    case 'api':
      title = generateApiTitle(profile)
      description = generateApiDescription(profile)
      break
    default:
      title = 'Plan de lecture biblique'
      description = 'Un parcours spirituel personnalisé'
  }
  
  // Generate days and tasks
  const days = []
  for (let i = 0; i < durationDays; i++) {
    const currentDate = new Date(start)
    currentDate.setDate(start.getDate() + i)
    
    const dayNumber = i + 1
    const tasks = generateTasksForDay(dayNumber, theme, profile)
    
    days.push({
      day_number: dayNumber,
      date: currentDate.toISOString().split('T')[0],
      tasks
    })
  }
  
  return {
    title,
    description,
    duration_days: durationDays,
    days
  }
}

function generateThompsonTitle(profile: any): string {
  const themes = {
    'spiritual_demand': 'Exigence spirituelle — Transformation profonde',
    'no_worry': 'Ne vous inquiétez pas — Apprentissages de Mt 6',
    'companionship': 'Cheminer en couple selon la Parole',
    'prayer_life': 'Vie de prière — Souffle spirituel',
    'forgiveness': 'Pardon & réconciliation — Cœur libéré'
  }
  
  return themes[profile.goal] || 'Plan Thompson personnalisé'
}

function generateThompsonDescription(profile: any): string {
  return `Un parcours spirituel basé sur la Thompson Study Bible, adapté à votre niveau ${profile.level || 'intermédiaire'}.`
}

function generateApiTitle(profile: any): string {
  return `Plan de lecture ${profile.goal || 'général'}`
}

function generateApiDescription(profile: any): string {
  return `Un plan de lecture biblique généré automatiquement selon vos préférences.`
}

function generateTasksForDay(dayNumber: number, theme: string, profile: any): PlanTask[] {
  const tasks: PlanTask[] = []
  
  // Reading task
  tasks.push({
    task_type: 'reading',
    title: `Lecture du jour ${dayNumber}`,
    description: `Lecture biblique recommandée`,
    book: getBookForDay(dayNumber, theme),
    chapter_start: getChapterForDay(dayNumber),
    estimated_minutes: Math.floor((profile.minutesPerDay || 30) * 0.6),
    order_index: 0
  })
  
  // Meditation task
  tasks.push({
    task_type: 'meditation',
    title: `Méditation ${dayNumber}`,
    description: `Prenez un moment pour méditer sur le passage lu`,
    estimated_minutes: Math.floor((profile.minutesPerDay || 30) * 0.3),
    order_index: 1
  })
  
  // Prayer task
  tasks.push({
    task_type: 'prayer',
    title: `Prière ${dayNumber}`,
    description: `Temps de prière personnelle`,
    estimated_minutes: Math.floor((profile.minutesPerDay || 30) * 0.1),
    order_index: 2
  })
  
  return tasks
}

function getBookForDay(dayNumber: number, theme: string): string {
  const books = ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens']
  return books[dayNumber % books.length]
}

function getChapterForDay(dayNumber: number): number {
  return (dayNumber % 28) + 1
}