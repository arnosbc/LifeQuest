// Edge Function npc-mission · RPGenie sugiere la misión de un NPC con Gemini.
// Solo redacta texto: el cobro, el cooldown y la tarea siguen en
// accept_npc_mission (019, 031). Secrets: GEMINI_API_KEY y GEMINI_MODEL.
// Si el NPC tiene documentos de contexto (032, resumidos por npc-context), la
// misión sale de sus temas, en su orden.
//
// Devuelve el título y una guía (objetivo, pasos o ejercicios concretos y
// pistas) para que alguien que no domina el tema sepa por dónde empezar.
//
// shortcut: sin límite por usuario; el cupo gratis de Gemini es compartido.
// Añadir un contador por usuario si el cupo se agota.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SYSTEM = [
  'Eres RPGenie, el asistente de una app de productividad con estilo RPG.',
  'Un NPC le pide al jugador una misión real. La «noble misión» del NPC es el TEMA:',
  'la misión debe practicar o estudiar ese tema de forma concreta',
  '(p. ej. tema «fundamentos de diseño gráfico» → «Diseña 3 composiciones aplicando la regla de tercios»).',
  'No repitas las misiones anteriores; avanza poco a poco dentro del tema.',
  'Si recibes documentos de contexto (p. ej. el plan de la asignatura), la misión debe salir',
  'de uno de sus temas: sigue el orden del documento, elige el primer tema que las misiones',
  'anteriores aún no cubran y nómbralo en el objetivo.',
  'Supón que el jugador es principiante en el tema: la misión debe poder hacerse hoy',
  'sin conocer el tema de antemano.',
  'Todo en español, en tono de invitación, sin emojis.',
  'Devuelve:',
  '- title: la misión en 15 palabras como máximo, sin comillas.',
  '- objective: 1 o 2 frases con qué aprenderá y por qué le sirve.',
  '- steps: de 2 a 5 pasos concretos. Si el tema se practica con ejercicios',
  '(matemáticas, programación, idiomas…), escribe los ejercicios completos con sus datos',
  '(p. ej. el sistema de ecuaciones exacto a resolver), no solo «resuelve un ejercicio».',
  '- hints: de 2 a 4 ayudas: el concepto clave explicado en simple, cómo empezar',
  'y un error común. No des la solución completa de los ejercicios.',
  '- search: 1 o 2 términos de búsqueda para aprender más (sin enlaces ni URLs).',
].join(' ');

/// Formato de salida que se pide a Gemini (JSON estructurado).
const SCHEMA = {
  type: 'OBJECT',
  properties: {
    title: { type: 'STRING' },
    objective: { type: 'STRING' },
    steps: { type: 'ARRAY', items: { type: 'STRING' } },
    hints: { type: 'ARRAY', items: { type: 'STRING' } },
    search: { type: 'ARRAY', items: { type: 'STRING' } },
  },
  required: ['title', 'objective', 'steps', 'hints'],
};

/// Límites de accept_npc_mission (031).
const TITLE_MAX = 200;
const GUIDE_MAX = 4000;

const BULLET = /^(?:[-*•]|\d+[.)])\s*/;

/// Primera línea, sin comillas ni viñetas, en el límite de accept_npc_mission.
export function cleanTitle(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const line = raw.trim().split('\n')[0]
    .replace(BULLET, '')
    .replace(/^["'«“]+|["'»”.]+$/g, '')
    .trim();
  return line ? line.slice(0, TITLE_MAX) : null;
}

/// En pasos y pistas la viñeta exige espacio: «-3x + y = 2» conserva su signo.
const texts = (value: unknown, max: number): string[] =>
  (Array.isArray(value) ? value : [])
    .filter((v): v is string => typeof v === 'string')
    .map((v) => v.trim().replace(/^(?:[-*•]|\d+[.)])\s+/, ''))
    .filter(Boolean)
    .slice(0, max);

/// Guía en texto plano para `tasks.description`; null si no trae nada útil.
export function formatGuide(raw: Record<string, unknown>): string | null {
  const objective = typeof raw.objective === 'string' ? raw.objective.trim() : '';
  const steps = texts(raw.steps, 5);
  const hints = texts(raw.hints, 4);
  const search = texts(raw.search, 2);
  const parts = [
    objective && `Objetivo: ${objective}`,
    steps.length && `Pasos:\n${steps.map((s, i) => `${i + 1}. ${s}`).join('\n')}`,
    hints.length && `Pistas:\n${hints.map((h) => `• ${h}`).join('\n')}`,
    search.length && `Para aprender más, busca: ${search.join(' · ')}`,
  ].filter(Boolean);
  return parts.length ? parts.join('\n\n').slice(0, GUIDE_MAX) : null;
}

/// Título y guía desde la respuesta de Gemini. Si no llega JSON válido, la
/// primera línea del texto sirve de título y la misión va sin guía.
export function parseSuggestion(text: unknown): { title: string | null; guide: string | null } {
  if (typeof text !== 'string') return { title: null, guide: null };
  try {
    const raw = JSON.parse(text);
    if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
      return { title: cleanTitle(raw.title), guide: formatGuide(raw) };
    }
  } catch {
    // Texto libre: se usa como título.
  }
  return { title: cleanTitle(text), guide: null };
}

type Npc = {
  name: string;
  noble_mission: string | null;
  frequency: string;
  skills: { name: string } | null;
};

type ContextDoc = { title: string; ai_summary: string | null };

/// Texto que recibe la IA. Solo datos del NPC y el resumen de sus documentos
/// (sin datos personales): en la capa gratis Google puede usarlo para entrenar.
export function buildPrompt(npc: Npc, previous: string[], docs: ContextDoc[] = []): string {
  return [
    `Tema (noble misión): ${npc.noble_mission ?? npc.skills?.name ?? 'general'}`,
    `Skill: ${npc.skills?.name ?? 'general'}`,
    `NPC: ${npc.name} · visita ${npc.frequency}`,
    ...docs
      .filter((d) => d.ai_summary)
      .map((d) => `Documento de contexto «${d.title}» (resumen):\n${d.ai_summary}`),
    previous.length ? `Misiones anteriores:\n- ${previous.join('\n- ')}` : '',
  ].filter(Boolean).join('\n');
}

/// `reason` (p. ej. `gemini_429`) llega al aviso de la app cuando no hay título.
async function suggest(
  npc: Npc,
  previous: string[],
  docs: ContextDoc[],
): Promise<{ title: string | null; guide?: string | null; reason?: string }> {
  const prompt = buildPrompt(npc, previous, docs);
  const model = Deno.env.get('GEMINI_MODEL');
  const started = Date.now();
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': Deno.env.get('GEMINI_API_KEY') ?? '',
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        // Sin maxOutputTokens: los modelos que "piensan" lo gastan y no dejan texto.
        // Gemini 3 usa thinkingLevel (ya no thinkingBudget). "low" lo aceptan
        // 3.5 Flash-Lite, 3.6 y 3.8 Flash; "minimal" (más rápido) solo los dos
        // primeros: se elige con el secret opcional GEMINI_THINKING_LEVEL.
        generationConfig: {
          temperature: 0.9,
          thinkingConfig: { thinkingLevel: Deno.env.get('GEMINI_THINKING_LEVEL') || 'low' },
          responseMimeType: 'application/json',
          responseSchema: SCHEMA,
        },
      }),
      // La guía es larga; pasado este tiempo se avisa y no se cobra nada.
      signal: AbortSignal.timeout(45_000),
    },
  );
  console.log('gemini', model, res.status, `${Date.now() - started} ms`);
  if (!res.ok) {
    console.error('gemini', res.status, await res.text());
    return { title: null, reason: `gemini_${res.status}` };
  }
  const data = await res.json();
  const { title, guide } = parseSuggestion(data?.candidates?.[0]?.content?.parts?.[0]?.text);
  if (title) return { title, guide };
  console.error('gemini sin texto', JSON.stringify(data).slice(0, 500));
  return { title: null, reason: `sin_texto_${data?.candidates?.[0]?.finishReason ?? 'vacio'}` };
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
    const { npc_id } = await req.json().catch(() => ({}));
    if (typeof npc_id !== 'string') return json({ error: 'invalid_npc' }, 400);

    // Cliente con el JWT del usuario: el RLS solo deja ver sus propios NPC.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    );
    // Sesión obligatoria aunque se apague "Enforce JWT" en el panel.
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) return json({ error: 'not_authenticated' }, 401);
    const { data: npc } = await supabase
      .from('npcs')
      .select('name, noble_mission, frequency, skills(name)')
      .eq('id', npc_id)
      .maybeSingle();
    if (!npc) return json({ error: 'npc_not_found' }, 404);
    // Últimas misiones del NPC para que la IA no las repita.
    const { data: tasks } = await supabase
      .from('tasks')
      .select('title')
      .eq('npc_id', npc_id)
      .order('created_at', { ascending: false })
      .limit(5);
    // Resúmenes de sus documentos de contexto (032).
    const { data: docs } = await supabase
      .from('resources')
      .select('title, ai_summary')
      .eq('npc_id', npc_id)
      .is('archived_at', null)
      .order('created_at');

    // Si Gemini falla o se agota el cupo, el usuario escribe la misión como antes.
    const result = await suggest(npc, (tasks ?? []).map((t) => t.title), docs ?? []).catch((e) => {
      console.error('gemini', Deno.env.get('GEMINI_MODEL'), e);
      const timedOut = e instanceof DOMException && e.name === 'TimeoutError';
      return { title: null, reason: timedOut ? 'gemini_timeout' : 'gemini_sin_conexion' };
    });
    return json(result);
  });
}
