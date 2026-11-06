// Uso: node --experimental-strip-types --test supabase/functions/assistant/sanitize_test.ts
// (en Deno: deno test supabase/functions/assistant/)
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { sanitizeParse, sanitizeSteps } from './sanitize.ts';

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
