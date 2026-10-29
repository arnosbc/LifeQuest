// deno test supabase/functions/npc-mission
import { assertEquals } from 'jsr:@std/assert@1';
import { buildPrompt, cleanTitle, formatGuide, parseSuggestion } from './index.ts';

Deno.test('buildPrompt usa la noble misión como tema y lista las anteriores', () => {
  const npc = { name: 'Iris', noble_mission: 'Fundamentos de diseño gráfico', frequency: 'weekly', skills: { name: 'Diseño' } };
  const prompt = buildPrompt(npc, ['Estudia la rueda de color']);
  assertEquals(prompt.split('\n')[0], 'Tema (noble misión): Fundamentos de diseño gráfico');
  assertEquals(prompt.includes('- Estudia la rueda de color'), true);
  // NPC antiguo sin noble misión: la skill hace de tema.
  assertEquals(buildPrompt({ ...npc, noble_mission: null }, []).split('\n')[0], 'Tema (noble misión): Diseño');
});

Deno.test('buildPrompt añade el resumen de los documentos de contexto', () => {
  const npc = { name: 'Ada', noble_mission: 'Programación móvil', frequency: 'weekly', skills: { name: 'Programación' } };
  const prompt = buildPrompt(npc, [], [
    { title: 'Plan de asignatura', ai_summary: 'Unidad 1: Flutter. Unidad 2: estado.' },
    { title: 'Sin resumen', ai_summary: null },
  ]);
  assertEquals(prompt.includes('Documento de contexto «Plan de asignatura» (resumen):\nUnidad 1: Flutter.'), true);
  assertEquals(prompt.includes('Sin resumen'), false);
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

Deno.test('parseSuggestion arma la guía con objetivo, pasos, pistas y búsqueda', () => {
  const { title, guide } = parseSuggestion(JSON.stringify({
    title: '«Resuelve un sistema 3x3 por eliminación gaussiana.»',
    objective: 'Aprenderás a escalonar una matriz.',
    steps: ['1. Escribe la matriz aumentada de x + y + z = 6, 2y + 5z = -4, 2x + 5y - z = 27', '-3x + y = 2'],
    hints: ['- Una fila puede sumarse a otra multiplicada por un número'],
    search: ['eliminación gaussiana paso a paso'],
  }));
  assertEquals(title, 'Resuelve un sistema 3x3 por eliminación gaussiana');
  assertEquals(guide, [
    'Objetivo: Aprenderás a escalonar una matriz.',
    'Pasos:\n1. Escribe la matriz aumentada de x + y + z = 6, 2y + 5z = -4, 2x + 5y - z = 27\n2. -3x + y = 2',
    'Pistas:\n• Una fila puede sumarse a otra multiplicada por un número',
    'Para aprender más, busca: eliminación gaussiana paso a paso',
  ].join('\n\n'));
});

Deno.test('parseSuggestion tolera texto libre y campos vacíos', () => {
  assertEquals(parseSuggestion('Lee 10 páginas\nporque…'), { title: 'Lee 10 páginas', guide: null });
  assertEquals(parseSuggestion(JSON.stringify({ title: 'Estira', steps: [], hints: [7] })),
    { title: 'Estira', guide: null });
  assertEquals(parseSuggestion(undefined), { title: null, guide: null });
  assertEquals(formatGuide({ objective: 'x'.repeat(5000) })?.length, 4000);
});
