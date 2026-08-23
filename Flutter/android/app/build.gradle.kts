import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing — key.properties (gitignore'd) dan o'qiladi
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "uz.pitgo.pitgo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.pitgo.pitgo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // PitGo (mijoz) va PitGo Pro (servis/usta/evakuator) — ikkita alohida ilova,
    // bitta kod bazasidan. Har biri o'z applicationId + nomi + ikonkasi bilan.
    flavorDimensions += "app"
    productFlavors {
        create("customer") {
            dimension = "app"
            applicationId = "uz.pitgo.pitgo"
            resValue("string", "app_name", "PitGo")
        }
        create("pro") {
            dimension = "app"
            applicationId = "uz.pitgo.pitgo.pro"
            resValue("string", "app_name", "PitGo Pro")
        }
    }

    // APK fayl nomida versiya bo'lsin: `app-customer-release.apk` o'rniga
    // `pitgo-2.1.0.apk` / `pitgo-pro-2.1.0.apk`. Shunda qaysi build qaysi
    // versiya ekani fayl nomidan ko'rinadi va serverga yuklaganda qayta
    // nomlash kerak bo'lmaydi.
    applicationVariants.all {
        val variant = this
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            val prefix = if (variant.flavorName == "pro") "pitgo-pro" else "pitgo"
            val suffix = if (variant.buildType.name == "release") "" else "-${variant.buildType.name}"
            output.outputFileName = "$prefix-${variant.versionName}$suffix.apk"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties bo'lsa release kalit bilan, bo'lmasa debug bilan imzolaymiz
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.yandex.android:maps.mobile:4.4.0-full")
}
