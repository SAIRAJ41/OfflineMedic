plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    ndkVersion = "27.0.12077973"
    namespace = "com.example.offline_medic"
    compileSdk = flutter.compileSdkVersion
    
=======
    namespace = "com.offlinemedic.app"

    // Updated SDK + NDK settings
    compileSdk = 34
    ndkVersion = "25.2.9519653"
>>>>>>> 5c4ad7a (hello)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.offlinemedic.app"

        // Raised minSdk for llama.cpp support
        minSdk = 26
        targetSdk = 34

        versionCode = 1
        versionName = "1.0"

        // Only build for ARM64
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // Using debug signing temporarily
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }

    // Prevent compression of GGUF model files
    androidResources {
        noCompress += listOf("gguf", "bin")
    }

    // Increase Gradle heap size
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    // flutter_llama_cpp manages native dependencies itself
}

flutter {
    source = "../.."
}