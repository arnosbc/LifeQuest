# PRODUCT.md — Producto (v2 · moderno, sin fantasía)

> **v2 (2026-10-29):** la app deja de presentarse como un RPG de fantasía. Se mantiene la gamificación
> (XP, niveles, rachas, Monedas, logros) con el lenguaje de las apps de hábitos. El nombre comercial está
> por decidir; el código y el título siguen como **LifeQuest**. Plan completo:
> `docs/plan-funcionalidades-asistente.md`.

## Qué es
Una app móvil de productividad con **progreso visible** y un **Asistente** que acompaña. Convierte tareas,
hábitos, proyectos y metas en pasos concretos, y cada avance real se ve en tu nivel, tus áreas y tus metas.

> «Organiza lo que quieres lograr, avanza paso a paso y ve cómo creces.»

## Para quién
Personas (estudiantes y jóvenes profesionales) que saben qué hacer pero les cuesta empezar. Les afectan:

- la brecha entre intención y acción;
- la falta de feedback inmediato;
- la fatiga de decisión;
- el pensamiento todo-o-nada.

## Principios
1. **Calma primero:** poca información por pantalla y una acción principal clara.
2. **Progreso visible:** cada acción real tiene una respuesta inmediata y deja una huella que se ve crecer.
3. **Sin culpa:** perder Constancia o una racha siempre tiene una salida. Nunca se pierde nivel ni progreso.
4. **Ético:** ninguna mecánica existe solo para retener al usuario. Sin patrones oscuros.
5. **Accesible:** WCAG 2.1 AA y zonas táctiles de 44 px.

## Estructura
- **Navegación de 5 pestañas:** Inicio · Planificador (Hoy, Calendario, Biblioteca) · Hábitos · Foco
  (Modo Foco) · Perfil.
- **Desde Inicio:** Avisos, Siguiente paso del Asistente, Mentores, Bandeja de ideas y Metas.
- **Desde Perfil:** Estadísticas, Visión, Logros, Recompensas, Actividad y Ajustes.
- **Antes de entrar:** Iniciar sesión / Crear cuenta / Recuperar contraseña y bienvenida de 5 pasos.

## Reglas clave
- **XP y nivel:**
  - la XP mide el progreso y nunca se gasta;
  - XP para subir de nivel: 100 × nivel^1,5;
  - las Áreas suben de nivel con la XP de sus tareas.
- **Tareas:**
  - sin tiempo estimado ni dificultad elegida por el usuario;
  - **la app calcula la XP por reglas** (10–40);
  - se pueden vincular a un Proyecto o a una Meta;
  - las tareas guiadas reparten su XP entre sus pasos.
- **Metas:**
  - son metas S.M.A.R.T. con una **barra de avance** de 0 a 100 %;
  - cada tarea o proyecto vinculado la hace avanzar.
- **Monedas (economía estable):**
  - 30 % de la XP;
  - tope diario suave de 50 + 25;
  - Recompensas en 3 categorías: Descanso (30 · 70 · 150), Protector de racha (90) y Reparar racha (150),
    y Mejoras (120 × 1,35ⁿ);
  - *aprobado el 2026-10-29, pendiente de la migración 038:* sin límite de bolsa ni Tesoro, sin Elixir y sin
    Cofre comprado. Mientras tanto, la app muestra lo que hay en el servidor.
- **Constancia (antes HP):**
  - pérdidas: mal hábito −3/−5/−8, plazo vencido −5, día sin actividad −5;
  - +4 al día con un hábito bueno;
  - por debajo de 30 queda en «Constancia baja» (−25 % de XP).
- **Ritmo (dificultad):**
  - solo se cambia en Ajustes;
  - XP ×1,2 / ×1 / ×0,85;
  - Constancia perdida ×0,75 / ×1 / ×1,25;
  - las Monedas no cambian.

Detalle completo: `docs/ideas-proyecto-productividad-gamificada.md` (vocabulario anterior) y
`docs/plan-funcionalidades-asistente.md`.

## Stack
Flutter/Dart (frontend) y Supabase (Auth, PostgREST, RLS, Storage, Edge Functions).
