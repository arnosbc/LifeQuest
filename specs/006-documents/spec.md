# Feature Specification: Taller de documentos (fase 1)

**Feature Branch**: `006-documents`

**Created**: 2026-10-31

**Status**: In progress

**Input**: User description: "Integrar una zona de elaboración de tareas o trabajos de cualquier tipo (programación, texto) donde se pueda editar, usar plantillas y cuadrículas, y entregar descargando en Word o PDF. Los documentos se guardan en el teléfono y en la nube."

## Contexto

LifeQuest ya convierte el trabajo real en misiones, pero el trabajo en sí (un ensayo, un informe, un ejercicio de programación) se hace fuera de la app. El Taller cierra ese ciclo: la tarea se redacta dentro, se entrega exportada y la tarea se completa en Foco como siempre.

No es un procesador de textos completo: es el lugar donde se hace la entrega de una tarea.

## Decisiones

- **Formato interno: Markdown.** Admite títulos, negrita, cursiva, listas, citas, tablas («cuadrículas») y bloques de código. Una barra de herramientas inserta la sintaxis; la vista previa lo muestra formateado.
- **Guardado doble:** cada cambio se guarda al instante en el teléfono (funciona sin internet) y se sincroniza con Supabase cuando hay conexión. Conflictos: gana la versión con `updated_at` más reciente. Borrar deja una marca (`deleted_at`) para que el borrado también se sincronice.
- **Exportación:** PDF (fiel a la vista previa) y Word `.docx` (títulos, párrafos con negrita/cursiva, listas, citas, tablas y código). Se comparte con la hoja del sistema (WhatsApp, correo, Drive, Archivos).
- **Vínculo con tareas:** un documento puede pertenecer a una tarea (`task_id`). Desde la tarea guiada se abre o se crea su documento.

## Requerimientos funcionales (propuestos para el documento de RF)

- **RF-117** El usuario puede crear un documento en blanco o desde una plantilla (ensayo, informe con portada, carta, trabajo de programación, apuntes).
- **RF-118** El usuario puede editar el documento con títulos, negrita, cursiva, listas, citas, tablas y bloques de código, y ver la vista previa formateada.
- **RF-119** Cada cambio se guarda en el dispositivo sin conexión y se sincroniza con la nube; el documento se puede abrir desde otro dispositivo de la misma cuenta.
- **RF-120** El usuario puede exportar el documento a PDF y a Word (.docx) y compartirlo.
- **RF-121** Un documento puede vincularse a una tarea; desde la tarea se abre su documento.
- **RF-122** El usuario puede renombrar y borrar documentos; el borrado se sincroniza.

## Fase 2 (2026-10-31)

- **Colores en el código** según el lenguaje del bloque (```dart, ```python…), igual en la vista previa, el PDF y el Word (paquete `highlight`).
- **Contador de palabras** junto al estado de guardado.
- **Historial de versiones** en el teléfono: una copia al abrir y otra al cerrar el editor si cambió (máx. 30). Restaurar guarda antes la versión actual. No se sincroniza.
- **Imágenes** (`047_document_images.sql`): se insertan desde la galería como `![Imagen](img/archivo)`; se guardan en el teléfono y en el bucket privado `documents` (`<user_id>/<documento>/<archivo>`). Sin red quedan pendientes y suben al sincronizar; en otro dispositivo se descargan al verlas. Salen en la vista previa, el PDF y el Word (WebP no se incrusta en Word).
- **RF-123** propuesto: el usuario puede insertar imágenes y restaurar una versión anterior del documento.

## Fuera de alcance

Ayuda del Asistente para el esquema (choca con la decisión de usar IA solo en el título de la misión de NPC, CLAUDE.md §3) y edición colaborativa.

## Criterios de aceptación

1. Sin internet, crear y editar un documento funciona y no pierde nada al cerrar la app.
2. Al volver la conexión, el documento aparece en la nube (tabla `documents`) y en otro dispositivo de la misma cuenta.
3. El PDF y el .docx exportados contienen títulos, listas, tablas y código del documento.
4. Desde una tarea guiada, «Documento» abre el documento de esa tarea (o lo crea con el título de la tarea).
