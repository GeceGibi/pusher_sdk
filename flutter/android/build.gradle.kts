group = "com.pusher.sdk"
version = "1.0.2"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.pusher.sdk"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
    }

    sourceSets {
        getByName("main") {
            val nativeSrc = file("../../android/src/main/kotlin")
            if (nativeSrc.exists()) {
                java.srcDirs("src/main/kotlin", nativeSrc)
            } else {
                java.srcDirs("src/main/kotlin")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:24.1.0")
}
