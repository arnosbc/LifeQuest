// deno test supabase/functions/npc-mission
import { assertEquals } from 'jsr:@std/assert@1';
import { buildPrompt, cleanTitle } from './index.ts';

Deno.test('buildPrompt usa la noble misión como tema y lista las anteriores', () => {
  const npc = { name: 'Iris', noble_mission: 'Fundamentos de diseño gráfico', frequency: 'weekly', skills: { name: 'Diseño' } };
  const prompt = buildPrompt(npc, ['Estudia la rueda de color']);
  assertEquals(prompt.split('\n')[0], 'Tema (noble misión): Fundamentos de diseño gráfico');
  assertEquals(prompt.includes('- Estudia la rueda de color'), true);
  // NPC antiguo sin noble misión: la skill hace de tema.
  assertEquals(buildPrompt({ ...npc, noble_mission: null }, []).split('\n')[0], 'Tema (noble misión): Diseño');
});

Deno.test('cleanTitle deja una sola línea limpia', () => {
  assertEquals(cleanTitle('"Camina 20 minutos al aire libre."\nPorque…'), 'Camina 20 minutos al aire libre');
  assertEquals(cleanTitle('- «Lee 10 páginas»'), 'Lee 10 páginas');
  assertEquals(cleanTitle('1. Ordena tu escritorio'), 'Ordena tu escritorio');
  assertEquals(cleanTitle('3 vueltas al parque'), '3 vueltas al parque');
  assertEquals(cleanTitle('x'.repeat(300))?.length, 200);
  assertEquals(cleanTitle('   '), null);
  assertEquals(cleanTitle(undefined), null);
});
