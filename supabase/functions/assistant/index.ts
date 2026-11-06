// Edge Function assistant · la IA solo interpreta lenguaje (fase 3 del rework).
//   { mode: 'parse', text, now }      → tarea { title, scheduled_at, … } (sanitize.ts)
//   { mode: 'breakdown', title }      → { steps: [3–7 pasos] }
// Fechas, huecos y repartos los deciden las reglas de la app, no la IA.
// Secrets: GEMINI_API_KEY y GEMINI_MODEL (capa gratis, sin facturación).
// Antes de llamar a Gemini se cuenta la llamada con consume_ai_call() (033):
// falla si el usuario no activó la IA o pasó el tope diario.
// Solo se envía el texto que escribió el usuario o el título de la tarea.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { sanitizeParse, sanitizeSteps } from './sanitize.ts';

const PARSE = [
  'Convierte una nota corta en español en una tarea de agenda.',
  'Responde solo JSON con: kind ("task" o "note" si no es algo por hacer),',
  'title (corto, sin fecha ni hora), scheduled_at (ISO 8601 con el mismo desfase',
  'horario que "now", o null si no dice hora), due_date (ISO 8601 o null),',
  'estimated_minutes (entero o null), reminder_minutes (entero o null),',
  'repeat_rule ("daily", "weekdays", "weekly:<días 0=domingo..6 separados por coma>",',
  '"monthly:<día>" o null) y priority ("low", "medium" o "high").',
  'Interpreta "mañana", días de la semana y "en N minutos" desde "now". No inventes datos.',
].join(' ');

const BREAKDOWN = [
  'Divide la tarea en 3 a 7 pasos concretos, en orden, que se puedan hacer en',
  'menos de una hora cada uno. Responde solo JSON: {"steps": ["..."]}.',
  'Pasos cortos en español, en infinitivo, sin numerar y sin emojis.',
].join(' ');

async function gemini(system: string, prompt: string): Promise<unknown> {
  const model = Deno.env.get('GEMINI_MODEL');
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': Deno.env.get('GEMINI_API_KEY') ?? '',
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        // Sin maxOutputTokens: los modelos que "piensan" lo gastan y no dejan texto.
        generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
      }),
      signal: AbortSignal.timeout(25_000),
    },
  );
  if (!res.ok) {
    console.error('gemini', res.status, await res.text());
    throw new Error(`gemini_${res.status}`);
  }
  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== 'string') throw new Error('gemini_sin_texto');
  return JSON.parse(text);
}

// Flutter web llama desde el navegador: sin estas cabeceras lo bloquea (CORS).
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'content-type': 'application/json' },
  });

if (import.meta.main) {
  Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
    const body = await req.json().catch(() => ({}));
    const mode = body?.mode;
    const input = typeof body?.text === 'string' ? body.text.trim().slice(0, 500)
      : typeof body?.title === 'string' ? body.title.trim().slice(0, 200)
      : '';
    if ((mode !== 'parse' && mode !== 'breakdown') || !input) {
      return json({ error: 'invalid_request' }, 400);
    }
    const now = new Date(typeof body.now === 'string' ? body.now : Date.now());
    if (Number.isNaN(now.getTime())) return json({ error: 'invalid_request' }, 400);

    // Cliente con el JWT del usuario: consume_ai_call usa su auth.uid().
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    );
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) return json({ error: 'not_authenticated' }, 401);
    const { error: quota } = await supabase.rpc('consume_ai_call');
    if (quota) return json({ error: quota.message }, 429);

    try {
      if (mode === 'parse') {
        const raw = await gemini(PARSE, JSON.stringify({ now: body.now, text: input }));
        return json(sanitizeParse(raw, input, now));
      }
      const steps = sanitizeSteps(await gemini(BREAKDOWN, input));
      return steps ? json({ steps }) : json({ error: 'sin_pasos' }, 502);
    } catch (e) {
      // La app cae al parser local; la llamada ya contó en el tope.
      console.error('assistant', e);
      return json({ error: e instanceof Error ? e.message : 'gemini_error' }, 502);
    }
  });
}
