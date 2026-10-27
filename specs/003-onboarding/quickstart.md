# Quickstart: Onboarding

## SQL

```bash
cd supabase/tests
npm install
node 015_onboarding.test.mjs   # o npm test para todas
```

En Supabase: SQL Editor → ejecutar `supabase/migrations/015_onboarding.sql` (requiere 001–014).

## Flutter

```bash
flutter test test/features/onboarding
flutter analyze
```

## Prueba manual

1. Registrar una cuenta nueva e iniciar sesión → aparece «Paso 1 de 5».
2. Paso 2: escribir una identidad. Paso 3: tocar «Salud», editar a «Salud física». Paso 4: elegir Difícil. Paso 5: «Entrar al reino».
3. En Perfil: identidad y skill «Salud física» nivel 1. En Supabase: `game_master_settings.difficulty = 'hard'`, `profiles.onboarded_at` con fecha.
4. Cerrar sesión e iniciar de nuevo → va directo a Inicio.
5. Con otra cuenta nueva: escribir identidad en el paso 2 y «Saltar» → Inicio, identidad guardada, dificultad `normal`.
