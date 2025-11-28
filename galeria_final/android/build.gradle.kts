import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ----------------------------
// 1. NECESARIO PARA FIREBASE
// ----------------------------
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin GOOGLE SERVICES necesario para Firebase
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// ----------------------------
// 2. REPOSITORIOS GLOBALES
// ----------------------------
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ----------------------------
// 3. CONFIGURACIÓN DEFAULT
// ----------------------------
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ----------------------------
// 4. TAREA CLEAN
// ----------------------------
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
