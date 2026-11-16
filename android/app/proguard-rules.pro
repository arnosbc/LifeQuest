# H-06 (M7): R8 activo en release. Estas clases se usan por JNI o reflexión
# desde Flutter/Android y R8 no ve esas llamadas: si las borra o renombra, la
# app queda en negro (pasó con shared_preferences) o fallan los avisos.

# Plugins oficiales de Flutter (Pigeon/JNI: shared_preferences, path_provider…).
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
# DataStore que usa shared_preferences_android.
-keep class androidx.datastore.** { *; }
# Almacén cifrado de la sesión (H-01).
-keep class com.it_nomads.fluttersecurestorage.** { *; }
# Avisos locales: guarda los programados con Gson (TypeToken por reflexión).
-keep class com.dexterous.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
# Revisión de avisos en segundo plano y widget de inicio.
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class es.antonborri.home_widget.** { *; }
# Push (Firebase Cloud Messaging).
-keep class io.flutter.plugins.firebase.** { *; }

# Avisos de librerías opcionales que la app no usa.
-dontwarn com.google.android.play.core.**
-dontwarn org.conscrypt.**
