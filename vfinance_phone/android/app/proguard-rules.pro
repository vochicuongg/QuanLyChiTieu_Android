# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep SharedPreferences
-keep class androidx.preference.** { *; }

# Keep HTTP client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep Package Info Plus
-keep class io.flutter.plugins.packageinfo.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Firestore
-keep class com.google.firebase.firestore.** { *; }

# Play Core (referenced by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Fix for deferred components
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Flutter Notification Listener
-keep class im.zoe.labs.flutter_notification_listener.** { *; }
-keep class android.service.notification.** { *; }
-keep class * extends android.service.notification.NotificationListenerService { *; }
-keepclassmembers class * extends android.service.notification.NotificationListenerService {
    public void onNotificationPosted(android.service.notification.StatusBarNotification);
    public void onNotificationRemoved(android.service.notification.StatusBarNotification);
}

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
