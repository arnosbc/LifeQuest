# H-07: con R8 activo, las clases que Dart busca por nombre a través de JNI
# (package:jni / jnigen) desaparecen o se renombran y el release se queda en
# negro (NoSuchMethodError en shared_preferences). Se conservan con su nombre.
# Lista sacada de los nombres que buscan jni y shared_preferences_android.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.github.dart_lang.** { *; }
# Los métodos suspend llevan Continuation en la firma y jni usa los
# intrínsecos de las corrutinas de Kotlin para esperar el resultado.
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
