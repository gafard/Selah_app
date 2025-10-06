import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, idempotency-key',
}

interface ImportRequest {
  name: string
  ics_url: string
}

interface ICSReading {
  book: string
  range: string
  url?: string
}

interface ICSDay {
  day_index: number
  date: string
  readings: ICSReading[]
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
    const { name, ics_url }: ImportRequest = await req.json()

    // Deactivate current active plan
    await supabaseClient
      .from('plans')
      .update({ is_active: false })
      .eq('user_id', user.id)
      .eq('is_active', true)

    // Download and parse ICS file
    const icsData = await downloadAndParseICS(ics_url)
    
    if (!icsData || icsData.length === 0) {
      throw new Error('No valid readings found in ICS file')
    }

    // Create the plan
    const { data: plan, error: planError } = await supabaseClient
      .from('plans')
      .insert({
        user_id: user.id,
        name: name,
        start_date: icsData[0].date,
        total_days: icsData.length,
        is_active: true
      })
      .select()
      .single()

    if (planError) {
      throw new Error(`Failed to create plan: ${planError.message}`)
    }

    // Create plan days
    const planDays = icsData.map((day: ICSDay) => ({
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
    console.error('Error in plans-import:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function downloadAndParseICS(icsUrl: string): Promise<ICSDay[]> {
  try {
    // Download the ICS file
    const response = await fetch(icsUrl)
    if (!response.ok) {
      throw new Error(`Failed to download ICS: ${response.statusText}`)
    }
    
    const icsContent = await response.text()
    
    // Parse ICS content
    return parseICSContent(icsContent)
    
  } catch (error) {
    console.error('Error downloading/parsing ICS:', error)
    throw new Error(`Failed to process ICS file: ${error.message}`)
  }
}

function parseICSContent(icsContent: string): ICSDay[] {
  const days: ICSDay[] = []
  const lines = icsContent.split('\n')
  
  let currentEvent: any = {}
  let dayIndex = 1
  
  for (const line of lines) {
    const trimmedLine = line.trim()
    
    if (trimmedLine === 'BEGIN:VEVENT') {
      currentEvent = {}
    } else if (trimmedLine === 'END:VEVENT') {
      if (currentEvent.summary && currentEvent.dtstart) {
        const readings = parseReadingFromSummary(currentEvent.summary)
        if (readings.length > 0) {
          days.push({
            day_index: dayIndex++,
            date: formatDateFromICS(currentEvent.dtstart),
            readings
          })
        }
      }
    } else if (trimmedLine.startsWith('SUMMARY:')) {
      currentEvent.summary = trimmedLine.substring(8)
    } else if (trimmedLine.startsWith('DTSTART:')) {
      currentEvent.dtstart = trimmedLine.substring(8)
    }
  }
  
  return days
}

function parseReadingFromSummary(summary: string): ICSReading[] {
  const readings: ICSReading[] = []
  
  // Simple parsing - look for book names and chapter references
  // This is a simplified parser - in production you'd want more robust parsing
  
  // Common book patterns
  const bookPatterns = [
    /(Jean|Matthieu|Marc|Luc|Actes|Romains|1\s+Corinthiens|2\s+Corinthiens|Galates|Ephésiens|Philippiens|Colossiens|1\s+Thessaloniciens|2\s+Thessaloniciens|1\s+Timothée|2\s+Timothée|Tite|Philémon|Hébreux|Jacques|1\s+Pierre|2\s+Pierre|1\s+Jean|2\s+Jean|3\s+Jean|Jude|Apocalypse)/gi
  ]
  
  for (const pattern of bookPatterns) {
    const matches = summary.match(pattern)
    if (matches) {
      for (const match of matches) {
        // Extract chapter/verse info
        const chapterMatch = summary.match(new RegExp(`${match}\\s+(\\d+)`, 'i'))
        if (chapterMatch) {
          const chapter = chapterMatch[1]
          readings.push({
            book: match.trim(),
            range: `${chapter}:1-${chapter}:50`,
            url: `https://www.biblegateway.com/passage/?search=${encodeURIComponent(match.trim())}+${chapter}&version=LSG`
          })
        }
      }
    }
  }
  
  // If no specific readings found, create a generic one
  if (readings.length === 0) {
    readings.push({
      book: 'Lecture du jour',
      range: '1:1-50',
      url: 'https://www.biblegateway.com/'
    })
  }
  
  return readings
}

function formatDateFromICS(dtstart: string): string {
  // ICS dates are typically in format YYYYMMDD or YYYYMMDDTHHMMSSZ
  // Convert to ISO date format
  
  if (dtstart.length >= 8) {
    const year = dtstart.substring(0, 4)
    const month = dtstart.substring(4, 6)
    const day = dtstart.substring(6, 8)
    return `${year}-${month}-${day}`
  }
  
  // Fallback to current date
  return new Date().toISOString().split('T')[0]
}
