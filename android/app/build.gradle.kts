import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vendwise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.vendwise"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Read keystore properties if present and configure signing for release
            val keystorePropsFile = rootProject.file("key.properties")
            if (keystorePropsFile.exists()) {
                val keystoreProps = Properties()
                keystoreProps.load(FileInputStream(keystorePropsFile))

                val keystorePath = keystoreProps.getProperty("storeFile")
                val keystoreStorePassword = keystoreProps.getProperty("storePassword")
                val keystoreAlias = keystoreProps.getProperty("keyAlias")
                val keystoreKeyPassword = keystoreProps.getProperty("keyPassword")

                signingConfigs {
                    create("release") {
                        // Resolve keystore path: prefer module-relative file, then rootProject file
                        val candidateModuleFile = project.file(keystorePath)
                        // rootProject.projectDir is the 'android' folder; its parent is the repo root
                        val repoRoot = rootProject.projectDir.parentFile ?: rootProject.projectDir
                        val candidateRepoFile = File(repoRoot, keystorePath)
                        // also try stripping a leading "android/" segment if present
                        val stripped = keystorePath.removePrefix("android/")
                        val candidateRepoStripped = File(repoRoot, stripped)
                        // finally try filename only at repo root
                        val candidateFilename = File(repoRoot, keystorePath.substringAfterLast('/'))

                        val resolvedKeystoreFile = when {
                            candidateModuleFile.exists() -> candidateModuleFile
                            candidateRepoFile.exists() -> candidateRepoFile
                            candidateRepoStripped.exists() -> candidateRepoStripped
                            candidateFilename.exists() -> candidateFilename
                            else -> candidateRepoFile
                        }

                        storeFile = resolvedKeystoreFile
                        storePassword = keystoreStorePassword
                        keyAlias = keystoreAlias
                        keyPassword = keystoreKeyPassword
                    }
                }
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if no key.properties is found
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
