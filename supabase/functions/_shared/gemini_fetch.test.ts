// deno test supabase/functions/_shared
import { assertEquals } from 'jsr:@std/assert@1';
import { geminiFetch } from './gemini_fetch.ts';

const fake = (statuses: number[]) => {
  let calls = 0;
  const fn = (() => Promise.resolve(new Response('x', { status: statuses[calls++] }))) as typeof fetch;
  return { fn, calls: () => calls };
};

Deno.test('reintenta un 503 y devuelve el primer éxito', async () => {
  const f = fake([503, 200]);
  const res = await geminiFetch('u', {}, f.fn, 0);
  assertEquals([res.status, f.calls()], [200, 2]);
});

Deno.test('se rinde tras 3 intentos con 503', async () => {
  const f = fake([503, 503, 503, 200]);
  const res = await geminiFetch('u', {}, f.fn, 0);
  assertEquals([res.status, f.calls()], [503, 3]);
});

Deno.test('no reintenta otros errores (429, 400)', async () => {
  for (const status of [429, 400]) {
    const f = fake([status, 200]);
    const res = await geminiFetch('u', {}, f.fn, 0);
    assertEquals([res.status, f.calls()], [status, 1]);
  }
});
