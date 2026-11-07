---
name: revision-funcionalidades
description: Filtro de producto de Questly (LifeQuest). Evalúa funciones existentes o propuestas con la regla del rework «cada función debe actuar en el día real del usuario, no solo guardar filas», y entrega un veredicto por función (Actúa / Solo guarda / Solo muestra), qué le falta para actuar y su prioridad. Úsala siempre que se proponga, diseñe, revise o priorice una función, pantalla o idea de Questly, cuando el usuario pregunte «¿esto sirve?», «¿qué construyo primero?», «¿qué le falta a la app?», cuando compare con otras apps (Todoist, TickTick, Habitica…), o antes de escribir código de una función nueva, aunque no diga «revisión».
---

# Revisión de funcionalidades (Questly)

El tutor rechazó la primera versión porque crear algo «solo guardaba texto» y muchas pantallas eran de solo lectura. Esta skill aplica ese mismo examen a cada función, para que nada nuevo repita el error. Es el filtro de **qué** construir; `ux-interaction` decide **cómo se usa**, `product-discovery` mide el riesgo y `brainstorm-ideas-existing` genera ideas que luego pasan por aquí.

Lee primero `CLAUDE.md` §0 (rework) y `docs/plan-rework.md` (qué ya existe). Revisa el código o la migración real de cada función antes de juzgarla: el veredicto se basa en lo que hace hoy, no en lo que dice un documento.

## 1. El veredicto

Para cada función, una de tres:

| Veredicto | Significa | Ejemplo en Questly |
|---|---|---|
| **Actúa** | Cambia algo del día real sin que el usuario lo vuelva a pedir: suena, agenda, mide tiempo, mueve, usa el sistema del teléfono | Recordatorio con «Hecha / Posponer», Foco que mide minutos, cierre del día a las 21:00 |
| **Solo guarda** | Crea filas que nadie vuelve a usar para hacer algo | Un recurso con enlace que la IA no lee |
| **Solo muestra** | Pantalla de lectura sin acción principal | Estadísticas sin ninguna decisión que tomar |

Una función **actúa** si responde «sí» al menos a una de estas preguntas:
1. **Tiempo:** ¿pasa algo a una hora concreta (aviso, bloque en la agenda, repetición)?
2. **Medida:** ¿mide algo real (minutos de foco, días cumplidos) y lo devuelve como decisión?
3. **Sistema:** ¿usa el teléfono (notificación con botones, widget, voz, compartir, calendario)?
4. **Siguiente paso:** ¿deja al usuario con la próxima acción concreta ya puesta (pasos, hora, «Empezar foco»)?
5. **Reacción:** ¿responde cuando el plan se rompe (atrasado → replanificar, racha en riesgo → aviso)?

Si es «Solo guarda» o «Solo muestra», escribe **qué le falta para actuar** en una línea, eligiendo la pregunta de arriba que más barato la convierte.

## 2. Las reglas de la casa (descartan o corrigen)

Una propuesta que rompe una de estas se marca **Bloqueada** con la regla, aunque actúe:

- **Reglas antes que IA:** lo determinista (fechas, huecos, orden, XP) va en `domain` con tests; la IA (Gemini capa gratis) solo interpreta lenguaje. Una función que pide a la IA decidir algo calculable está mal planteada.
- **Gratis:** nada que pueda cobrar (APIs de pago, servidores propios). Gemini con tope diario y apagado por defecto.
- **Privacidad:** a la IA solo va lo que el usuario escribió o eligió enviar, con aviso. Enviar más contexto es decisión abierta (CLAUDE.md §11): pregunta al usuario.
- **Sin fantasía y juego ligero:** solo XP, nivel y racha. Sin tienda, monedas visibles, jefes ni mascotas.
- **Ético (§9):** sin dark patterns, castigos de golpe ni avisos para «volver» sin motivo; tono de invitación (§7).
- **Un solo usuario (§10):** sin rankings ni social.
- **Android primero; el servidor manda en la economía:** XP y completar van por RPC `SECURITY DEFINER`.
- **Arquitectura (§8):** una feature no importa otra; la composición va en `app/`.

## 3. Prioridad

Puntúa 1–3 cada eje y multiplica:

- **Impacto en el día:** ¿cuántas veces al día o a la semana actúa? (3 = a diario)
- **Cercanía al hueco:** ¿cuánto falta para que actúe? (3 = ya existe casi todo; reusar beats construir)
- **Riesgo bajo:** según `product-discovery` (valor, uso, factibilidad, viabilidad). (3 = riesgo bajo)

**Alta** ≥ 18 · **Media** 8–17 · **Baja** < 8. Ordena por puntaje; empata a favor de lo que no toca la BD.

## 4. Formato de salida

Siempre esta tabla, una fila por función, y después la lista priorizada:

```markdown
## Revisión de funcionalidades — <alcance> (<fecha>)

| Función | Dónde (archivo o RPC) | Veredicto | Por qué (pregunta 1–5 o regla) | Qué le falta para actuar | Prioridad |
|---|---|---|---|---|---|

### Qué construir primero
1. <función> — <cambio mínimo que la hace actuar> (<puntaje>)

### Bloqueadas
- <propuesta> — <regla que rompe> — <versión que sí cabría>
```

Luego, para cada función de prioridad Alta, pasa `ux-interaction` sobre su diseño antes de escribir código.

## Ejemplo

Entrada: «¿Sirven los recursos de Proyectos?»

| Función | Dónde | Veredicto | Por qué | Qué le falta para actuar | Prioridad |
|---|---|---|---|---|---|
| Recursos | `create_resource` (013), Proyectos | Solo guarda | Nadie lee el enlace; la IA solo recibe el título de la tarea | Que «Dividir en pasos» use el texto del recurso del Área (pregunta 4) — requiere decisión de privacidad | Media (2×2×2 = 8) |
