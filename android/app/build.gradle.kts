import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (never committed — it and the
// keystore are git-ignored) holds storeFile, storePassword, keyAlias and
// keyPassword. See android/key.properties.example. Without it the release build
// falls back to the debug key, loudly: a warning is printed and the APK is named
// waha-ops-release-DEBUGKEY.apk so it cannot be mistaken for a properly signed one.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val useReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.waha.ops"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.waha.ops"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (useReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (useReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn("WARNING: android/key.properties not found — signing the release build with the DEBUG key.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    // Names the built APK waha-ops-release.apk rather than Flutter's generic
    // app-release.apk, since it is installed manually, not through a store.
    applicationVariants.all {
        val variant = this
        variant.outputs
            .map { it as com.android.build.gradle.internal.api.BaseVariantOutputImpl }
            .forEach { output ->
                val keyTag = if (variant.buildType.name == "release" && !useReleaseKey) "-DEBUGKEY" else ""
                output.outputFileName = "waha-ops-${variant.buildType.name}$keyTag.apk"
            }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
