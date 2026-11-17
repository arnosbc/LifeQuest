// Edge Function push-dispatch · Envía por FCM los avisos que toca (050).
// La llama pg_cron cada 5 min con la cabecera x-push-secret. Supabase decide qué
// aviso sale (push_dispatch, mismas reglas que la revisión del teléfono); esta
// función solo lo entrega con Firebase Cloud Messaging (HTTP v1).
//
// Secrets: FIREBASE_SERVICE_ACCOUNT (JSON de la cuenta de servicio) y
// PUSH_CRON_SECRET. SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los pone Supabase.
// Desplegar con: supabase functions deploy push-dispatch --no-verify-jwt

import { createClient } from 'jsr:@supabase/supabase-js@2';

type Item = { id: string; type: string; title: string; message: string };
type Batch = { tokens: string[]; items: Item[] };
type ServiceAccount = { client_email: string; private_key: string; project_id: string };

// Mismos canales que la app (notifications_local_datasource.dart).
const CHANNEL: Record<string, string> = {
  critical: 'critical_v2',
  motivational: 'motivational_v2',
  informational: 'informational_v2',
};

const b64url = (data: ArrayBuffer | string) =>
  btoa(typeof data === 'string' ? data : String.fromCharCode(...new Uint8Array(data)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

/// Token de acceso de Google firmando un JWT con la clave de la cuenta de servicio.
async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))}`;
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s/g, '');
  const key = await crypto.subtle.importKey(
    'pkcs8',
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${b64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`google_oauth_${res.status}`);
  return (await res.json()).access_token;
}

/// Comparación en tiempo constante del secreto del cron.
function sameSecret(a: string, b: string): boolean {
  if (!a || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  if (!sameSecret(req.headers.get('x-push-secret') ?? '', Deno.env.get('PUSH_CRON_SECRET') ?? '')) {
    return new Response('forbidden', { status: 403 });
  }
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data, error } = await db.rpc('push_dispatch');
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const batches = (data ?? []) as Batch[];
  if (batches.length === 0) return Response.json({ sent: 0 });

  const sa = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!) as ServiceAccount;
  const bearer = await accessToken(sa);
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  let sent = 0;
  for (const { tokens, items } of batches) {
    for (const token of tokens) {
      for (const item of items) {
        const res = await fetch(url, {
          method: 'POST',
          headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: item.title, body: item.message },
              data: { id: String(item.id), type: item.type },
              android: {
                priority: 'HIGH',
                notification: {
                  channel_id: CHANNEL[item.type] ?? 'motivational_v2',
                  sound: 'default',
                  icon: 'ic_launcher',
                },
              },
            },
          }),
        });
        if (res.ok) {
          sent++;
        } else if (res.status === 404 || res.status === 400) {
          // Token borrado o inválido (app desinstalada): se olvida.
          const body = await res.text();
          if (body.includes('UNREGISTERED') || body.includes('INVALID_ARGUMENT')) {
            await db.rpc('clear_push_token', { p_fcm_token: token });
            break;
          }
        }
      }
    }
  }
  return Response.json({ sent });
});
