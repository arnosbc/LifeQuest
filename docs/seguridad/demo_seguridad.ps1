# Demostración en vivo de las correcciones de seguridad de LifeQuest.
# Uso (en la terminal de VS Code, dentro de la carpeta proyec_movil):
#   powershell -ExecutionPolicy Bypass -File docs\seguridad\demo_seguridad.ps1
# Para mostrar un solo hallazgo:  ... -File docs\seguridad\demo_seguridad.ps1 H-05
#
# Cada bloque muestra cómo estaba ANTES (de las evidencias guardadas) y repite
# la misma prueba AHORA. No muestra tokens, contraseñas ni correos.

param([string]$Solo = '')

$ErrorActionPreference = 'Continue'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$apk = 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
$tools = Get-ChildItem (Join-Path $sdk 'build-tools') -Directory -ErrorAction SilentlyContinue |
  Sort-Object Name | Select-Object -Last 1
$adb = Join-Path $sdk 'platform-tools\adb.exe'
foreach ($jbr in @('C:\Program Files\Android\Android Studio1\jbr', 'C:\Program Files\Android\Android Studio\jbr')) {
  if (Test-Path $jbr) { $env:JAVA_HOME = $jbr; break }
}

function Titulo($id, $texto) {
  Write-Host ''
  Write-Host ('=' * 70) -ForegroundColor DarkMagenta
  Write-Host " $id · $texto" -ForegroundColor Magenta
  Write-Host ('=' * 70) -ForegroundColor DarkMagenta
}
function Antes($texto) { Write-Host "ANTES:  $texto" -ForegroundColor Red }
function Ahora($texto) { Write-Host "AHORA:  $texto" -ForegroundColor Green }
function Toca($id) { return ($Solo -eq '' -or $Solo -eq $id) }
function SinApk {
  if (Test-Path $apk) { return $false }
  Write-Host "  (Falta el APK de release. Compílalo primero con:" -ForegroundColor Yellow
  Write-Host "   flutter build apk --release --split-per-abi --target-platform android-arm64 --obfuscate --split-debug-info=build/debug-info --dart-define-from-file=supabase.json)" -ForegroundColor Yellow
  return $true
}

if (Toca 'H-05') {
  Titulo 'H-05 (M4)' 'Enlace del widget con texto malicioso'
  Antes "el enlace lifequest://focus?task=1' OR '1'='1 llegaba a la app:"
  Write-Host "        Expected: '/dungeon'   Actual: '/dungeon?task=1'' OR ''1''=''1'" -ForegroundColor Red
  Ahora 'la prueba manda 5 enlaces maliciosos y ninguno debe pasar:'
  flutter test test/app/home_screen_widget_test.dart
}

if (Toca 'H-01') {
  Titulo 'H-01 (M9)' 'Sesión guardada sin cifrar'
  Antes 'FlutterSharedPreferences.xml tenía el access_token y el refresh_token legibles.'
  Ahora 'la sesión se guarda solo en el almacén cifrado (Keystore) y se borra la copia vieja:'
  flutter test test/core/storage/secure_session_storage_test.dart
}

if (Toca 'H-04') {
  Titulo 'H-04 (M5)' 'Conexiones sin cifrar (HTTP)'
  Antes 'la app no prohibía HTTP ni revisaba que el servidor fuera https.'
  Ahora 'una URL http se rechaza:'
  flutter test test/app/config/constants_test.dart
}

if (Toca 'H-02') {
  Titulo 'H-02 (M8)' 'Firma de la app'
  Antes 'Signer #1 certificate DN: C=US, O=Android, CN=Android Debug   (llave pública de pruebas)'
  if (-not (SinApk)) {
    Ahora 'firma con la llave propia del proyecto:'
    & (Join-Path $tools.FullName 'apksigner.bat') verify --print-certs $apk 2>$null |
      Select-String 'DN:' | Select-Object -First 1 | ForEach-Object { Write-Host "        $_" -ForegroundColor Green }
  }
}

if (Toca 'H-03') {
  Titulo 'H-03 (M9) y H-04 (M5)' 'Copia de seguridad y tráfico sin cifrar en el APK'
  Antes 'el AndroidManifest no tenía allowBackup, dataExtractionRules, networkSecurityConfig ni usesCleartextTraffic (Android usaba copias de seguridad ACTIVAS).'
  if (-not (SinApk)) {
    Ahora 'atributos dentro del APK (0x0 = falso):'
    & (Join-Path $tools.FullName 'aapt.exe') dump xmltree $apk AndroidManifest.xml 2>$null |
      Select-String 'allowBackup|fullBackupContent|dataExtractionRules|networkSecurityConfig|usesCleartextTraffic' |
      ForEach-Object { Write-Host ('        ' + $_.Line.Trim()) -ForegroundColor Green }
  }
  if ((Test-Path $adb) -and ((& $adb devices) -match "`tdevice")) {
    Antes 'Android reportaba: flags=[ HAS_CODE ALLOW_CLEAR_USER_DATA ALLOW_BACKUP ]'
    Ahora 'lo que reporta el teléfono conectado (ya sin ALLOW_BACKUP):'
    & $adb shell dumpsys package com.example.proyecto_movil |
      Select-String 'flags=\[' | Select-Object -First 1 |
      ForEach-Object { Write-Host ('        ' + $_.Line.Trim()) -ForegroundColor Green }
  } else {
    Write-Host '  (Conecta el teléfono por USB para ver también lo que reporta Android.)' -ForegroundColor Yellow
  }
}

if (Toca 'H-06') {
  Titulo 'H-06 (M7)' 'Código legible al descompilar'
  Antes 'en libapp.so se leían nombres de clases: DungeonBloc, DungeonRemoteDataSource, GuidedTaskBloc, HabitsRemoteDataSource. R8 apagado.'
  if (-not (SinApk)) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $apk))
    $entry = $zip.Entries | Where-Object FullName -eq 'lib/arm64-v8a/libapp.so'
    $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::GetEncoding(28591))
    $bin = $reader.ReadToEnd(); $reader.Close(); $zip.Dispose()
    $found = @('DungeonBloc', 'DungeonRemoteDataSource', 'GuidedTaskBloc', 'HabitsRemoteDataSource') |
      Where-Object { $bin.Contains($_) }
    if ($found) { Ahora ('todavía se leen: ' + ($found -join ', ')) }
    else { Ahora 'ninguno de esos nombres aparece: el código está ofuscado.' }
    $mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Ahora "R8 activo · tamaño del APK: $mb MB (antes 42.1 MB)"
  }
}

Write-Host ''
Write-Host 'Listo. Commits de cada corrección: docs\seguridad (informe, sección 5).' -ForegroundColor Cyan
