// Edge Function npc-mission · RPGenie sugiere la misión de un NPC con Gemini.
// Solo redacta texto: el cobro, el cooldown y la tarea siguen en
// accept_npc_mission (019). Secrets: GEMINI_API_KEY y GEMINI_MODEL.
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
  'Responde solo con el título de UNA misión que se pueda hacer hoy,',
  'en español, de 15 palabras como máximo, en tono de invitación,',
  'sin comillas, sin emojis y sin explicación.',
].join(' ');

/// Primera línea, sin comillas ni viñetas, en el límite de accept_npc_mission.
export function cleanTitle(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const line = raw.trim().split('\n')[0]
    .replace(/^(?:[-*•]|\d+[.)])\s*/, '')
    .replace(/^["'«“]+|["'»”.]+$/g, '')
    .trim();
  return line ? line.slice(0, 200) : null;
}

type Npc = {
  name: string;
  noble_mission: string | null;
  frequency: string;
  skills: { name: string } | null;
};

/// Texto que recibe la IA. Solo datos del NPC: en la capa gratis Google
/// puede usarlo para entrenar.
export function buildPrompt(npc: Npc, previous: string[]): string {
  return [
    `Tema (noble misión): ${npc.noble_mission ?? npc.skills?.name ?? 'general'}`,
    `Skill: ${npc.skills?.name ?? 'general'}`,
    `NPC: ${npc.name} · visita ${npc.frequency}`,
    previous.length ? `Misiones anteriores:\n- ${previous.join('\n- ')}` : '',
  ].filter(Boolean).join('\n');
}

/// `reason` (p. ej. `gemini_429`) llega al aviso de la app cuando no hay título.
async function suggest(
  npc: Npc,
  previous: string[],
): Promise<{ title: string | null; reason?: string }> {
  const prompt = buildPrompt(npc, previous);
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
        systemInstruction: { parts: [{ text: SYSTEM }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        // Sin maxOutputTokens: los modelos que "piensan" lo gastan y no dejan texto.
        generationConfig: { temperature: 0.9 },
      }),
    },
  );
  if (!res.ok) {
    console.error('gemini', res.status, await res.text());
    return { title: null, reason: `gemini_${res.status}` };
  }
  const data = await res.json();
  const title = cleanTitle(data?.candidates?.[0]?.content?.parts?.[0]?.text);
  if (title) return { title };
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

    // Si Gemini falla o se agota el cupo, el usuario escribe la misión como antes.
    const result = await suggest(npc, (tasks ?? []).map((t) => t.title)).catch((e) => {
      console.error('gemini', e);
      return { title: null, reason: 'gemini_sin_conexion' };
    });
    return json(result);
  });
}
