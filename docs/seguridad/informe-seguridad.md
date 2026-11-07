# Informe de seguridad — Questly (LifeQuest)

**Materia:** Programación Móvil · **Profesor:** Alex Vacca · **Entrega:** 16 de noviembre de 2026
**Proyecto:** Questly, app Flutter (Android primero) con Supabase (Auth, PostgREST, RLS, Edge Functions) y Gemini en una Edge Function.
**Referencia:** OWASP Mobile Top 10 (2024), MASVS y MASTG.

> Regla base que sigue el proyecto: el teléfono y la app instalada no son de confianza; toda decisión importante (XP, completar, permisos) la valida el servidor.

---

## Fase 1 · Modelo de amenazas

### Diagrama de la app

```
┌──────────────────────── Teléfono (no confiable) ────────────────────────┐
│  App Flutter                                                            │
│   Pantallas: Hoy · Tareas · Hábitos · Foco · Tú · Crear · Bandeja        │
│   Almacenamiento local:                                                 │
│     · Sesión Supabase (access + refresh token) ── flutter_secure_storage│
│     · Tema / ajustes visuales ─────────────────── SharedPreferences     │
│     · Avisos programados ─────────────────────── flutter_local_notif.   │
│   Entradas del sistema:                                                 │
│     · Widget de inicio (broadcast «done?id=…»)                          │
│     · Compartir a Questly (intent SEND text/*)                          │
│     · Botones de notificación (Hecha / Posponer / Hecho)                │
│     · Micrófono (dictado del sistema) · Calendario (solo lectura local) │
└──────────────┬──────────────────────────────────────────────────────────┘
               │ HTTPS (TLS) · JWT del usuario
┌──────────────▼──────────────── Supabase ────────────────────────────────┐
│  Auth (email + contraseña)                                              │
│  PostgREST → RPC SECURITY DEFINER (complete_task, complete_habit…)      │
│  Tablas con RLS «auth.uid() = user_id»                                  │
│  Edge Function «assistant» ── HTTPS ──► Gemini API (capa gratis)        │
│     · comprueba el JWT y el tope diario (consume_ai_call)               │
│     · GEMINI_API_KEY solo en los secrets del servidor                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Datos sensibles

| Dato | Dónde vive | Por qué importa |
|---|---|---|
| Correo y contraseña | Solo en Supabase Auth (la app no la guarda) | Acceso a la cuenta |
| Access y refresh token | Teléfono (almacén cifrado) | Quien lo copie entra como el usuario sin contraseña |
| Tareas, hábitos, metas, notas de la Bandeja | Supabase (RLS) y en memoria | Información personal del día a día |
| Eventos del calendario | Solo se leen en el teléfono; no se suben | Agenda privada |
| Texto enviado a la IA | Edge Function → Gemini | La capa gratis de Gemini puede usarlo para mejorar sus productos |
| Clave publicable de Supabase | Compilada en la app | Pública por diseño; la protección real es el RLS |
| GEMINI_API_KEY | Secrets de Supabase | Si se filtra, otros gastan la cuota |

### Amenazas reales de Questly

| # | Amenaza | Quién | Por dónde | Riesgo OWASP | Control |
|---|---|---|---|---|---|
| A1 | Robar la sesión y entrar a la cuenta sin contraseña | Alguien con el teléfono un momento (adb, copia de seguridad) o malware con root | Token en texto plano en SharedPreferences; copias de seguridad de Android | M9 | H-01, H-02 |
| A2 | Otra app del teléfono completa tareas ajenas o envía datos raros | App maliciosa instalada | Receiver exportado del widget, intent de compartir | M8, M4 | H-03, H-04 |
| A3 | Usuario que se da XP de más o lee datos de otro | Usuario autenticado que modifica la app o llama la API directo | PostgREST / RPC | M3 | RLS + RPC `SECURITY DEFINER` (003–008), ya cumple |
| A4 | Leer o cambiar el tráfico en una wifi pública | Atacante en la red | HTTP en claro o CA instalada por el usuario | M5 | H-06 |
| A5 | Sacar llaves o lógica del APK | Cualquiera que descargue el APK | Ingeniería inversa | M1, M7 | Sin secretos en el APK; H-07; firma propia H-08 |

---

## Fase 2 · Auditoría OWASP Mobile Top 10 (2024)

Técnicas usadas (mínimo dos):
1. **Buscar secretos en el código y en el historial de Git:** `git log --all -p` filtrado por patrones de llaves (`sb_secret_`, `service_role`, `AIza…`, `GEMINI_API_KEY=`). Mismo objetivo que gitleaks.
2. **Revisar `AndroidManifest.xml`, `build.gradle.kts` y los permisos.**
3. **Revisar dependencias:** `flutter pub outdated`.
4. **Revisar el código de almacenamiento y logs** (cómo guarda la sesión `supabase_flutter`, `debugPrint` en release).

| ID | Riesgo | Estado | Justificación |
|---|---|---|---|
| M1 | Improper Credential Usage | **Cumple** | No hay secretos en el código ni en el historial de Git (búsqueda sin coincidencias). `supabase.json` está en `.gitignore`. La clave publicable es pública por diseño; la de Gemini vive solo en los secrets de la Edge Function. |
| M2 | Inadequate Supply Chain Security | **Cumple (con mantenimiento)** | `flutter pub outdated`: sin avisos de vulnerabilidad; quedan versiones menores atrasadas (`go_router` 18.1.0 → 18.1.3, `flutter_local_notifications` 22 → 23 con cambios mayores). `pubspec.lock` versionado. |
| M3 | Insecure Authentication/Authorization | **Cumple** | RLS `auth.uid() = user_id` en toda tabla con usuario; XP, completar y comprar solo por RPC `SECURITY DEFINER` que validan dueño y estado; la Edge Function valida el JWT y el tope de IA. Probado con dos usuarios en `supabase/tests`. |
| M4 | Insufficient Input/Output Validation | **No cumple** | El widget de inicio usaba el `id` del intent sin validarlo (H-04). Lo demás valida: el texto compartido se corta a 500 caracteres, las RPC validan longitudes y fechas, la Edge Function limpia la respuesta de la IA (`sanitize.ts`). |
| M5 | Insecure Communication | **Cumple (mejorado)** | Supabase y Gemini van por HTTPS. No había configuración de red explícita ni comprobación del esquema de la URL (H-06). Sin certificate pinning (mejora opcional). |
| M6 | Inadequate Privacy Controls | **Cumple parcialmente** | El calendario se lee solo en el teléfono; los permisos se piden al usarse; la IA viene apagada y avisa antes de enviar texto. Pendiente: Gemini capa gratis exige usuarios mayores de 18 años y puede usar el texto; no se corrige en código, queda documentado. |
| M7 | Insufficient Binary Protections | **No cumple** | `build.gradle.kts` no declaraba R8 y el Dart no se ofuscaba al compilar (H-07). |
| M8 | Security Misconfiguration | **No cumple** | Receiver del widget `exported="true"` (H-03); release firmado con la llave de debug (H-08); `applicationId` `com.example…` (pendiente antes de publicar). |
| M9 | Insecure Data Storage | **No cumple** | Sesión (access + refresh token) en SharedPreferences en texto plano (H-01); copias de seguridad de Android activas (H-02); un `debugPrint` de errores salía también en release (H-05). |
| M10 | Insufficient Cryptography | **No aplica / Cumple** | La app no implementa criptografía propia. Tras H-01 la sesión se cifra con `flutter_secure_storage` (llave en Android Keystore / Keychain), sin `EncryptedSharedPreferences` (obsoleta). |

### Hallazgos

| ID | Riesgo OWASP | Descripción | Evidencia | Severidad | Corrección propuesta |
|---|---|---|---|---|---|
| H-01 | M9 | La sesión de Supabase (access y refresh token) se guardaba en SharedPreferences sin cifrar: `supabase_flutter` usa `SharedPreferencesLocalStorage` por defecto. | `supabase_flutter-2.18.3/lib/src/supabase.dart:137-143` crea `SharedPreferencesLocalStorage(persistSessionKey: "sb-…-auth-token")`; en el teléfono: `adb shell run-as com.example.proyecto_movil cat shared_prefs/FlutterSharedPreferences.xml` muestra la clave `sb-…-auth-token` con el JWT. | **Alta** | Guardar la sesión con `flutter_secure_storage` (llave en Keystore) y migrar la sesión vieja. |
| H-02 | M9 / M8 | `android:allowBackup` no estaba declarado (por defecto `true`): la copia de seguridad de Android podía llevarse los datos de la app. | `AndroidManifest.xml` sin `allowBackup` ni reglas de extracción. | **Media** | `allowBackup="false"`, `fullBackupContent="false"` y `data_extraction_rules.xml` que excluye todo. |
| H-03 | M8 | `HomeWidgetBackgroundReceiver` estaba `exported="true"`: cualquier app podía enviarle un broadcast y completar una tarea. | `AndroidManifest.xml`, receiver `es.antonborri.home_widget.HomeWidgetBackgroundReceiver`. | **Media** | `exported="false"`: el widget lo llama con un `PendingIntent` explícito de la propia app. |
| H-04 | M4 | El callback del widget usaba el `id` de la URI sin validar. | `lib/app/home_widget_sync.dart` (`onWidgetAction`). | **Baja** | Aceptar solo ids con forma de UUID antes de arrancar Supabase. |
| H-05 | M9 | `guardSupabase` imprimía el error y la pila con `debugPrint` también en release (visible en `adb logcat`). | `lib/core/errors/supabase_guard.dart:60`. | **Baja** | Imprimir solo con `kDebugMode`. |
| H-06 | M5 | Sin `network_security_config` explícito ni comprobación de que la URL del backend sea HTTPS. | `AndroidManifest.xml`; `lib/app/config/constants.dart`. | **Baja (preventiva)** | Config de red sin tráfico en claro y solo CAs del sistema; la app no arranca si `SUPABASE_URL` no es `https://`. |
| H-07 | M7 | Release sin R8 declarado ni ofuscación del código Dart. | `android/app/build.gradle.kts` sin `isMinifyEnabled`; compilación sin `--obfuscate`. | **Media** | `isMinifyEnabled = true`, `isShrinkResources = true` y compilar con `--obfuscate --split-debug-info`. |
| H-08 | M8 | El build de release se firmaba con la llave de debug (pública y compartida). | `build.gradle.kts`: `signingConfig = signingConfigs.getByName("debug")`. | **Alta** | Firma de release desde `android/key.properties` (fuera de Git); si falta, Gradle avisa. |

---

## Fase 3 · Corrección

Se corrigieron los 8 hallazgos (mínimo pedido: 5), empezando por los de mayor severidad. Mejoras obligatorias:

- [x] **Ningún secreto en el código ni en el repositorio:** ya se cumplía (M1); además `.gitignore` excluye `android/key.properties`, `*.jks` y `*.keystore` (H-08).
- [x] **Tokens y datos sensibles con Keystore:** H-01 (`lib/core/storage/secure_session_storage.dart`).
- [x] **Todo el tráfico por HTTPS, sin excepciones en release:** H-06.
- [x] **Validación de entradas en la app y permisos en el servidor:** H-04 en la app; RLS y RPC en el servidor (M3).
- [x] **Release sin debug, sin logs sensibles y con R8:** H-05, H-07 (Flutter compila release sin modo debug).

| ID | Cambio | Archivos |
|---|---|---|
| H-01 | `SecureSessionStorage` implementa `LocalStorage` de Supabase con `flutter_secure_storage`; si encuentra la sesión vieja en SharedPreferences, la mueve y la borra (nadie pierde la sesión). Se usa en el arranque normal y en el de segundo plano. | `lib/core/storage/secure_session_storage.dart`, `lib/app/config/constants.dart`, `lib/main.dart`, `lib/app/background_boot.dart`, `pubspec.yaml` |
| H-02 | Copias de seguridad desactivadas y reglas de extracción que excluyen todo. | `AndroidManifest.xml`, `res/xml/data_extraction_rules.xml` |
| H-03 | Receiver del widget no exportado. | `AndroidManifest.xml` |
| H-04 | `isTaskId` valida el UUID antes de usarlo. | `lib/app/home_widget_sync.dart` |
| H-05 | Log de errores solo en debug. | `lib/core/errors/supabase_guard.dart` |
| H-06 | `network_security_config.xml` (sin texto en claro, solo CAs del sistema) y comprobación de `https://`. | `res/xml/network_security_config.xml`, `AndroidManifest.xml`, `lib/app/config/constants.dart` |
| H-07 | R8 y reducción de recursos explícitos; compilar con ofuscación. | `android/app/build.gradle.kts` |
| H-08 | Firma de release con `key.properties`. | `android/app/build.gradle.kts`, `.gitignore` |

Comando de release:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=supabase.json
```

Crear la llave propia (una vez, fuera del repositorio):

```bash
keytool -genkey -v -keystore ~/questly-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias questly
# android/key.properties (no se sube a Git):
# storeFile=C:/ruta/questly-release.jks
# storePassword=…
# keyAlias=questly
# keyPassword=…
```

**Mejora opcional pendiente (+5):** certificate pinning con plan de rotación, biometría ligada a una llave o Play Integrity. No se hizo.

---

## Fase 4 · Verificación (antes y después)

| ID | Prueba | Antes | Después |
|---|---|---|---|
| H-01 | `adb shell run-as com.example.proyecto_movil cat shared_prefs/FlutterSharedPreferences.xml` tras iniciar sesión | Aparece `flutter.sb-…-auth-token` con el JWT | La clave ya no aparece. Prueba automática: `test/core/secure_session_storage_test.dart` (migra y borra el texto plano; guardar no toca SharedPreferences) |
| H-02 | `adb shell dumpsys package com.example.proyecto_movil \| findstr ALLOW_BACKUP` | Bandera `ALLOW_BACKUP` presente | Sin la bandera |
| H-03 | `apkanalyzer manifest print build/app/outputs/flutter-apk/app-release.apk` (o MobSF) | `HomeWidgetBackgroundReceiver` `exported=true` | `exported=false` |
| H-04 | Prueba automática `isTaskId` | Cualquier texto llegaba a `complete_task` | Solo UUID válidos (inyecciones y rutas rechazadas) |
| H-05 | `adb logcat` con el release mientras se fuerza un error (modo avión) | Se ve `Error inesperado: …` con la pila | No aparece nada |
| H-06 | Compilar con `SUPABASE_URL=http://…` | La app arrancaba | La app no arranca (`StateError`); el APK incluye `network_security_config` |
| H-07 | Abrir el APK con jadx o MobSF | Nombres de clases legibles; Dart sin ofuscar | Clases renombradas por R8; símbolos Dart en `build/symbols` |
| H-08 | `apksigner verify --print-certs app-release.apk` | `CN=Android Debug` | Certificado propio (con `key.properties`) |

### Evidencia del APK de release (7 de noviembre de 2026)

Compilado con `flutter build apk --release --obfuscate --split-debug-info=build/symbols` (R8 activo, 58 MB, símbolos Dart en `build/symbols/app.android-*.symbols`). Manifiesto leído con `aapt2 dump xmltree`:

```
android:allowBackup=false                              ← H-02
android:fullBackupContent=false                        ← H-02
android:dataExtractionRules=@xml/data_extraction_rules ← H-02
android:networkSecurityConfig=@xml/network_security_config ← H-06
es.antonborri.home_widget.HomeWidgetBackgroundReceiver  exported=false  ← H-03
```

Firma (`apksigner verify --print-certs`): `CN=Android Debug`. **H-08 está corregido en la configuración, pero falta crear la llave propia y `android/key.properties`**; hasta entonces Gradle avisa y firma con la de debug. Volver a ejecutar `apksigner` después de crearla para la evidencia final.

Nota: Flutter avisa que la librería nativa conserva información DWARF sin ofuscar; los nombres de Dart sí van ofuscados (`--obfuscate`).

Cada corrección queda en un commit propio que menciona su ID (por ejemplo, `H-01: sesión de Supabase cifrada con Keystore`).
