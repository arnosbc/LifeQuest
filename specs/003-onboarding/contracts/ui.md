# Contrato: pantalla de Onboarding

Ruta `/onboarding`, pantalla completa, fuera de la barra inferior. Usa `context.lq` (sigue el tema). Arriba: «Paso n de 5» como texto + barra de progreso, botón «Atrás» (pasos 2–5) y «Saltar» (todos). Abajo: botón principal.

| Paso | Contenido | Botón principal |
|---|---|---|
| 1 Bienvenida | «Bienvenido a LifeQuest» · «Tu progreso real hace progresar a tu personaje.» · ciclo «Tarea → XP y Monedas → Nivel» | Empezar |
| 2 Identidad | «¿Quién eres en este reino?» · campo opcional, `maxLength` 280 con contador · ayuda «Puedes dejarlo para después.» | Continuar |
| 3 Primera skill | «¿Qué área de tu vida quieres hacer crecer?» · campo opcional, `maxLength` 40 · chips Salud, Estudio, Trabajo, Hogar, Creatividad, Relaciones (tocar rellena el campo) | Continuar |
| 4 Dificultad | 3 opciones (Fácil, Normal, Difícil), Normal preseleccionada. Cada una: «XP ×1,2 · Vida perdida ×0,75» con los valores del servidor · nota «Las Monedas son iguales en las tres.» · aviso «Después solo podrás cambiarla en Configuración.» | Continuar |
| 5 Listo | Resumen: identidad (o «Sin identidad por ahora»), skill (o «Sin skill por ahora»), dificultad | Entrar al reino |

## Estados

- **Cargando el estado:** indicador centrado con `Semantics(label: 'Preparando tu aventura')`.
- **Guardando:** botón principal y «Saltar» deshabilitados con indicador.
- **Error al guardar:** `SnackBar` con el mensaje del repositorio y acción «Reintentar»; «Saltar» sigue disponible.

## Mensajes (repositorio → `Failure`)

| Código | Mensaje |
|---|---|
| red | «Sin conexión. Revisa tu internet y vuelve a intentarlo.» |
| `onboarding_done` | se trata como éxito (ya estaba hecho): entra a Inicio |
| `skill_exists` | «Ya tienes una skill con ese nombre.» |
| `skill_limit_reached` | «Ya tienes el máximo de skills.» |
| check de longitud (23514) | «Usa una identidad de hasta 280 caracteres y una skill de hasta 40.» |
| otro | «No pudimos guardar tu aventura. Inténtalo de nuevo.» |

## Accesibilidad

- Opciones de dificultad y chips con `Semantics(selected: …)` y zona táctil ≥ 48 px.
- El color nunca va solo: la opción elegida lleva icono de check y texto.
