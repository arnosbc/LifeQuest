# Quickstart: Actualización del Perfil

## Probar el servidor en local

```sh
cd supabase/tests
npm install
npm test        # 001, 002, 003–007, 008 y 009
```

`009_profile_titles.test.mjs` comprueba:

1. 009 se aplica dos veces sobre 001–008 sin error.
2. `profile_overview` devuelve `treasury`, `active_title: null` y `titles: []` para un jugador nuevo, y conserva las claves de 002.
3. Con dos títulos ganados: `titles` los lista en orden de obtención; `set_active_title` los activa y `active_title` lo refleja; `set_active_title(null)` lo quita.
4. Un título no ganado (o inexistente) → `title_not_earned` y el activo no cambia; un `update profiles set active_title_id` directo también se rechaza.
5. Aislamiento: el otro jugador no ve los títulos ni el Tesoro del primero.
6. Borrar un título del catálogo deja al jugador sin título activo, sin error.
7. `anon` no puede llamar `set_active_title`.

## Probar la app

```sh
flutter test test/features/profile
flutter analyze
```

A mano (con 009 aplicada en Supabase):

1. Vida < 30 → aviso «25 % menos de XP… Tus Monedas no cambian.»; vida 30 → sin aviso.
2. Sembrar un título en `titles` y `user_titles` (SQL Editor, `service_role`) → «Elegir título» → elegirlo → aparece bajo el nombre; «Sin título» → desaparece.
3. Sin títulos → la hoja muestra el estado vacío.
4. Los 6 accesos: Diario, Marketplace y Configuración abren su pantalla; los otros tres muestran «… llegará pronto.».
5. Configuración → Apariencia → cambiar a oscuro → vuelve y se conserva al reiniciar.

## Aplicar en Supabase

1. Comprobar que 001–008 ya están aplicadas.
2. SQL Editor → pegar `supabase/migrations/009_profile_titles.sql` → ejecutar.
3. Reflejar en `Esquema_Base_de_Datos.md` la nueva forma de `profile_overview` y `set_active_title`, y actualizar RF-034 en `Requerimientos_Funcionales.md`.
