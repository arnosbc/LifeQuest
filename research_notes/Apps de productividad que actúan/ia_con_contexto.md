# IA con contexto del usuario: documentos, plan de estudio y tareas (estado a 2026-11-07)

## 1. ¿Cómo dejan las apps que el usuario le dé contexto a la IA (temario, notas) y cómo lo usan para generar pasos o planes?

### Takeaway
Hay tres patrones: (1) **pegar/subir un documento una vez y extraer tareas** con revisión antes de guardar (Todoist, apps de temario como ProPlan Scholar); (2) **contexto persistente por espacio** (páginas, @-menciones, fuentes de un cuaderno) que la IA lee al responder (Notion AI, NotebookLM); (3) **descomposición sin contexto**, solo con el título y un nivel de detalle (Todoist Task Assist, TickTick, goblin.tools). Ninguna app de tareas revisada usa RAG visible para el usuario al partir una tarea; el contexto llega por selección explícita.

### Cited Findings
- **Todoist — captura desde texto, imágenes y documentos:** Quick Add acepta texto pegado de hasta 25.000 caracteres (correos, notas, viñetas); la captura de imágenes extrae tareas ya escritas en la foto; con documentos se pueden añadir instrucciones de qué extraer (p. ej. solo las acciones asignadas a mí). **Nada se añade hasta que el usuario confirma.** Solo planes Pro/Business, tope de 10 sesiones al mes; el límite de subida aparece como 7 MB en unas versiones regionales del artículo y 10 MB en otras (sin resolver) — [Todoist Help](https://www.todoist.com/help/articles/capture-tasks-from-text-images-and-documents-cAflh0WKe)
- **Todoist Assist** es el nombre paraguas de sus funciones de IA; incluye Task Assist (partir una tarea vaga en subtareas desde el menú de la tarea), Ramble (dictado a tareas) y la captura anterior — [Todoist Help: AI features](https://www.todoist.com/help/categories/todoist-and-ai/ai-features); [Todoist Assist](https://www.todoist.com/todoist-assist)
- Un artículo antiguo de Todoist describía «sugerir tareas para un proyecto» a partir de una meta escrita, revisando la lista y pulsando Añadir (con un backend GPT-3, probablemente desfasado) — [Todoist Help: AI Assistant](https://www.todoist.com/help/articles/use-the-ai)
- **Notion AI — contexto:** lee páginas del espacio a las que el usuario tiene acceso, conectores (Slack, Google Drive) para Enterprise Search, web (desactivable), selección manual con @-menciones y el campo «Specified context» en bloques de IA, y archivos subidos al chat. «Only uses information it has permission to see» — [Notion: What is Notion AI?](https://www.notion.com/help/notion-ai-faqs)
- **Notion Autofill (bases de datos):** rellena propiedades de filas existentes (resúmenes, extraer acciones); el Autofill básico usa **solo el contenido de esa fila/página**, no todo el espacio, y no navega la web. Notion AI no puede crear páginas en la base de datos por sí solo (según la ayuda) — [Notion: AI for databases](https://www.notion.com/help/autofill)
- **NotebookLM (ahora citado también como «Gemini Notebook»):** el usuario sube fuentes (PDF, webs, vídeos de YouTube, audio, Google Docs/Slides) a un cuaderno y la IA responde anclada a esas fuentes — [Google Help](https://support.google.com/notebooklm/answer/16164461)
- **TickTick:** su ficha de App Store anuncia un AI Assistant que «crea tareas, parte proyectos y organiza listas con una sola instrucción» — [App Store](https://apps.apple.com/app/626144601). Una guía no oficial dice que sugiere subtareas y que requiere Pro — [todoticked-support (no oficial)](https://todoticked-support.pages.dev/articles/ai-assistant)
- **goblin.tools Magic ToDo:** parte una tarea en pasos con un control de «picante» (1–5 chiles) que indica cuánta ayuda/detalle se quiere; más chiles = más pasos. No usa documentos — [Laura Yost (Substack)](https://laurayost.substack.com/p/goblin-tools-improving-accessibility); [App Store](https://apps.apple.com/au/app/goblin-tools/id6449003064)
- **Planificadores de estudio con temario:** ProPlan Scholar (iOS) extrae cursos, profesores, horarios y cada entrega/examen con fecha de un PDF, Word o foto del temario — [App Store](https://apps.apple.com/au/app/id6777539187). «Study Planner: Syllabus AI» toma un PDF de texto o texto plano, deja **revisar** los cursos y fechas detectados y luego muestra lo de hoy — [App Store](https://apps.apple.com/us/app/-/id6766181202). Taskade tiene un convertidor temario → plan de estudio — [Taskade](https://www.taskade.com/convert/education/academic-syllabus-to-study-plan); [Taskade: 11 AI study planners 2026](https://www.taskade.com/blog/ai-study-planners.md)
- Roundup 2026 de planificadores escolares con IA (fuente de proveedor, MyStudyLife) — [MyStudyLife](https://mystudylife.com/best-ai-school-planner-apps-for-students-in-2026-free-paid/)

### Inferences
- El patrón común y fiable es **extraer → mostrar borrador → confirmar**. Encaja con el `CaptureBloc`/borrador que ya tiene Questly.
- El contexto que mejora el «partir en pasos» es pequeño y elegido: el temario de una materia, no toda la vida del usuario. Notion lo hace explícito con «Specified context»; Notion Autofill se limita a la fila.

### Gaps
- No verifiqué Motion AI, Knowt, StudySmarter ni los planes de estudio de Quizlet (las búsquedas no devolvieron páginas primarias). No los cites sin revisar.
- No verifiqué si Todoist Task Assist usa la descripción del proyecto como contexto.

## 2. ¿Qué UX de consentimiento y privacidad muestran?

### Takeaway
Los grandes declaran «no entrenamos con tus datos» (Notion para feedback y con toggle de admin; NotebookLM salvo que des feedback) y dan controles a nivel de espacio. Las apps de tareas pequeñas (TickTick, goblin.tools) no publican detalles claros de qué va al proveedor del modelo. El consentimiento visible más común es implícito: el usuario pulsa el botón de IA y revisa el resultado antes de guardarlo.

### Cited Findings
- Notion: «Your feedback isn't used to train Notion AI»; el propietario del espacio tiene un toggle para compartir datos con Notion para mejorar la IA, puede elegir proveedores/modelos permitidos, apagar la búsqueda web o exigir confirmación antes de visitar sitios externos, y limitar créditos por miembro — [Notion FAQ](https://www.notion.com/help/notion-ai-faqs)
- NotebookLM: «Your data is protected, and is not used to train Gemini Notebook unless you provide feedback»; si das feedback, «we may review the full context of that interaction, including your queries, uploads, and the model's responses». En cuentas Workspace/Education no hay revisión humana ni entrenamiento — [Google Help](https://support.google.com/notebooklm/answer/16164461). Universidades avisan que una cuenta Google personal no tiene las mismas protecciones — [UMN IT](https://it.umn.edu/services-technologies/notebooklm)
- Todoist: la captura no guarda nada hasta que el usuario confirma (control humano del resultado) — [Todoist Help](https://www.todoist.com/help/articles/capture-tasks-from-text-images-and-documents-cAflh0WKe). La página de IA no resume política de entrenamiento ni proveedores — [Todoist Help: AI features](https://www.todoist.com/help/categories/todoist-and-ai/ai-features)
- TickTick: la etiqueta de privacidad de App Store no menciona tratamiento específico de IA — [App Store](https://apps.apple.com/app/626144601)
- goblin.tools: la ficha de App Store declara datos de uso y diagnóstico no vinculados a la identidad; la sincronización se describe como cifrada en el dispositivo; no encontré qué proveedor de IA usa — [App Store](https://apps.apple.com/za/app/id6449003064)

### Inferences
- Para Questly, con Gemini gratis (que **sí** entrena, ver §3), una UX honesta debe ser más explícita que la de estas apps: aviso al activar la IA, aviso al guardar un contexto, y opción de usar solo reglas. Ya existe `game_master_settings.ai_enabled` apagado por defecto.

### Gaps
- No leí las políticas de privacidad completas de TickTick, Todoist ni Notion (página «Notion AI security & privacy practices»); no afirmes zero-retention ni subprocesadores.

## 3. Límites y condiciones de uso de datos del free tier de la Gemini API (texto y PDF, 2026)

### Takeaway
Gratis hay muchos modelos Flash/Flash-Lite, PDF hasta 50 MB o 1000 páginas a 258 tokens/página, Files API gratis con 48 h de almacenamiento. **Pero en el nivel gratis Google usa lo que envías para mejorar sus productos y puede haber revisores humanos; prohíbe enviar información sensible, confidencial o personal; exige 18+; y para usuarios del EEE/Suiza/RU solo se permiten servicios de pago.** Los límites RPM/RPD ya no se publican en la doc; se ven en AI Studio por proyecto.

### Cited Findings
- Precios: el free tier dice «Content used to improve our products»; el paid tier «Content not used to improve our products». Modelos gratis listados hoy incluyen Gemini 3.8 Flash, 3.6 Flash, 3.5 Flash-Lite, 3.1 Flash-Lite, 3 Flash Preview, 2.5 Pro/Flash/Flash-Lite, Gemini Embedding y Gemma 4; no gratis: Gemini 4 Argon, 3.1 Pro Preview, modelos de imagen, entre otros — [Gemini pricing](https://aistudio.google.com/docs/pricing) (ai.google.dev ahora redirige a aistudio.google.com/docs)
- Términos, Unpaid Services: «Google uses the content you submit … to provide, improve, and develop» productos y tecnologías de ML; «human reviewers may read, annotate, and process your API input and output» (desvinculado de la cuenta); **«Do not submit sensitive, confidential, or personal information to the Unpaid Services.»** — [Gemini API Terms](https://aistudio.google.com/docs/terms)
- Términos, Paid Services: no usa prompts/respuestas para mejorar productos; registra por tiempo limitado solo para detectar abusos — [Gemini API Terms](https://aistudio.google.com/docs/terms)
- EEE, Suiza y RU: «You may use only Paid Services when making API Clients available to users in the European Economic Area», Suiza y RU — [Gemini API Terms](https://aistudio.google.com/docs/terms)
- Edad: «You must be 18 years of age or older to use the APIs»; no se permiten API Clients dirigidos o probablemente usados por menores de 18 — [Gemini API Terms](https://aistudio.google.com/docs/terms)
- PDF: hasta 1000 páginas o 50 MB (inline y Files API); 258 tokens por página; también Word, PowerPoint, Excel, ODF; TXT/Markdown/HTML se procesan como texto plano. Files API: archivos guardados 48 h, sin coste — [Document processing](https://aistudio.google.com/docs/document-processing)
- Rate limits: la doc ya no lista RPM/TPM/RPD del free tier por modelo; «View your active rate limits in AI Studio». Límites por proyecto (no por clave), RPD se reinicia a medianoche del Pacífico, «not guaranteed» — [Rate limits](https://aistudio.google.com/docs/rate-limits)

### Inferences
- 258 tokens/página: un temario de 10 páginas ≈ 2.600 tokens; cabe sin problema en un prompt junto al título de la tarea. No hace falta RAG para esto.
- El free tier es incompatible con «documentos personales» si se lee literal la cláusula de información personal: un temario de curso público es aceptable; notas personales, nombres, salud o trabajo confidencial no. Esto debe decirse en la UI.
- Si Questly tuviera usuarios en el EEE/RU, el free tier no sería legal para ellos. Y el requisito 18+ importa si la app apunta a estudiantes de colegio.

### Gaps
- No verifiqué la ventana de contexto exacta de los modelos actuales (3.x); históricamente los Flash tenían 1M tokens de entrada (dato de entrenamiento, **sin confirmar para 2026**).
- No obtuve cifras RPM/RPD del free tier: solo visibles en AI Studio con cuenta.
- Los nombres de modelos (3.8 Flash, 4 Argon…) vienen de la página de precios leída hoy; cambian a menudo, conviene que `GEMINI_MODEL` siga siendo un secret configurable.

## 4. ¿Cuál es el diseño más simple y fiable para «usa mi plan de estudio al partir una tarea en pasos»?

### Takeaway
Guardar **un texto de contexto por Área** (pegado por el usuario, recortado a un tope, p. ej. ~8–10k caracteres) y, al pulsar «Partir en pasos» en una tarea con esa Área, mandar a la Edge Function `breakdown` el título + ese texto. Sin embeddings, sin vectores, sin subir PDFs al proveedor. Mostrar borrador y confirmar. RAG solo tendría sentido con muchos documentos largos por Área, que no es el caso.

### Cited Findings
- Patrón de contexto acotado y explícito: Notion Autofill usa solo el contenido de la fila/página y Notion AI deja fijar «Specified context» con @-menciones — [Notion Autofill](https://www.notion.com/help/autofill); [Notion FAQ](https://www.notion.com/help/notion-ai-faqs)
- Patrón borrador → confirmar: Todoist no añade nada hasta que el usuario confirma; Syllabus AI deja revisar cursos y fechas detectados — [Todoist Help](https://www.todoist.com/help/articles/capture-tasks-from-text-images-and-documents-cAflh0WKe); [App Store](https://apps.apple.com/us/app/-/id6766181202)
- Tope de texto como límite práctico: Todoist limita el pegado a 25.000 caracteres — [Todoist Help](https://www.todoist.com/help/articles/capture-tasks-from-text-images-and-documents-cAflh0WKe)
- El coste en tokens de un documento es predecible (258 tokens/página PDF), y la Files API caduca a las 48 h, así que no sirve como almacén permanente del contexto — [Document processing](https://aistudio.google.com/docs/document-processing)

### Inferences
- Diseño propuesto para Questly (encaja con lo que ya existe: `skills` = Áreas, Edge Function `assistant` con `breakdown`, `ai_enabled`, `consume_ai_call`):
  1. Columna de texto en `skills` (p. ej. `context_note text` con `check (char_length(...) <= 10000)`), RLS ya cubierta por la tabla. Nada de tabla nueva ni de Storage.
  2. UI en la ficha del Área: campo «Plan o temario (opcional)» con aviso fijo: «Si usas la IA, este texto se envía a Google Gemini (capa gratis), que puede usarlo para mejorar sus productos. No pegues datos personales.»
  3. `breakdown` recibe `task_title` + `area_context` (lo lee la Edge Function desde la BD con el JWT del usuario, no lo manda el cliente) y pide JSON de pasos con fechas.
  4. Sin IA (o si falla): `LocalParser`/reglas parten en pasos genéricos; el contexto no sale del teléfono.
  5. PDF: si se quiere, extraer texto en el dispositivo y pegarlo en el campo; evitar subir el PDF a Gemini (más datos, 48 h en Files API, más superficie de privacidad).
- RAG (embeddings + pgvector + recuperación por similitud) añade tablas, jobs de indexado y otra llamada de embeddings, para un problema que cabe en un prompt. Solo vale si el contexto por Área supera de forma habitual el tope de tokens.

### Gaps
- No medí la calidad de los pasos de Gemini con y sin contexto; sería una prueba manual con 3–4 temarios reales.
- No verifiqué si existe un paquete Flutter mantenido para extraer texto de PDF en el dispositivo sin coste (p. ej. `syncfusion_flutter_pdf` tiene licencia comunitaria con condiciones).
