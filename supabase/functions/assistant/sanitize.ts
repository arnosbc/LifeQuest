// Validación de lo que responde la IA. No se confía en su JSON: todo campo
// fuera de formato o de rango se descarta (queda null) en vez de llegar a la app.
// Sin APIs de Deno para poder probarlo también con Node.

export type ParsedTask = {
  kind: 'task' | 'note';
  title: string;
  scheduled_at: string | null;
  due_date: string | null;
  estimated_minutes: number | null;
  reminder_minutes: number | null;
  repeat_rule: string | null;
  priority: 'low' | 'medium' | 'high';
};

const REPEAT = /^(daily|weekdays|weekly:[0-6](,[0-6])*|monthly:([1-9]|[12][0-9]|3[01]))$/;
const DAY = 24 * 3600 * 1000;

const int = (v: unknown, min: number, max: number): number | null =>
  typeof v === 'number' && Number.isInteger(v) && v >= min && v <= max ? v : null;

/// ISO dentro de [ahora − 1 día, ahora + 1 año]; se devuelve en UTC.
const date = (v: unknown, now: Date): string | null => {
  if (typeof v !== 'string') return null;
  const t = Date.parse(v);
  if (Number.isNaN(t) || t < now.getTime() - DAY || t > now.getTime() + 366 * DAY) {
    return null;
  }
  return new Date(t).toISOString();
};

const text = (v: unknown): string | null => {
  if (typeof v !== 'string') return null;
  const line = v.trim().split('\n')[0].replace(/^["'«“]+|["'»”]+$/g, '').trim();
  return line ? line.slice(0, 200) : null;
};

/// [input] es lo que escribió el usuario: título de respaldo si la IA no da uno.
export function sanitizeParse(raw: unknown, input: string, now: Date): ParsedTask {
  const o = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const repeat = typeof o.repeat_rule === 'string' && REPEAT.test(o.repeat_rule)
    ? o.repeat_rule
    : null;
  const scheduled = date(o.scheduled_at, now);
  return {
    kind: o.kind === 'note' ? 'note' : 'task',
    title: text(o.title) ?? input.trim().slice(0, 200),
    scheduled_at: scheduled,
    due_date: date(o.due_date, now),
    estimated_minutes: int(o.estimated_minutes, 5, 720),
    // Un aviso sin hora no sirve de nada.
    reminder_minutes: scheduled ? int(o.reminder_minutes, 0, 1440) : null,
    repeat_rule: repeat,
    priority: o.priority === 'high' || o.priority === 'medium' ? o.priority : 'low',
  };
}

/// 3–7 pasos distintos, de una línea; null si la IA no dio al menos 2.
export function sanitizeSteps(raw: unknown): string[] | null {
  const list = Array.isArray((raw as { steps?: unknown })?.steps)
    ? (raw as { steps: unknown[] }).steps
    : [];
  const clean = list
    .map(text)
    .map((s) => s?.replace(/^(?:[-*•]|\d+[.)])\s*/, '').trim())
    .filter((s): s is string => !!s);
  const steps = [...new Set(clean)].slice(0, 7);
  return steps.length >= 2 ? steps : null;
}
