plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // 🔑 Firebase
    id("dev.flutter.flutter-gradle-plugin") // 🔑 Flutter
}

android {
    namespace = "com.example.galeria_final"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.galeria_final"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        // 🔑 Usa Java 17 para evitar errores con librerías modernas
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // ✅ Kotlin stdlib con versión explícita
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")

    // 🔑 Firebase BOM (maneja versiones automáticamente)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // 🔑 Firebase Storage
    implementation("com.google.firebase:firebase-storage")

    // 🔑 Firebase Analytics (opcional pero recomendado)
    implementation("com.google.firebase:firebase-analytics")
}