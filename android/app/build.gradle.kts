plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.office_control"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.office_control"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
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

tasks.register<Copy>("copyOfficeControlApk") {
    // Flutter/Gradle output lives under the root build directory:
    //   <repo>/build/app/outputs/apk/release/app-release.apk
    from(rootProject.layout.buildDirectory.file("app/outputs/apk/release/app-release.apk"))
    into(rootProject.layout.buildDirectory.dir("app/outputs/apk/release"))
    rename("app-release.apk", "office-control.apk")
}

// Produce office-control.apk alongside app-release.apk after the APK listing
// redirect task finishes (avoids Gradle implicit dependency validation issues).
tasks.matching { it.name == "createReleaseApkListingFileRedirect" }.configureEach {
    finalizedBy("copyOfficeControlApk")
}

flutter {
    source = "../.."
}
