# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.app.**        { *; }
-keep class io.flutter.plugin.**     { *; }
-keep class io.flutter.util.**       { *; }
-keep class io.flutter.view.**       { *; }
-keep class io.flutter.**            { *; }
-keep class io.flutter.plugins.**    { *; }
-dontwarn io.flutter.embedding.**

# ── Google Mobile Ads SDK ─────────────────────────────────────────────────────
-keep class com.google.android.gms.ads.**   { *; }
-keep class com.google.ads.**               { *; }
-dontwarn com.google.android.gms.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.**                { *; }
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlin.**

# ── Shared Preferences / JSON ─────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# ── Keep native methods ───────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── Audioplayers plugin ───────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# ── Firebase Core ─────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }

# ── Firebase Analytics ────────────────────────────────────────────────────────
-keep class com.google.android.gms.measurement.** { *; }
-dontwarn com.google.android.gms.measurement.**

# ── Firebase Crashlytics ──────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**
# Preserve the mapping file so Crashlytics can deobfuscate stack traces
-printmapping mapping.txt
