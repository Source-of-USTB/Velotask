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
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                    setCompileSdkVersion.invoke(android, 36)
                    
                    val setBuildToolsVersion = android.javaClass.getMethod("setBuildToolsVersion", String::class.java)
                    setBuildToolsVersion.invoke(android, "36.0.0")
                } catch (e: Exception) {
                    println("Failed to set compileSdk/buildTools for ${project.name}: ${e.message}")
                }

                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    if (getNamespace.invoke(android) == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val groupName = if (project.group.toString().isNotEmpty() && project.group.toString() != "unspecified") project.group.toString() else "com.example.${project.name}"
                        setNamespace.invoke(android, groupName)
                    }
                } catch (e: Exception) {
                     println("Failed to set namespace for ${project.name}: ${e.message}")
                }

                try {
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    
                    setSourceCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
                    setTargetCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (e: Exception) {
                    println("Failed to set Java 17 for ${project.name}: ${e.message}")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
