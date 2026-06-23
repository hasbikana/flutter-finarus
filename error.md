WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): receive_sharing_intent
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':receive_sharing_intent:compileDebugKotlin'.
> Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks
    Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks
      Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (11) and 'compileDebugKotlin' (21).

* Try:
> Consider using JVM Toolchain: https://kotl.in/gradle/jvm/toolchain
> Run with --scan to generate a Build Scan (Powered by Develocity).

BUILD FAILED in 1m 14s
Running Gradle task 'assembleDebug'...                             75.4s
Error: Gradle task assembleDebug failed with exit code 1