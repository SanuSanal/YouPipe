# R8 rules for release builds.

# NewPipeExtractor runs YouTube's player JavaScript with Rhino to decipher stream URLs. Rhino loads classes by
# reflection, so shrinking or renaming them breaks playback. Keep both libraries whole.
-keep class org.schabi.newpipe.extractor.** { *; }
-keep class org.mozilla.javascript.** { *; }
-keep class org.mozilla.classfile.ClassFileWriter

# Rhino references desktop-JVM classes that don't exist on Android and are never reached there.
-dontwarn java.beans.**
-dontwarn javax.script.**
-dontwarn jdk.dynalink.**
-dontwarn org.mozilla.javascript.tools.**

# WorkManager (downloads) opens its Room database by reflection on the generated WorkDatabase_Impl's no-arg
# constructor. Without this, R8 strips it and the release build crashes at startup in InitializationProvider.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
