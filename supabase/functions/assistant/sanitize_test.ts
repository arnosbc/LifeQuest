// Uso: node --experimental-strip-types --test supabase/functions/assistant/sanitize_test.ts
// (en Deno: deno test supabase/functions/assistant/)
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { sanitizeGoal, sanitizeParse, sanitizeQuestions, sanitizeSteps } from './sanitize.ts';

const now = new Date('2026-11-05T14:00:00Z');

test('parse: deja pasar lo válido y normaliza la hora a UTC', () => {
  const r = sanitizeParse({
    kind: 'task',
    title: '  "Gimnasio"  ',
    scheduled_at: '2026-11-06T18:00:00-05:00',
    due_date: null,
    estimated_minutes: 60,
    reminder_minutes: 15,
    repeat_rule: 'weekly:1',
    priority: 'high',
  }, 'gym mañana 6pm cada lunes', now);
  assert.deepEqual(r, {
    kind: 'task',
    title: 'Gimnasio',
    scheduled_at: '2026-11-06T23:00:00.000Z',
    due_date: null,
    estimated_minutes: 60,
    reminder_minutes: 15,
    repeat_rule: 'weekly:1',
    priority: 'high',
  });
});

test('parse: descarta lo que no cumple formato o rango', () => {
  const r = sanitizeParse({
    kind: 'algo',
    title: 42,
    scheduled_at: '2019-01-01T10:00:00Z',
    due_date: 'mañana',
    estimated_minutes: 2.5,
    reminder_minutes: 15,
    repeat_rule: 'cada lunes',
    priority: 'urgentísima',
    extra: 'DROP TABLE',
  }, '  llamar a mamá  ', now);
  assert.deepEqual(r, {
    kind: 'task',
    title: 'llamar a mamá',
    scheduled_at: null,
    due_date: null,
    estimated_minutes: null,
    reminder_minutes: null, // sin hora válida no hay aviso
    repeat_rule: null,
    priority: 'low',
  });
  assert.equal(sanitizeParse(null, 'x', now).title, 'x');
  assert.equal(sanitizeParse({ kind: 'note' }, 'idea', now).kind, 'note');
});

test('steps: 2–7 pasos únicos de una línea, sin viñetas', () => {
  assert.deepEqual(
    sanitizeSteps({ steps: ['1. Investigar', '- Escribir\nborrador', 'Investigar', '', 7] }),
    ['Investigar', 'Escribir'],
  );
  assert.equal(sanitizeSteps({ steps: ['Solo uno'] }), null);
  assert.equal(sanitizeSteps('texto'), null);
  assert.equal(sanitizeSteps({ steps: Array.from({ length: 10 }, (_, i) => `Paso ${i}`) })!.length, 7);
});

test('goal: exige los 4 campos S.M.A.R.T. y al menos 2 pasos', () => {
  const ok = sanitizeGoal({
    title: 'Correr 10 km',
    specific: 'Correr 10 km sin parar',
    measurable: 'Tiempo y distancia en la app',
    achievable: 'Entreno 3 días por semana',
    relevant: 'Mejorar mi salud',
    steps: ['Correr 3 km', 'Correr 5 km', 'Correr 8 km'],
  }, 'correr 10k');
  assert.equal(ok?.title, 'Correr 10 km');
  assert.equal(ok?.steps.length, 3);
  assert.equal(sanitizeGoal({ title: 'x', steps: ['a', 'b'] }, 'x'), null);
  assert.equal(sanitizeGoal({ specific: 'a', measurable: 'b', achievable: 'c',
    relevant: 'd', steps: ['a', 'b'] }, 'aprender piano')?.title, 'aprender piano');
});

test('questions: 1–3 preguntas únicas de una línea', () => {
  assert.deepEqual(
    sanitizeQuestions({ questions: ['1. ¿Qué es un límite?', '¿Qué es un límite?', 3, '- ¿Por qué falló el 4?\nextra'] }),
    ['¿Qué es un límite?', '¿Por qué falló el 4?'],
  );
  assert.equal(sanitizeQuestions({ questions: [] }), null);
  assert.equal(sanitizeQuestions(null), null);
  assert.equal(sanitizeQuestions({ questions: ['a', 'b', 'c', 'd'] })!.length, 3);
});
