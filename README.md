# Questly

Questly es una app de productividad para Android. Capturas lo que tienes en mente y la app lo convierte en un día que avanza: lo pone en tu agenda, te avisa a tiempo, mide el tiempo que trabajas y te ayuda a cerrar lo pendiente. Lo que cumples suma XP, sube tu nivel y mantiene tu racha.

> El repositorio y el paquete se llaman **LifeQuest** (`proyecto_movil`); el nombre visible de la app es **Questly**.

**Descargar:** [última versión del APK](https://github.com/arnosbc/LifeQuest/releases/latest) · página de presentación en [`landing/`](landing/).

---

## Qué hace

La regla del proyecto: **cada función actúa en tu día real, no solo guarda texto.**

| Pestaña | Qué hace |
|---|---|
| **Hoy** | Arma tu día con tareas, eventos y hábitos y te dice qué toca ahora. Desde aquí replanificas lo atrasado. |
| **Tareas** | Escribes como hablas («llamar al médico el martes a las 10») y queda con fecha, hora y aviso. Una tarea grande se divide en pasos. Proyectos y metas cuelgan de aquí. |
| **Hábitos** | Se marcan en un toque, tienen recordatorio y llevan la racha. |
| **Foco** | Sesiones por ciclos (25, 30 o 45 min) con descansos sobre una tarea concreta. El tiempo real se suma a la tarea. |
| **Tú** | Nivel, XP, estadísticas, historial y ajustes. |

Además: **Bandeja** de captura rápida (botón flotante, voz o compartir desde otra app), notificaciones con botones «Hecha / Posponer», widget de inicio y recursos por tarea (enlaces, fotos, PDF y notas).

Referencia completa de funciones: [`docs/funcionalidades-questly.md`](docs/funcionalidades-questly.md).

---

## Cómo funciona

```
Flutter (Android)  ──RPC──►  Supabase (Postgres + RLS + Auth)
      │                            │
      │                            └── Edge Function `assistant` ──► Gemini (capa gratis)
      └── notificaciones locales, widget, calendario del teléfono
```

- **La app nunca escribe recompensas.** Completar una tarea, registrar un hábito o cerrar un ciclo de foco se hace con funciones Postgres `SECURITY DEFINER` llamadas por RPC (`complete_task`, `complete_habit`, `complete_dungeon_cycle`…). El servidor valida, calcula la XP y escribe el historial en una sola transacción.
- **Toda tabla con `user_id` tiene RLS** (`auth.uid() = user_id`): cada usuario solo ve lo suyo.
- **Lo determinista va por reglas** en Dart puro (`features/assistant/domain`: `DayPlanner`, `LocalParser`). La IA solo interpreta lenguaje (`parse` y `breakdown`), está apagada por defecto y tiene un tope diario por usuario. Solo se envía el texto escrito o el título.

### Stack

| Capa | Tecnología |
|---|---|
| App | Flutter / Dart 3, `flutter_bloc`, `get_it`, `go_router`, `fpdart`, `equatable` |
| Backend | Supabase: Auth, PostgREST, RLS, Storage, Edge Functions |
| IA | Gemini (Google AI Studio, capa gratis, sin facturación) |
| Sistema | `flutter_local_notifications`, `home_widget`, `shared_preferences` |
| Pruebas | `flutter_test`, `bloc_test`, `mocktail`; SQL con PGlite |
| Landing | Astro (estático) en Netlify |

### Estructura

```
lib/
├── app/            # router (go_router), shell, tema, composición entre features
├── core/           # errores, usecases base, widgets compartidos, tema Questly
├── features/<x>/   # una carpeta por función (tasks, habits, focus, home, assistant…)
│   ├── data/          # datasources (Supabase), models, repository impl
│   ├── domain/        # entities, repositorios abstractos, usecases (Dart puro)
│   └── presentation/  # blocs, screens, widgets
├── injection_container.dart   # registro de dependencias (get_it)
└── main.dart
test/               # refleja lib/
supabase/
├── schema.sql      # modelo de datos de referencia (v2)
├── migrations/     # 001…050, se aplican en orden
├── functions/assistant/   # Edge Function de la IA
└── tests/          # pruebas SQL de cada migración
landing/            # página de presentación (Astro)
docs/               # diseño, plan del rework, funcionalidades, seguridad
```

Reglas de arquitectura: `domain` no importa Flutter ni Supabase; `presentation` solo conoce `domain`; una feature no importa otra (lo compartido va a `core/`, la composición a `app/`). Detalle en [`CLAUDE.md`](CLAUDE.md) §8.

---

## Guía: poner el proyecto en marcha

### 1. Requisitos

- Flutter estable con Dart ≥ 3.12 (`flutter doctor` sin errores para Android).
- Android Studio o un celular Android con depuración USB.
- Node.js 22 (pruebas SQL y landing).
- Una cuenta de Supabase en el **plan gratis**.

### 2. Clonar e instalar

```bash
git clone https://github.com/arnosbc/LifeQuest.git
cd LifeQuest
git checkout Remaked
flutter pub get
```

### 3. Conectar con Supabase

1. Crea un proyecto en Supabase.
2. En el **SQL Editor** ejecuta primero `supabase/tests/deployed_v1.sql` (el esquema base: 31 tablas, enums y RLS) y después **cada archivo de `supabase/migrations/` en orden** (`001_home.sql` … `050_fix_create_habit.sql`). Es el mismo orden que usan las pruebas; cada migración depende de las anteriores. (`supabase/schema.sql` es el modelo de referencia documentado, no el punto de partida.)
3. Copia la configuración y rellénala con los datos de *Project Settings → API*:

   ```bash
   cp supabase.example.json supabase.json
   ```

   ```json
   {
     "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```

   `supabase.json` está en `.gitignore`: **no lo subas**. La app solo acepta URLs `https://`.

### 4. (Opcional) Activar la IA

La app funciona sin IA: el texto se interpreta con reglas locales. Para activar el asistente:

```bash
supabase functions deploy assistant
supabase secrets set GEMINI_API_KEY=tu_clave GEMINI_MODEL=nombre_del_modelo
```

`GEMINI_MODEL` es el nombre de un modelo de la capa gratis tal como aparece en AI Studio; se usa para entender frases. Opcional: `GEMINI_MODEL_PRO`, un modelo más potente para dividir en pasos, metas y repaso (sin él, todo usa `GEMINI_MODEL`).

Usa una clave de [Google AI Studio](https://aistudio.google.com/) **sin cuenta de facturación vinculada**: así, si se pasa del límite, falla en lugar de cobrar. Después, cada usuario la enciende en *Tú → Ajustes*.

### 5. Ejecutar

```bash
flutter run --dart-define-from-file=supabase.json
```

---

## Guía: pruebas

```bash
# App: usecases, repositorios y blocs
flutter test

# Base de datos: cada migración contra un Postgres real (PGlite)
cd supabase/tests
npm install
npm test

# Edge Function (necesita Deno)
deno test supabase/functions/assistant/
```

Las pruebas SQL comprueban comportamiento, no solo sintaxis: límites, unicidad, triggers y aislamiento de RLS entre dos usuarios.

---

## Guía: publicar una versión nueva

1. Sube la versión en `pubspec.yaml` (`version: X.Y.Z+N`).
2. Compila el APK:

   ```bash
   flutter build apk --release --dart-define-from-file=supabase.json
   ```

   Queda en `build/app/outputs/flutter-apk/app-release.apk`. Renómbralo `Questly-X.Y.Z.apk`.
3. En GitHub → **Releases → Draft a new release**: etiqueta `vX.Y.Z`, título `Questly X.Y.Z`, adjunta el APK y publica.
4. Actualiza `VERSION` y `APK_SIZE` al inicio de `landing/src/pages/index.astro` para que el botón de descarga apunte al nuevo APK.

Enlace directo para compartir: `https://github.com/arnosbc/LifeQuest/releases/download/vX.Y.Z/Questly-X.Y.Z.apk`.

---

## Guía: landing

```bash
cd landing
npm install
npm run dev       # http://localhost:4321
npm run build     # genera dist/
```

Se publica en **Netlify** (plan gratis, sin tarjeta) con *Base directory* `landing` y rama `Remaked`; el resto lo lee de `landing/netlify.toml`. Solo se recompila cuando un commit cambia `landing/`. Usa los colores y la fuente de la app (`docs/diseño/DESIGN.md`).

---

## Convenciones

- **Idioma:** documentación, comentarios de dominio y textos de UI en español; identificadores en inglés (`snake_case` en SQL).
- **Tono:** de invitación, nunca de culpa ni amenaza («Tu racha de 12 días te está esperando»).
- **Ramas:** el trabajo actual vive en `Remaked`.
- **Commits:** mensaje corto en español con la versión al final, p. ej. `Landing de Questly (v2.10.1)`. Sube la versión en cada commit y no uses `--amend`.
- **Base de datos:** todo cambio va en una migración nueva con su prueba en `supabase/tests`; nunca edites una migración ya aplicada.
- **Diseño:** antes de tocar UI, lee [`docs/diseño/DESIGN.md`](docs/diseño/DESIGN.md) (colores, tipografía Archivo, componentes) y cumple WCAG 2.1 AA.

## Documentación

| Documento | Para qué |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Contexto completo: reglas de negocio, arquitectura y decisiones |
| [`PRODUCT.md`](PRODUCT.md) | Usuario, propósito y principios de producto |
| [`docs/plan-rework.md`](docs/plan-rework.md) | Plan y estado del rework (fases 0–4) |
| [`docs/funcionalidades-questly.md`](docs/funcionalidades-questly.md) | Todas las funciones y cómo se conectan |
| [`docs/diseño/DESIGN.md`](docs/diseño/DESIGN.md) | Sistema visual «Calendario de taco» |
| [`docs/seguridad/`](docs/seguridad/) | Informe de seguridad |
| [`supabase/schema.sql`](supabase/schema.sql) | Modelo de datos |
