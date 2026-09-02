import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取发布签名配置（android/key.properties，已被 .gitignore 忽略）
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.yuan.family_archive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 用到 Java 8 time API，必须开启核心库脱糖
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yuan.family_archive"
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

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

// AGP 9 下，file_picker 等插件在脚本里声明了 kotlin-android，却被
// `isAgp9OrAbove` 分支跳过，导致其 .kt 源码不被编译（Java 侧找不到
// FilePickerPlugin）。这里统一补一次；重复 apply 是幂等的。
rootProject.childProjects.values.forEach { sub ->
    if (sub.name in listOf("file_picker", "image_gallery_saver_plus", "share_plus")) {
        sub.pluginManager.apply("kotlin-android")
    }
}

// Kotlin 的 jvmTarget 必须与同一模块 Java 的 targetCompatibility 一致，否则报
// "Inconsistent JVM-target compatibility"。本机只装了 JDK 21，Kotlin 默认跟随 21，
// 而各插件把 Java 固定成 17 / 11，因此这里按模块读取 Java 版本来对齐 Kotlin。
fun javaTargetOf(project: Project): JavaVersion? {
    val androidExt = project.extensions.findByName("android") ?: return null
    val compileOptions =
        runCatching { androidExt.javaClass.getMethod("getCompileOptions").invoke(androidExt) }.getOrNull()
            ?: return null
    val raw = runCatching { compileOptions.javaClass.getMethod("getTargetCompatibility").invoke(compileOptions) }
        .getOrNull()
    return raw as? JavaVersion
}

gradle.projectsEvaluated {
    rootProject.childProjects.values.forEach { sub ->
        val jvmTarget = when (javaTargetOf(sub)) {
            JavaVersion.VERSION_21 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
            JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
        sub.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(jvmTarget)
        }
    }
}

dependencies {
    // 配合上面的 isCoreLibraryDesugaringEnabled
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
