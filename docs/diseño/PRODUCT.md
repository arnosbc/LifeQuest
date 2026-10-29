# PRODUCT.md — Questly

## Qué es
Questly es una app móvil de productividad gamificada (RPG). Convierte tareas, hábitos, proyectos y metas reales en misiones, y el progreso real del usuario hace progresar a su personaje.

> «Convierte tus objetivos y responsabilidades diarias en una aventura donde tu progreso en la vida real hace progresar a tu personaje.»

## Para quién
Personas (estudiantes y jóvenes profesionales) que saben qué hacer pero les cuesta empezar. Les afectan:

- la brecha entre intención y acción;
- la falta de feedback inmediato;
- la fatiga de decisión;
- el pensamiento todo-o-nada.

## Principios
1. **Calma primero:** poca información por pantalla y una acción principal clara.
2. **Aventura con medida:** el lenguaje y las ilustraciones RPG motivan, pero nunca restan claridad.
3. **Sin culpa:** perder vida o una racha siempre tiene una salida. No hay muerte del personaje ni pérdida de nivel.
4. **Ético:** ninguna mecánica existe solo para retener al usuario. Sin patrones oscuros.
5. **Accesible:** WCAG 2.1 AA y zonas táctiles de 44 px.

## Estructura
- **Navegación de 5 pestañas:** Inicio · Stage (P.A.R.A.: Hoy, Calendario, Biblioteca) · Hábitos · Mazmorra (Deep Working) · Perfil.
- **Desde Inicio:** Avisos, Misión actual de RPGenie, Taverna (NPCs), Brain Dump y Boss Fight.
- **Desde Perfil:** Estadísticas, Vision Board, Inventario y logros, Marketplace, Diario (Bitácora) y Configuración.
- **Antes de entrar:** Iniciar sesión / Registro / Recuperar contraseña y Onboarding de 5 pasos.

## Reglas clave
- **XP y nivel:**
  - la XP mide el progreso y nunca se gasta;
  - XP para subir de nivel: 100 × nivel^1,5;
  - las skills son las Áreas de P.A.R.A.
- **Tareas:**
  - sin tiempo estimado ni dificultad elegida por el usuario;
  - **RPGenie calcula la XP** (10–40);
  - se pueden vincular a un Proyecto o a una Meta.
- **Metas:**
  - son metas S.M.A.R.T. que se muestran como un jefe;
  - cada tarea o proyecto vinculado le quita vida.
- **Monedas (economía estable):**
  - 30 % de la XP;
  - tope diario suave de 50 + 25;
  - bolsa de 400 + 25 por nivel (máximo 1.000), con el exceso al Tesoro del reino;
  - precios fijos (Siesta 30, Posada 70, Banquete 150, Elixir 40, Cofre 60, Pase 90, Recuperar racha 150);
  - Refugio a 120 × 1,35ⁿ.
- **Vida (HP):**
  - pérdidas: malo −3/−5/−8, plazo vencido −5, día perdido −5;
  - +4 al día con un hábito bueno;
  - por debajo de 30 queda debilitado (−25 % de XP).
- **Dificultad:**
  - solo se cambia en Configuración;
  - XP ×1,2 / ×1 / ×0,85;
  - vida perdida ×0,75 / ×1 / ×1,25;
  - las Monedas no cambian.

Detalle completo: `docs/ideas-proyecto-productividad-gamificada.md`.

## Stack previsto
Flutter/Dart (frontend), con Supabase o Firebase como backend.
