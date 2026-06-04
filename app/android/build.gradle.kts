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
subprojects {
    val configureProject: Project.() -> Unit = {
        if (extensions.findByName("android") != null) {
            configure<com.android.build.gradle.BaseExtension> {
                if (namespace == null) {
                    val groupStr = project.group.toString()
                    namespace = if (groupStr.isNotEmpty() && groupStr != "unspecified") {
                        groupStr
                    } else {
                        val formattedName = project.name.replace(Regex("[^a-zA-Z0-9_]"), "_")
                        "com.example.$formattedName"
                    }
                }
            }
        }
    }
    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
