# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# UnifiedPush
-keep class org.unifiedpush.** { *; }
-dontwarn org.unifiedpush.**
-keep class org.unifiedpush.android.connector.** { *; }
-keep interface org.unifiedpush.android.connector.** { *; }

# Matrix SDK
-keep class org.matrix.** { *; }
-dontwarn org.matrix.**

# Background services
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver

# Notifications
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class * extends androidx.core.app.NotificationCompat$Style
-keep class * extends android.app.NotificationManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }