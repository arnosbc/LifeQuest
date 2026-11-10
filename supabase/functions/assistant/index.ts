// Edge Function assistant · la IA solo interpreta lenguaje (fase 3 del rework).
//   { mode: 'parse', text, now }      → tarea { title, scheduled_at, … } (sanitize.ts)
//   { mode: 'breakdown', title }      → { steps: [3–7 pasos] }
//   { mode: 'goal', text }            → meta S.M.A.R.T. { title, specific, …, steps }
//   { mode: 'recall', title, notes }  → { questions: [1–3 preguntas de repaso] }
// breakdown y goal aceptan paths (máx. 3 fotos o PDF en el bucket `resources`,
// 045) y context (notas y enlaces en texto) que el usuario adjuntó.
// Fechas, huecos y repartos los deciden las reglas de la app, no la IA.
// Secrets: GEMINI_API_KEY y GEMINI_MODEL (capa gratis, sin facturación).
// Antes de llamar a Gemini se cuenta la llamada con consume_ai_call() (033):
// falla si el usuario no activó la IA o pasó el tope diario.
// Solo se envía el texto, el título y los recursos que el usuario eligió.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import { encodeBase64 } from 'jsr:@std/encoding@1/base64';

import { sanitizeGoal, sanitizeParse, sanitizeQuestions, sanitizeSteps } from './sanitize.ts';

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

const GOAL = [
  'Convierte la idea del usuario en una meta S.M.A.R.T. de semanas o meses.',
  'Responde solo JSON con: title (corto), specific (qué se logra exactamente),',
  'measurable (cómo se mide), achievable (por qué es realista), relevant (para',
  'qué le importa) y steps (3 a 7 tareas concretas, en orden, en infinitivo).',
  'Todo en español, una línea por campo, sin emojis. No inventes datos personales.',
].join(' ');

const RECALL = [
  'Eres un tutor. Con el título de la tarea y las notas del usuario sobre lo',
  'que hizo, escribe 1 a 3 preguntas cortas de repaso para que compruebe si lo',
  'entendió o recuerda dónde quedó. Responde solo JSON: {"questions": ["..."]}.',
  'En español, una línea cada una, sin emojis. Solo sobre lo que dicen las notas.',
].join(' ');

type Part = { text: string } | { inline_data: { mime_type: string; data: string } };
const MIME: Record<string, string> = {
  jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', pdf: 'application/pdf',
};
// Gemini acepta hasta 20 MB por petición con inline_data.
const MAX_INLINE = 15 * 1024 * 1024;

const strings = (v: unknown, max: number, len: number): string[] =>
  (Array.isArray(v) ? v : [])
    .filter((x): x is string => typeof x === 'string' && x.trim() !== '')
    .slice(0, max).map((x) => x.trim().slice(0, len));

/// Recursos que el usuario eligió como partes de Gemini: [paths] son fotos o
/// PDF ya subidos a su carpeta del bucket `resources` (045); [context], notas
/// y enlaces en texto. Descarga con su JWT: las políticas del bucket impiden
/// leer lo de otro. Lo que falla se salta.
async function resourceParts(
  supabase: SupabaseClient, uid: string, paths: unknown, context: unknown,
): Promise<Part[]> {
  const parts: Part[] = strings(context, 5, 500).map((text) => ({ text: `Contexto: ${text}` }));
  let bytes = 0;
  for (const path of strings(paths, 3, 200)) {
    const mime = MIME[path.split('.').pop()?.toLowerCase() ?? ''];
    if (!mime || !path.startsWith(`${uid}/`)) continue;
    const { data: file } = await supabase.storage.from('resources').download(path);
    if (!file || bytes + file.size > MAX_INLINE) continue;
    bytes += file.size;
    parts.push({ inline_data: { mime_type: mime, data: encodeBase64(await file.arrayBuffer()) } });
  }
  if (parts.length) parts.unshift({ text: 'Material del usuario para esta tarea:' });
  return parts;
}

async function gemini(system: string, prompt: string, extra: Part[] = []): Promise<unknown> {
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
        contents: [{ role: 'user', parts: [...extra, { text: prompt }] }],
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
    if (!['parse', 'breakdown', 'goal', 'recall'].includes(mode) || !input) {
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
      if (mode === 'recall') {
        const notes = (Array.isArray(body.notes) ? body.notes : [])
          .filter((n: unknown) => typeof n === 'string' && n.trim())
          .slice(0, 10).map((n: string) => n.trim().slice(0, 300));
        if (!notes.length) return json({ error: 'invalid_request' }, 400);
        const questions = sanitizeQuestions(await gemini(RECALL, JSON.stringify({ title: input, notes })));
        return questions ? json({ questions }) : json({ error: 'sin_preguntas' }, 502);
      }
      const extra = await resourceParts(supabase, auth.user.id, body.paths, body.context);
      if (mode === 'goal') {
        const goal = sanitizeGoal(await gemini(GOAL, input, extra), input);
        return goal ? json(goal) : json({ error: 'sin_pasos' }, 502);
      }
      const steps = sanitizeSteps(await gemini(BREAKDOWN, input, extra));
      return steps ? json({ steps }) : json({ error: 'sin_pasos' }, 502);
    } catch (e) {
      // La app cae al parser local; la llamada ya contó en el tope.
      console.error('assistant', e);
      return json({ error: e instanceof Error ? e.message : 'gemini_error' }, 502);
    }
  });
}
