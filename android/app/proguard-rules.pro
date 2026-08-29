# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener los MethodChannels para NativeBridge
-keep class com.mipypos.native.MainActivity { *; }

# Hive y dependencias de base de datos
-keep class io.hive.** { *; }
-dontwarn io.hive.**
