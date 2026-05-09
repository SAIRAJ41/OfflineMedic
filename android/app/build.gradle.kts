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
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.offlinemedic.app"

    compileSdk = 34
    ndkVersion = "27.0.12077973"

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
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }

    androidResources {
        noCompress += listOf("gguf", "bin")
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
}

flutter {
    source = "../.."
}