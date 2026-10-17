# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
Una sola persona que quiere cerrar la brecha entre intención y acción en su vida real: tareas grandes sin punto de entrada, falta de feedback inmediato, fatiga de decisión al organizar pendientes y el pensamiento todo-o-nada cuando rompe una racha. Usa la app a diario, en el móvil, para capturar, decidir qué hacer ahora, concentrarse y ver su progreso. No hay modo cooperativo, gremios ni rankings.

## Product Purpose
LifeQuest convierte tareas, hábitos, proyectos y metas reales en misiones de un RPG: el progreso real del usuario hace progresar a su personaje. El éxito es que el usuario actúe más y con menos fricción, no que abra más la app.

Ciclo principal: Vision Board → Brain Dump / Quick Add → Diagnóstico (G.T.D. o S.M.A.R.T.) → Meta → Proyecto → Tarea / Misión → Mazmorra (concentración) → XP + Monedas → Nivel / Skill → Marketplace → siguiente misión.

## Positioning
No es una lista de tareas con puntos encima: integra métodos de productividad reales (G.T.D., P.A.R.A., S.M.A.R.T., Pomodoro) dentro de un motor RPG coherente donde cada acción real termina en XP, Monedas, HP y nivel de una skill definida por el propio usuario. Diseño ético por principio: sin dark patterns, el HP nunca "mata" ni borra progreso, y las recompensas aleatorias son solo cosméticas.

## Operating Context
- Uso móvil frecuente y breve (captura, revisar la Misión actual, registrar hábitos) más sesiones largas de Deep Working, donde la UI debe desaparecer: sin navegación extra ni ruido.
- El Brain Dump se abre desde cualquier pantalla con mínima fricción (Modelo de Fogg).
- Menú de 9 secciones (RF-114): Perfil, RPGenie, Stage · P.A.R.A., Diario, Hábitos, Mazmorras / Deep Working, Objetivos, Taverna, Marketplace.
- Stage · P.A.R.A., Diario y Daily Highlight son pantallas de lectura sobre datos de otros módulos.

## Capabilities and Constraints
- Stack: Flutter / Dart (Material 3, Riverpod) sobre Supabase (Postgres, Auth, RLS, RPC, Edge Functions). Android primero; iOS corre la misma UI sin adaptarla.
- Textos de UI en español; identificadores de código en inglés.
- Economía dual: XP (nunca se gasta) y Monedas (se gastan); gastar nunca debe sentirse como perder avance. HP agregado con estado "debilitado" (≤ 20 %) que nunca bloquea acciones.
- Un único estado real de objetivos (`not_started | in_progress | completed | expired`); las "pieles" (Éxito/Fracaso, "¡Hazlo ahora!") son solo de UI.
- Única escala de urgencia: high 🔴 / medium 🟡 / low 🟢.
- Notificaciones en tres niveles (critical / motivational / informational) con tono de invitación, nunca de amenaza ni culpa.
- Terminología del juego y su entidad: ver `CLAUDE.md` §4. Comportamiento: `Requerimientos_Funcionales.md` (RF-001…RF-116).
- Fuera de alcance: Financial Vault, personalización visual completa (avatar, ropa, temas, marcos), cooperativo/rankings, autorecompensas de texto libre.
- Abierto: valores numéricos de la economía, catálogo de la Tienda, tipo de misión (RF-050), cálculo del daño al Boss.

## Brand Commitments
- Nombre **provisional**: LifeQuest (proyecto), Questly o LevelUp. No fijar el nombre en assets definitivos.
- Voz **provisional**. Lo único ya fijado: tono de invitación, nunca de amenaza ni culpa (✅ "Tu racha de 12 días te está esperando 🔥"; ❌ "¡Vas a perder tu racha!").

## Evidence on Hand
- Documentación de diseño en el Project de claude.ai "LifeQuest": `schema.sql` v2, Requerimientos Funcionales, Casos de Uso, Esquema de BD.
- No hay usuarios, testimonios, métricas ni arte propio. No inventarlos.

## Product Principles
1. Ético primero: cada mecánica refuerza comportamiento productivo real; prohibidos los dark patterns.
2. Progreso que no se pierde: penalizaciones graduales, nunca punitivas de golpe; el HP nunca mata ni borra avance.
3. Autonomía: el usuario define sus skills, su Tienda (dentro del catálogo), su dificultad y sus notificaciones.
4. Mínima fricción para actuar: capturar y empezar la siguiente misión debe costar casi nada.
5. Invitar, no presionar: el sistema anima, nunca culpa.

## Accessibility & Inclusion
- WCAG 2.1 AA: contraste, objetivos táctiles y lector de pantalla (TalkBack).
- Diseño apto para neurodivergencia / TDAH: baja carga cognitiva, poco ruido visual, una acción clara por pantalla, sin urgencia artificial ni presión.
