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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.offline_medic"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21  // Required for flutter_map
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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