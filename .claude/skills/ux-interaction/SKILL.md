---
name: ux-interaction
description: Interaction and UX logic for app screens, especially mobile (Flutter, iOS, Android). Decides what each control means, which action a screen leads with, how mistakes are prevented and undone, how much fits before the user has to scroll, and what work the app should do instead of the user. Use before building or changing any screen, flow, list row, form or gesture, and when reviewing UI for usability ("is this confusing?", "UX review", "why did the user tap the wrong thing?"). Complements design-taste-frontend (art direction), impeccable (design process and critique) and emil-design-eng (polish and motion): this one covers behaviour, not looks.
---

# UX Interaction

Taste decides how a screen looks. This skill decides whether a person can use it without guessing, without losing work, and without doing the app's job for it. Run it **before** writing UI code, then again as a review on the result.

## The six questions (ask them for every screen)

1. **What is the one job of this screen?** Name the primary action. It is visible without scrolling on a 360×640 dp phone at text scale 1.3. Everything else is secondary or folded.
2. **What does each control mean here, and does it mean the same everywhere?** One visual = one meaning across the app. If a check circle selects items in one screen, it must not finish items in another.
3. **What happens if this is tapped by accident?** Every action that changes data is either reversible (undo) or guarded. Prefer undo over a confirm dialog.
4. **What is the user typing that the app could produce?** If the app has the data or an assistant, it proposes and the user edits. Empty fields where a suggestion is possible are a bug.
5. **How long is this screen on a heavy day?** Fill it with the worst realistic data (20 tasks, 8 events, 6 habits). If a one-tap action ends up below two screens of scrolling, the layout is wrong.
6. **Can it be done without sight and without precision?** Every gesture has a visible alternative; every icon button has a label; targets are 48 dp.

## Rules

### Affordance and meaning
- A control's look promises a behaviour. An empty circle reads as "select/finish this". Never show one that does nothing when tapped: remove it or make it act.
- Do not reuse a control for two meanings. When two screens need "pick" and "finish", give them different forms (checkbox for selection; swipe + labelled button for finishing).
- Label verbs with the outcome in the user's words: "Ya la hice", "Empezar foco", "Armar mi día". Not "OK", "Procesar", "Enviar".
- Destructive or final actions never sit where the thumb rests while scrolling (the leading edge of a list row is a scroll-grab zone).

### Error prevention and recovery (Nielsen 3 + 5)
- Order of preference: **make the error impossible → undo → confirm**.
- Undo pattern for "complete", "archive", "delete": hide the item immediately, show a snackbar with "Deshacer" for ~5 s, commit to the server when the window closes. The window lives in the state layer (bloc), not in the widget, and pending commits flush when the screen closes.
- Anything that awards points, money or streaks must be reversible within the window, because a reward for a mistake teaches the user that the app does not care.
- Confirm dialogs only for actions that cannot be undone and destroy user-written content. Write the consequence, not "¿Estás seguro?".

### Effort: the app works, the user decides
- Defaults are a decision the app makes so the user doesn't have to (Hick's law). Pick the likely date, time, duration and area.
- When an assistant exists, the flow is **propose → review → accept**: a button fills the fields ("Dividir en pasos"), the user edits or removes. Never present an empty list with "Añadir paso" as the only path.
- If the assistant is off or fails, say why in one line next to the button and keep the manual path working. Errors inside a modal sheet go inline, not in a snackbar hidden behind the sheet.
- Do not ask for what can be inferred (title words → priority hints, deadline → step dates).

### Density and scroll budget on mobile
- Order sections by **frequency × speed**: one-tap daily actions (habits, current task) above long reference lists (agenda, backlog).
- Long lists on a summary screen show a preview (3 items of what comes next) and fold the rest behind "Ver todo · N más". The full list lives in its own tab; the summary never duplicates it.
- Merge parallel lists that share an axis (calendar events + time blocks = one timeline sorted by time).
- Collapse past and done items by default; they are history, not action.
- Many small one-tap items (habits, filters) go in a wrapping row of chips, not one row per item.
- A summary card counts; it does not list. "5 tareas sin hora · Armar mi día" beats five rows.

### Gestures
- Swipe is a shortcut, never the only path. Pair it with a visible button on the focused item and a menu entry.
- Swipe right = positive (done), swipe left = negative (delete/postpone). Keep it consistent app-wide.
- Show the swipe once with a hint in the subtitle or empty state; don't rely on discovery.
- Threshold ≥ 40 % of width to avoid accidental triggers during vertical scroll.

### Feedback
- Every tap gets a response within 100 ms (pressed state, spinner on the item, not a full-screen loader).
- After a state change, say what changed and what it earned: "«Comprar pan» hecha · +10 XP".
- Optimistic UI for reversible actions; keep the old data on screen if the server fails and say so.

### Forms
- Required first, optional folded ("Hora, aviso, repetir y más"). The most valuable optional thing (e.g. steps) is not buried under the fold if the app can fill it.
- One column, labels outside the field, keyboard type matches the data, primary button reachable without closing the keyboard.
- Editing mode hides what cannot be edited instead of showing disabled fields without explanation.

### Accessibility (WCAG 2.1 AA, non-negotiable)
- Targets ≥ 48 dp (44 pt iOS). Contrast 4.5:1 (3:1 large text and icons).
- `Semantics` with `button`, `checked`/`selected` and a label that says the outcome ("Marcar Leer como hecho").
- Color never alone: pair with icon, text or strike-through.
- Respect reduce-motion and text scale up to 1.3 without overflow.

## Workflow

1. **Before coding**: write the screen's job, its primary action and the worst-case data set in 3 lines. Answer the six questions.
2. **Map the controls**: list every interactive element with its meaning. Check each meaning against other screens (grep the shared widget, e.g. `SheetCheck`, and see where else it appears and what it does there).
3. **Build** with the house components (in this repo: `lib/core/widgets/`, `lib/core/widgets/questly/`, tokens in `context.q`).
4. **Review** against the checklist below, with worst-case data (use `break-ui` for content extremes).
5. **Report** findings as: problem → who it hurts → fix, ordered by harm (data loss and false rewards first, then confusion, then effort, then polish).

## Review checklist

- [ ] Primary action visible above the fold on 360×640 @1.3×.
- [ ] No control looks interactive without being interactive (dead checkboxes, chevrons that don't open).
- [ ] Same glyph, same meaning across screens.
- [ ] Every completing/deleting/rewarding action has undo or is impossible by accident.
- [ ] Nothing the app could suggest is left for the user to type from scratch.
- [ ] One-tap daily actions sit above long lists; long lists preview 3 and fold.
- [ ] Parallel lists on the same axis are merged.
- [ ] Every gesture has a visible and an accessible alternative.
- [ ] Errors in sheets show inline; snackbars only on full screens.
- [ ] Semantics labels describe outcomes; targets ≥ 48 dp; color never alone.

## Anti-patterns seen in this project (keep as examples)

| Seen | Why it failed | Fix applied |
|---|---|---|
| Check circle at the left of each task completed it on tap | Same circle selects tasks in Foco; users tapped it to pick, and it finished the task and paid XP | No check in Tareas; swipe right or "Ya la hice" on the current task or menu; 5 s undo before the server is called |
| Empty "Subtareas" list under "more options" | The user did the assistant's job; the AI breakdown existed only in another flow | "Dividir en pasos" in the task form fills the steps; manual add stays |
| Today: Ahora → full agenda → 5 unscheduled rows → habits | One-tap habits ended up two screens down on busy days | Habits as chips right after Ahora; agenda previews the next 3; unscheduled collapsed to one summary row |
| Empty check circles on agenda rows for tasks | Looked tappable, did nothing | Removed; only reminders keep a working check |
