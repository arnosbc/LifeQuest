// Edge Function npc-context · Resume UNA vez el documento de contexto de un NPC
// (p. ej. el plan de la asignatura) para que npc-mission proponga misiones
// sobre sus temas. Migración 032. Secrets: GEMINI_API_KEY y GEMINI_MODEL.
//
// La app sube el archivo al bucket privado `npc-context`
// (<user_id>/<npc_id>/<archivo>) y llama aquí con { npc_id, path, title }.
// Acepta PDF (Gemini lo lee directo), Word .docx (se extrae el texto) y
// Markdown o texto. Si algo falla, borra el archivo y no guarda nada.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { encodeBase64 } from 'jsr:@std/encoding@1/base64';
import { strFromU8, unzipSync } from 'npm:fflate@0.8.2';

const SYSTEM = [
  'Eres RPGenie, el asistente de una app de productividad con estilo RPG.',
  'Recibes un documento de contexto (por ejemplo, el plan de una asignatura universitaria).',
  'Resúmelo para proponer después misiones de estudio sobre sus temas.',
  'Escribe en español y en texto plano (sin Markdown de tablas):',
  '1) De qué trata en una frase.',
  '2) Las unidades o temas EN EL ORDEN del documento, cada uno con sus subtemas.',
  '3) Los objetivos de aprendizaje o competencias.',
  '4) Prácticas, proyectos, entregas o evaluaciones, con fechas si las hay.',
  '5) Bibliografía o herramientas clave.',
  'Omite lo que el documento no traiga. Como máximo 1200 palabras.',
  'No incluyas datos personales: ni nombres de personas, ni correos, ni teléfonos.',
].join(' ');

/// Límites de add_npc_document (032).
const SUMMARY_MAX = 8000;
/// Texto máximo que se envía a Gemini (≈ 80 k tokens).
const TEXT_MAX = 300_000;

export type DocKind = 'pdf' | 'docx' | 'text';

/// Tipo de documento según la extensión; null si no se acepta.
export function kindOf(path: string): DocKind | null {
  const ext = path.toLowerCase().split('.').pop();
  if (ext === 'pdf') return 'pdf';
  if (ext === 'docx') return 'docx';
  if (ext === 'md' || ext === 'markdown' || ext === 'txt') return 'text';
  return null;
}

const ENTITIES: Record<string, string> = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'",
};

/// Texto de un .docx: un .zip cuyo cuerpo está en word/document.xml.
/// Cada párrafo (<w:p>) pasa a ser una línea.
export function docxText(bytes: Uint8Array): string {
  const files = unzipSync(bytes, { filter: (f) => f.name === 'word/document.xml' });
  const xml = files['word/document.xml'];
  if (!xml) return '';
  return strFromU8(xml)
    .replace(/<w:tab\/>/g, '\t')
    .replace(/<w:br\/>|<w:p\/>|<\/w:p>/g, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&(#x[0-9a-f]+|#\d+|\w+);/gi, (m, e: string) =>
      e[0] === '#'
        ? String.fromCodePoint(parseInt(e[1] === 'x' ? e.slice(2) : e.slice(1), e[1] === 'x' ? 16 : 10))
        : ENTITIES[e] ?? m)
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/// Parte del mensaje a Gemini con el documento; null si no tiene texto.
export function documentPart(kind: DocKind, bytes: Uint8Array): Record<string, unknown> | null {
  if (kind === 'pdf') {
    return { inlineData: { mimeType: 'application/pdf', data: encodeBase64(bytes) } };
  }
  const text = (kind === 'docx' ? docxText(bytes) : new TextDecoder().decode(bytes)).trim();
  return text ? { text: `Documento:\n${text.slice(0, TEXT_MAX)}` } : null;
}

async function summarize(part: Record<string, unknown>): Promise<{ summary?: string; reason?: string }> {
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
        contents: [{ role: 'user', parts: [part] }],
        generationConfig: { temperature: 0.2, thinkingConfig: { thinkingLevel: 'low' } },
      }),
      // Un documento largo tarda más que una misión.
      signal: AbortSignal.timeout(60_000),
    },
  );
  if (!res.ok) {
    console.error('gemini', res.status, await res.text());
    return { reason: `gemini_${res.status}` };
  }
  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  const summary = typeof text === 'string' ? text.trim().slice(0, SUMMARY_MAX) : '';
  if (summary) return { summary };
  console.error('gemini sin texto', JSON.stringify(data).slice(0, 500));
  return { reason: `sin_texto_${data?.candidates?.[0]?.finishReason ?? 'vacio'}` };
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
    const { npc_id, path, title } = await req.json().catch(() => ({}));
    if (typeof npc_id !== 'string' || typeof path !== 'string' || typeof title !== 'string') {
      return json({ error: 'invalid_request' }, 400);
    }

    // Cliente con el JWT del usuario: Storage y RLS solo dejan lo suyo.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    );
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) return json({ error: 'not_authenticated' }, 401);
    if (!path.startsWith(`${auth.user.id}/${npc_id}/`)) return json({ error: 'invalid_path' }, 400);

    const bucket = supabase.storage.from('npc-context');
    // Si no se guarda, el archivo sobra.
    const fail = async (error: string, status = 200) => {
      await bucket.remove([path]);
      return json({ error }, status);
    };

    const kind = kindOf(path);
    if (!kind) return fail('unsupported_type');
    const { data: file, error: downloadError } = await bucket.download(path);
    if (downloadError || !file) {
      console.error('storage', downloadError);
      return json({ error: 'file_not_found' }, 404);
    }

    let part: Record<string, unknown> | null;
    try {
      part = documentPart(kind, new Uint8Array(await file.arrayBuffer()));
    } catch (e) {
      console.error('lectura', e);
      return fail('unreadable_document');
    }
    if (!part) return fail('empty_document');

    const result = await summarize(part).catch((e) => {
      console.error('gemini', e);
      const timedOut = e instanceof DOMException && e.name === 'TimeoutError';
      return { reason: timedOut ? 'gemini_timeout' : 'gemini_sin_conexion' };
    });
    if (!result.summary) return fail(result.reason ?? 'gemini_sin_texto');

    const { data: id, error } = await supabase.rpc('add_npc_document', {
      p_npc_id: npc_id,
      p_title: title,
      p_path: path,
      p_summary: result.summary,
    });
    if (error) {
      console.error('add_npc_document', error);
      return fail(error.message);
    }
    return json({ id, title });
  });
}
