import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ImportRequest {
  icsUrl: string
  startDate: string
  profile: any
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { icsUrl, startDate, profile }: ImportRequest = await req.json()

    if (!icsUrl || !startDate) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: icsUrl, startDate' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch ICS data
    const icsResponse = await fetch(icsUrl)
    if (!icsResponse.ok) {
      return new Response(
        JSON.stringify({ error: 'Failed to fetch ICS data' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const icsData = await icsResponse.text()
    const planData = parseICSData(icsData, startDate, profile)

    // Create the plan
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
          ics_url: icsUrl,
          profile: profile,
          imported_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (planError) {
      return new Response(
        JSON.stringify({ error: 'Failed to create plan', details: planError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Deactivate other plans
    await supabaseClient
      .from('plans')
      .update({ is_active: false })
      .eq('user_id', user.id)
      .neq('id', plan.id)

    // Create plan days and tasks
    const planDays = []
    for (const dayData of planData.days) {
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

      if (dayError) continue

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

        if (!taskError) {
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
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function parseICSData(icsData: string, startDate: string, profile: any) {
  // Simple ICS parser - in a real implementation, you'd use a proper ICS library
  const lines = icsData.split('\n')
  const events = []
  
  let currentEvent = {}
  for (const line of lines) {
    if (line.startsWith('BEGIN:VEVENT')) {
      currentEvent = {}
    } else if (line.startsWith('END:VEVENT')) {
      events.push(currentEvent)
    } else if (line.startsWith('SUMMARY:')) {
      currentEvent.summary = line.substring(8)
    } else if (line.startsWith('DESCRIPTION:')) {
      currentEvent.description = line.substring(12)
    }
  }

  const start = new Date(startDate)
  const days = []
  
  for (let i = 0; i < events.length; i++) {
    const event = events[i]
    const currentDate = new Date(start)
    currentDate.setDate(start.getDate() + i)
    
    days.push({
      day_number: i + 1,
      date: currentDate.toISOString().split('T')[0],
      tasks: [{
        task_type: 'reading',
        title: event.summary || `Lecture du jour ${i + 1}`,
        description: event.description || 'Lecture biblique',
        estimated_minutes: profile.minutesPerDay || 30,
        order_index: 0
      }]
    })
  }

  return {
    title: 'Plan importé',
    description: 'Plan de lecture importé depuis un fichier ICS',
    duration_days: events.length,
    days
  }
}