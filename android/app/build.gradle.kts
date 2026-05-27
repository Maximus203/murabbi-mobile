plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.murabbi.murabbi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications ^17.x (uses java.time APIs
        // that need backporting on minSdk < 26). Cf. Q-15a / ADR-008.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.murabbi.murabbi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 5.0 (API 21) — required by flutter_local_notifications ^17.x.
        // Bump from `flutter.minSdkVersion` (resolves to 19) to satisfy
        // CheckAarMetadata. Cf. ADR-008 (Q-15a, timer notifications v1.5).
        // Android 5.0 (API 21) — required by flutter_local_notifications ^17.x.
        // Bump from `flutter.minSdkVersion` (resolves to 19) to satisfy
        // CheckAarMetadata. Cf. ADR-008 (Q-15a, timer notifications v1.5).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backport des APIs Java 8+ (notamment java.time) pour
    // flutter_local_notifications sur Android API < 26. Cf. Q-15a / ADR-008.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
