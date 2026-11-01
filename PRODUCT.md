# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
Cualquier persona que quiere ordenar su día desde el celular: tareas, hábitos y sesiones de concentración. La abre varias veces al día, en momentos cortos (al despertar, entre actividades, antes de dormir), con una mano y sin mucha paciencia.

## Product Purpose
Questly convierte lo que tienes en mente en un día que avanza: capturas, la app ordena, te avisa a tiempo y mide lo que hiciste. Éxito = el usuario termina más de lo que planea y vuelve al día siguiente sin sentir culpa.

## Positioning
Un asistente de productividad que actúa en tu día real (agenda, recordatorios con acción, tiempo medido, repetición) y no solo guarda listas; el progreso (XP, nivel, racha) es un reflejo ligero de lo cumplido, no un juego de fantasía.

## Operating Context
- Pestañas: Hoy · Tareas · Hábitos · Foco · Tú. Bandeja (captura rápida) desde un botón flotante.
- Foco = Pomodoro (ciclos 25/30/45 min con descansos), siempre en oscuro.
- Proyectos y metas (P.A.R.A.) cuelgan de Tareas; Áreas agrupan tareas y hábitos.
- Backend Supabase; la XP la calcula el servidor.

## Capabilities and Constraints
- Flutter, Clean Architecture (Bloc, get_it, go_router, fpdart). Android primero; iOS fuera por ahora.
- Textos de UI en español, tono de invitación, nunca culpa ni amenaza.
- Gratis: nada que pueda cobrar (solo capas gratuitas).
- Planeado (aún no hecho): agenda por horas, recordatorios con «Hecha / Posponer», repetición real, asistente que interpreta texto y arma el día, voz, calendario del teléfono, compartir a la app, widget.
- Abierto: el nombre del repo y del paquete siguen siendo LifeQuest; la marca visible pasa a **Questly**.

## Brand Commitments
- Nombre: **Questly** (decidido 2026-10-31).
- Sin ambientación de fantasía (nada de reino, héroe, mazmorra, jefes, monedas).

## Evidence on Hand
No hay usuarios reales, testimonios ni métricas. No inventarlos.

## Product Principles
1. Cada pantalla tiene una acción que cambia el día; nada solo informa.
2. Capturar cuesta un toque; ordenar lo hace la app.
3. El progreso se ve, pero nunca castiga.
4. Rápido de leer con una mano en 3 segundos.

## Accessibility & Inclusion
WCAG 2.1 AA: contraste 4,5:1, zonas táctiles ≥ 44 px, `Semantics` en botones de icono, el color nunca va solo, respetar reducción de movimiento.
