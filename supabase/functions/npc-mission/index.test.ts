// deno test supabase/functions/npc-mission
import { assertEquals } from 'jsr:@std/assert@1';
import {
  buildHabitPrompt,
  buildIdeasPrompt,
  buildPrompt,
  buildTaskPrompt,
  cleanTitle,
  formatGuide,
  parseGuide,
  parseIdeas,
  parsePlan,
  parseReply,
  parseSuggestion,
} from './index.ts';

Deno.test('buildHabitPrompt dice si el hábito es bueno o malo', () => {
  assertEquals(
    buildHabitPrompt({ name: 'Fumar', type: 'bad', frequency: 'daily' }),
    'Hábito: Fumar\nTipo: malo (quiere dejarlo)\nFrecuencia: daily',
  );
});

Deno.test('parsePlan exige la versión mínima y limpia espacios', () => {
  assertEquals(
    parsePlan('{"tiny":" Leer una página ","cue":"Después de cenar","reward":"","why":"Calma"}'),
    { tiny: 'Leer una página', cue: 'Después de cenar', why: 'Calma' },
  );
  assertEquals(parsePlan('{"cue":"sin tiny"}'), null);
  assertEquals(parsePlan('no es json'), null);
});

Deno.test('buildPrompt usa la noble misión como tema y lista las anteriores', () => {
  const npc = { name: 'Iris', noble_mission: 'Fundamentos de diseño gráfico', frequency: 'weekly', skills: { name: 'Diseño' } };
  const prompt = buildPrompt(npc, ['Estudia la rueda de color']);
  assertEquals(prompt.split('\n')[0], 'Tema (propósito del mentor): Fundamentos de diseño gráfico');
  assertEquals(prompt.includes('- Estudia la rueda de color'), true);
  // NPC antiguo sin noble misión: la skill hace de tema.
  assertEquals(buildPrompt({ ...npc, noble_mission: null }, []).split('\n')[0], 'Tema (propósito del mentor): Diseño');
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

Deno.test('buildTaskPrompt manda solo el título y qué significa completarla', () => {
  assertEquals(
    buildTaskPrompt({ title: 'Estudiar para el parcial', description: 'Repasar 3 temas' }),
    'Tarea: Estudiar para el parcial\nQué significa completarla: Repasar 3 temas',
  );
  assertEquals(buildTaskPrompt({ title: 'Leer', description: null }), 'Tarea: Leer');
});

Deno.test('buildTaskPrompt con lo que dijo la persona y los pasos hechos', () => {
  const prompt = buildTaskPrompt({ title: 'Ordenar escritorio', description: null }, 'No tengo escritorio', [
    'Retira lo que sobra',
  ]);
  assertEquals(prompt.includes('Pasos ya hechos:'), true);
  assertEquals(prompt.includes('- Retira lo que sobra'), true);
  assertEquals(prompt.endsWith('Lo que me dice la persona: No tengo escritorio'), true);
});

Deno.test('parseReply toma la respuesta de Nevi o null', () => {
  assertEquals(parseReply('{"reply":"  Entiendo, usemos tu cama.  "}'), 'Entiendo, usemos tu cama.');
  assertEquals(parseReply('{"steps":[]}'), null);
  assertEquals(parseReply('nada'), null);
});

Deno.test('parseGuide trae los minutos de cada paso, con tope y null si no son válidos', () => {
  const guide = parseGuide(JSON.stringify({
    steps: ['Junta los cuadernos', 'Separa lo que no usas', 'Ordena la pila'],
    step_minutes: [5, 500, 'diez'],
  }));
  assertEquals(guide?.minutes, [5, 120, null]);
  assertEquals(parseGuide(JSON.stringify({ steps: ['Uno'] }))?.minutes, [null]);
});

Deno.test('buildIdeasPrompt usa solo datos de la app y sirve sin datos', () => {
  assertEquals(
    buildIdeasPrompt({ identity: ' Alguien sano ', areas: ['Inglés'], habits: ['Leer'] }),
    'Quién quiere ser: Alguien sano\nSus áreas: Inglés\nHábitos que ya tiene (no los repitas): Leer',
  );
  assertEquals(
    buildIdeasPrompt({}),
    'Aún no hay datos: propón hábitos de bienestar básicos y variados.',
  );
});

Deno.test('parseIdeas: máximo 3, sin repetir los suyos, hora válida o null', () => {
  const text = JSON.stringify({
    ideas: [
      { name: ' Leer ', why: 'Ya lo tienes', time: '21:00' },
      { name: 'Caminar 10 minutos', why: 'Te despeja', time: '07:30' },
      { name: 'Tomar agua al despertar', why: 'Te hidrata', time: '25:99' },
      { name: '', why: 'vacío', time: '08:00' },
      { name: 'caminar 10 minutos', why: 'repetida', time: '08:00' },
      { name: 'Estirar 2 minutos', why: 'Menos tensión', time: '18:00' },
      { name: 'Escribir 1 línea', why: 'sobra', time: '22:00' },
    ],
  });
  assertEquals(parseIdeas(text, ['Leer']), [
    { name: 'Caminar 10 minutos', why: 'Te despeja', time: '07:30' },
    { name: 'Tomar agua al despertar', why: 'Te hidrata', time: null },
    { name: 'Estirar 2 minutos', why: 'Menos tensión', time: '18:00' },
  ]);
  assertEquals(parseIdeas('no es json'), []);
  assertEquals(parseIdeas('{"ideas":"x"}'), []);
});
