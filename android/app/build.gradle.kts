// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//     id("dev.flutter.flutter-gradle-plugin")
// }

// android {
//     ndkVersion = "27.0.12077973"
//     namespace = "com.example.offline_medic"
//     compileSdk = flutter.compileSdkVersion
    

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_11.toString()
//     }

//     defaultConfig {
//         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//         applicationId = "com.example.offline_medic"
//         // You can update the following values to match your application needs.
//         // For more information, see: https://flutter.dev/to/review-gradle-config.
//         minSdk = 21  // Required for flutter_map
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         release {
//             // TODO: Add your own signing config for the release build.
//             // Signing with the debug keys for now, so `flutter run --release` works.
//             signingConfig = signingConfigs.getByName("debug")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }


plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
    // Flutter Gradle Plugin
=======
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
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
=======
    namespace = "com.offlinemedic.app"

    compileSdk = 34
    ndkVersion = "27.0.12077973"
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.offlinemedic.app"

        // Needed for AI / llama.cpp support
        minSdk = 26
        targetSdk = 34

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
<<<<<<< HEAD
            // Using debug signing temporarily
=======
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }

<<<<<<< HEAD
    // Prevent compression of GGUF model files
=======
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f
    androidResources {
        noCompress += listOf("gguf", "bin")
    }

<<<<<<< HEAD
    // Increase Gradle heap size
=======
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
<<<<<<< HEAD
    // flutter_llama_cpp manages native dependencies itself
=======
>>>>>>> 9d481f0b8d82d4142780d25b4cbc8bb761adf19f
}

flutter {
    source = "../.."
}