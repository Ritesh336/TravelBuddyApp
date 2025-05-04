plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.travel_buddy_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // Updated from flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.travel_buddy_app"
        minSdk = 23  // Android 6.0 Marshmallow
        targetSdk = 34  // Android 14
        versionCode = flutter.versionCode.toInt()  // Fixed from toInteger()
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

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    
    // Add the dependencies for Firebase products you want to use
    // For example, to use Firebase Authentication
    implementation("com.google.firebase:firebase-auth")
    
    // To use Firestore
    implementation("com.google.firebase:firebase-firestore")
    
    // To use Firebase Storage
    implementation("com.google.firebase:firebase-storage")
}

flutter {
    source = "../.."
}