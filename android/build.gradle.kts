allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Patch: inject missing `namespace` for old plugins incompatible with AGP 7.3+
// Specifically fixes: device_calendar 4.3.3 (abandoned, never added namespace DSL)
// Uses plugins.withId instead of afterEvaluate to avoid "already evaluated" error.
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
        if (android != null) {
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}
