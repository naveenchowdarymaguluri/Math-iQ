import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// ── Release keystore (optional — falls back to debug if file absent) ──────────
// Create android/keystore.properties (add it to .gitignore!) containing:
//   storeFile=../your-key.jks      ← path relative to android/app/
//   storePassword=YourStorePassword
//   keyAlias=YourKeyAlias
//   keyPassword=YourKeyPassword
val keystorePropsFile = rootProject.file("keystore.properties")
val hasKeystore = keystorePropsFile.exists()
val keystoreProps = Properties().apply {
    if (hasKeystore) load(keystorePropsFile.inputStream())
}

android {
    namespace  = "com.naveen.iqmath"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ── Signing configs ───────────────────────────────────────────────────────
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias      = keystoreProps["keyAlias"]      as String
                keyPassword   = keystoreProps["keyPassword"]   as String
                storeFile     = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.naveen.iqmath"
        minSdk = flutter.minSdkVersion                      // Android 5.0 Lollipop+
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    buildTypes {
        release {
            // ── Code shrinking & obfuscation ──────────────────────────────
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use release keystore if available, otherwise fall back to debug
            signingConfig = if (hasKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
