# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# MediaPipe / Gemma / Google AI 
-keep class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.**

# Google RAG library
-keep class com.google.ai.edge.localagents.** { *; }
-dontwarn com.google.ai.edge.localagents.**

# Guava
-dontwarn javax.annotation.**
-dontwarn javax.xml.stream.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.j2objc.annotations.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# TensorFlow Lite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# ObjectBox
-keep class io.objectbox.** { *; }
-dontwarn io.objectbox.**

# Apache Tika (transitive dependency)
-dontwarn org.apache.tika.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

