plugins {
    id("com.android.library") version "8.5.2"
    id("org.jetbrains.kotlin.android") version "2.1.10"
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.10"
}

android {
    namespace = "dev.fluidtype"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        consumerProguardFiles("consumer-rules.pro")
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()
            // The conformance fixtures in spec/ are a plain committed
            // directory shared with the other three ports, so the tests are
            // told where the repository root is rather than loading them from
            // the classpath.
            it.systemProperty("fluidtype.repoRoot", rootDir.parent)
        }
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
            withJavadocJar()
        }
    }
}

kotlin {
    jvmToolchain(17)

    // Every public declaration in a library should state its visibility.
    // explicitApi() rather than the matching -X flag in freeCompilerArgs,
    // because the DSL applies it only to production sources — the flag would
    // also hit the test sources and fail the build on every `fun` in them.
    explicitApi()

    compilerOptions {
        allWarningsAsErrors = true
    }
}

dependencies {
    // The core (FluidTypeScale, FluidTypeRole, FluidType) is plain Kotlin and
    // depends on none of this; only the dev.fluidtype.compose package does.
    implementation(platform("androidx.compose:compose-bom:2024.09.03"))
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")

    testImplementation(kotlin("test"))
    testImplementation("org.junit.jupiter:junit-jupiter:5.11.4")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
