import groovy.json.JsonSlurper
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// No se incluye una configuración de otra app para habilitar el botón Google.
// Si existe el archivo real de Champ, se valida antes de generar sus recursos.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    val configuration = JsonSlurper().parse(googleServicesFile) as? Map<*, *>
        ?: error("google-services.json debe contener un objeto JSON de Champ.")
    val projectInfo = configuration["project_info"] as? Map<*, *>
        ?: error("Falta project_info en google-services.json de Champ.")
    val firebaseProjectId = projectInfo["project_id"]?.toString().orEmpty()
    val projectNumber = projectInfo["project_number"]?.toString().orEmpty()
    require(firebaseProjectId.isNotBlank() && projectNumber.isNotBlank()) {
        "Faltan project_id/project_number reales en google-services.json de Champ."
    }
    val clients = configuration["client"] as? List<*> ?: emptyList<Any>()
    val matchingClient = clients.mapNotNull { it as? Map<*, *> }.firstOrNull {
        val clientInfo = it["client_info"] as? Map<*, *>
        val androidInfo = clientInfo?.get("android_client_info") as? Map<*, *>
        androidInfo?.get("package_name") == "com.example.champ"
    } ?: error("google-services.json no tiene un registro para com.example.champ.")
    val clientInfo = matchingClient["client_info"] as Map<*, *>
    val firebaseAppId = clientInfo["mobilesdk_app_id"]?.toString().orEmpty()
    require(firebaseAppId.startsWith("1:$projectNumber:android:")) {
        "El registro Android de Champ no coincide con project_number del JSON."
    }
    val dartDefines = providers.gradleProperty("dart-defines").orNull.orEmpty()
        .split(",")
        .filter { it.isNotBlank() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .map { it.split("=", limit = 2) }
        .filter { it.size == 2 }
        .associate { it[0] to it[1] }
    val expectedValues = mapOf(
        "FIREBASE_PROJECT_ID" to firebaseProjectId,
        "FIREBASE_APP_ID" to firebaseAppId,
        "FIREBASE_MESSAGING_SENDER_ID" to projectNumber,
    )
    expectedValues.forEach { (key, value) ->
        val supplied = dartDefines[key]
        require(supplied.isNullOrBlank() || supplied == value) {
            "$key no coincide con google-services.json de Champ."
        }
    }
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.example.champ"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.champ"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
