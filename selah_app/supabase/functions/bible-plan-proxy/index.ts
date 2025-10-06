import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

console.log('bible-plan-proxy function started');

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 405,
    });
  }

  try {
    const url = new URL(req.url);
    const searchParams = url.searchParams;
    
    // Extraire les paramètres de l'URL
    const start = searchParams.get('start');
    const total = searchParams.get('total');
    const format = searchParams.get('format') || 'calendar';
    const order = searchParams.get('order') || 'traditional';
    const daysofweek = searchParams.get('daysofweek') || '1,2,3,4,5,6,7';
    const books = searchParams.get('books') || 'OT,NT';
    const lang = searchParams.get('lang') || 'fr';
    const logic = searchParams.get('logic') || 'words';
    const checkbox = searchParams.get('checkbox') || '1';
    const colors = searchParams.get('colors') || '0';
    const dailypsalm = searchParams.get('dailypsalm') || '0';
    const dailyproverb = searchParams.get('dailyproverb') || '0';
    const otntoverlap = searchParams.get('otntoverlap') || '0';
    const reverse = searchParams.get('reverse') || '0';
    const stats = searchParams.get('stats') || '0';
    const dailystats = searchParams.get('dailystats') || '0';
    const nodates = searchParams.get('nodates') || '0';
    const includeurls = searchParams.get('includeurls') || '1';
    const urlsite = searchParams.get('urlsite') || 'biblegateway';
    const urlversion = searchParams.get('urlversion') || 'LSG';

    console.log('📋 Paramètres reçus:', {
      start, total, format, order, daysofweek, books, lang, logic, checkbox,
      colors, dailypsalm, dailyproverb, otntoverlap, reverse, stats, dailystats,
      nodates, includeurls, urlsite, urlversion
    });

    // Construire l'URL de l'API biblereadingplangenerator.com
    const apiUrl = new URL('https://www.biblereadingplangenerator.com/');
    apiUrl.searchParams.set('start', start || '');
    apiUrl.searchParams.set('total', total || '');
    apiUrl.searchParams.set('format', format);
    apiUrl.searchParams.set('order', order);
    apiUrl.searchParams.set('daysofweek', daysofweek);
    apiUrl.searchParams.set('books', books);
    apiUrl.searchParams.set('lang', lang);
    apiUrl.searchParams.set('logic', logic);
    apiUrl.searchParams.set('checkbox', checkbox);
    apiUrl.searchParams.set('colors', colors);
    apiUrl.searchParams.set('dailypsalm', dailypsalm);
    apiUrl.searchParams.set('dailyproverb', dailyproverb);
    apiUrl.searchParams.set('otntoverlap', otntoverlap);
    apiUrl.searchParams.set('reverse', reverse);
    apiUrl.searchParams.set('stats', stats);
    apiUrl.searchParams.set('dailystats', dailystats);
    apiUrl.searchParams.set('nodates', nodates);
    apiUrl.searchParams.set('includeurls', includeurls);
    apiUrl.searchParams.set('urlsite', urlsite);
    apiUrl.searchParams.set('urlversion', urlversion);

    console.log('🌐 URL API construite:', apiUrl.toString());

    // Appeler l'API biblereadingplangenerator.com
    const response = await fetch(apiUrl.toString(), {
      method: 'GET',
      headers: {
        'User-Agent': 'Selah-App/1.0',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    });

    if (!response.ok) {
      console.error('❌ Erreur API:', response.status, response.statusText);
      return new Response(JSON.stringify({ 
        error: `Erreur HTTP ${response.status}: ${response.statusText}` 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status,
      });
    }

    const htmlContent = await response.text();
    console.log('✅ Plan généré avec succès (', htmlContent.length, 'caractères)');

    // Retourner le contenu HTML
    return new Response(htmlContent, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/html; charset=utf-8',
      },
      status: 200,
    });

  } catch (error) {
    console.error('❌ Erreur inattendue:', error.message);
    return new Response(JSON.stringify({ 
      error: error.message 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
