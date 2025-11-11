# Keep Flutter embedding and plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep Google Mobile Ads SDK public APIs
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }

# Keep AndroidX annotations and lifecycle classes used via reflection
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }
-keep class androidx.annotation.** { *; }

# Don't warn about Kotlin metadata in AARs
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**

# Optimize aggressively but keep class/method names where needed for reflection
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# SharedPreferences rules
-keep class androidx.preference.** { *; }
-keep class com.color.paletteasian.** { *; }

# Keep all model classes and serializers
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# General Android optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Remove logging for production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference 