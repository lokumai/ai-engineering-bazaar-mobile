import java.io.File
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter passes the --dart-define values as the `dart-defines` Gradle property: each entry is base64 encoded and the
// entries are separated by commas (encodeDartDefines in packages/flutter_tools/lib/src/build_info.dart).
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        .orEmpty()
        .split(",")
        .filter { it.isNotEmpty() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .associate { it.substringBefore("=") to it.substringAfter("=", "") }

// The host app starts sentry-android itself (NativeSentry.kt), and only when the Dart side starts Sentry: in the prod
// environment, which only lib/main/main_prod.dart selects, with a SENTRY_DSN (AppConfig.sentryDsn). On Android every
// Dart event leaves the device through the native SDK, so the two gates must agree; a fork that renames the prod
// entry point changes it here too (test/architecture/sentry_native_scrub_patterns_test.dart checks it, and
// nativeSdkReady fails at start when the gates disagree).
val isProdTarget = File(project.findProperty("target") as String? ?: "").name == "main_prod.dart"

// The upload key (plan 21.1): android/key.properties names the keystore and its passwords, and both stay out of git
// (.gitignore). Without the file a release APK is signed with the debug key, so `flutter run --release` works on any
// machine; a bundle, which is what Google Play takes, stops instead (below).
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties =
    Properties().apply { if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { load(it) } }

fun buildConfigString(value: String) = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

android {
    namespace = "dev.lokumai.bazaar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.lokumai.bazaar"
        // sentry_flutter 10 requires Android API 26 or higher.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The DSN is the public key that --dart-define already compiles into the Dart snapshot.
        val nativeSentryDsn = if (isProdTarget) dartDefines["SENTRY_DSN"].orEmpty() else ""
        buildConfigField("String", "SENTRY_DSN", buildConfigString(nativeSentryDsn))
        buildConfigField("String", "SENTRY_ENVIRONMENT", buildConfigString(dartDefines["SENTRY_ENVIRONMENT"].orEmpty()))
        buildConfigField("String", "SENTRY_DIST", buildConfigString(dartDefines["SENTRY_DIST"].orEmpty()))
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            signingConfig =
                if (keyPropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

// Review 6, finding 20: a bundle built without the upload key is signed with the debug key, which Google Play refuses.
// It stops here instead, on every machine but CI, which builds one only to check that it builds. A release APK, which
// `flutter run --release` installs, still builds with the debug key (review 7, finding 17).
gradle.taskGraph.whenReady {
    val releasing = allTasks.any { it.project == project && it.name == "bundleRelease" }
    if (releasing && !keyPropertiesFile.exists() && System.getenv("CI") != "true") {
        throw GradleException(
            "android/key.properties is missing, so this bundle would be signed with the debug key. " +
                "Add the upload key (docs/development.md, Release), or set CI=true to check only that the release builds.",
        )
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

// NativeSentryScrubberTest reads the fixtures the Dart tests share, so a changed fixture runs the JVM tests again.
tasks.withType<Test>().configureEach {
    inputs.dir(rootProject.file("../test/fixtures")).withPropertyName("sharedScrubFixtures")
}

dependencies {
    // Settings' Scan the code (plan 17.5): Google's code scanner, whose camera screen Google Play services shows, so the
    // app asks for no camera permission.
    implementation("com.google.android.gms:play-services-code-scanner:16.1.0")
    testImplementation("junit:junit:4.13.2")
    // Reads test/fixtures/native_scrub_cases.json, which the Dart scrubber test runs too.
    testImplementation("com.google.code.gson:gson:2.13.2")
}
