############################################
# ANDROID 14 BACK GESTURE FIX
############################################
-dontwarn android.window.**
-keep class android.window.BackEvent { *; }

############################################
# FLUTTER ENGINE
############################################
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

############################################
# INAPPWEBVIEW
############################################
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

############################################
# KOTLIN METADATA
############################################
-keep class kotlin.Metadata { *; }
