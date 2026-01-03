import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

/// ============================================================================
/// NOTIFICATION SERVICE
/// Handles budget threshold notifications with "Crossing the Line" algorithm
/// to prevent notification spam.
/// ============================================================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification channel IDs
  static const String _warningChannelId = 'budget_warning';
  static const String _criticalChannelId = 'budget_critical';

  // SharedPreferences keys to track shown notifications (prevent spam)
  static const String _keyShownNotifications = 'shown_budget_notifications';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized successfully');
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Warning channel (50% threshold)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _warningChannelId,
          'Budget Warnings',
          description: 'Notifications when budget reaches 50%',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );

      // Critical channel (100% threshold)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _criticalChannelId,
          'Budget Alerts',
          description: 'Critical notifications when budget is exceeded',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    // Can navigate to specific screen based on payload if needed
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    debugPrint('[NotificationService] Permission status: $status');
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ===========================================================================
  // BUDGET THRESHOLD CHECKING - "Crossing the Line" Algorithm
  // ===========================================================================

  /// Check budget thresholds and trigger notifications if crossed
  /// 
  /// This implements the "Crossing the Line" algorithm:
  /// - Only notifies when CROSSING the threshold, not for every transaction
  /// - Prevents notification spam by tracking which thresholds have been shown
  /// 
  /// [categoryName] - Name of the budget category (e.g., "Xăng", "Thức ăn")
  /// [currentTotal] - Total spent BEFORE this transaction
  /// [newAmount] - Amount being added in this transaction
  /// [budgetLimit] - The budget limit for this category
  /// 
  /// Returns: Map with keys 'showWarning' and 'showCritical' indicating which thresholds were crossed
  Future<Map<String, bool>> checkBudgetThresholds({
    required String categoryName,
    required int currentTotal,
    required int newAmount,
    required int budgetLimit,
  }) async {
    if (budgetLimit <= 0) return {'showWarning': false, 'showCritical': false};

    // Calculate percentages
    final double oldPercent = currentTotal / budgetLimit;
    final double newPercent = (currentTotal + newAmount) / budgetLimit;

    debugPrint('[NotificationService] Budget check: $categoryName');
    debugPrint('  Old: ${(oldPercent * 100).toStringAsFixed(1)}%, New: ${(newPercent * 100).toStringAsFixed(1)}%');

    bool showWarning = false;
    bool showCritical = false;

    // Get month key for tracking (reset monthly)
    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';
    final notificationKey50 = '${categoryName}_50_$monthKey';
    final notificationKey100 = '${categoryName}_100_$monthKey';

    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    final shownNotifications = prefs.getStringList(_keyShownNotifications) ?? [];

    // Check 50% threshold crossing
    if (oldPercent < 0.5 && newPercent >= 0.5 && !shownNotifications.contains(notificationKey50)) {
      showWarning = true;
      await _showWarningNotification(categoryName, (newPercent * 100).toInt());
      
      // Mark as shown
      shownNotifications.add(notificationKey50);
      await prefs.setStringList(_keyShownNotifications, shownNotifications);
    }

    // Check 100% threshold crossing
    if (oldPercent < 1.0 && newPercent >= 1.0 && !shownNotifications.contains(notificationKey100)) {
      showCritical = true;
      await _showCriticalNotification(categoryName);
      
      // Mark as shown
      shownNotifications.add(notificationKey100);
      await prefs.setStringList(_keyShownNotifications, shownNotifications);
    }

    return {'showWarning': showWarning, 'showCritical': showCritical};
  }

  /// Show 50% warning notification
  Future<void> _showWarningNotification(String categoryName, int percentage) async {
    final isVi = appLanguage == 'vi';
    
    final title = isVi 
        ? '⚠️ Cảnh báo ngân sách' 
        : '⚠️ Budget Warning';
    final body = isVi
        ? 'Bạn đã sử dụng $percentage% ngân sách "$categoryName"'
        : 'You\'ve used $percentage% of your "$categoryName" budget';

    await _notifications.show(
      categoryName.hashCode + 50, // Unique ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _warningChannelId,
          'Budget Warnings',
          channelDescription: 'Notifications when budget reaches 50%',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFFA500), // Orange for warning
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'budget_warning_$categoryName',
    );

    debugPrint('[NotificationService] Showed 50% warning for $categoryName');
  }

  /// Show 100% critical notification with vibration
  Future<void> _showCriticalNotification(String categoryName) async {
    final isVi = appLanguage == 'vi';
    
    final title = isVi 
        ? '🚨 CẢNH BÁO: Vượt ngân sách!' 
        : '🚨 ALERT: Budget Exceeded!';
    final body = isVi
        ? 'Bạn đã hết ngân sách "$categoryName"!'
        : 'You\'ve run out of "$categoryName" budget!';

    // Show notification
    await _notifications.show(
      categoryName.hashCode + 100, // Unique ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _criticalChannelId,
          'Budget Alerts',
          channelDescription: 'Critical notifications when budget is exceeded',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF0000), // Red for critical
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'budget_critical_$categoryName',
    );

    // Vibrate the phone
    await _triggerVibration();

    debugPrint('[NotificationService] Showed 100% critical for $categoryName');
  }

  /// Trigger device vibration for critical alerts
  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        // Vibrate pattern: 500ms on, 200ms off, 500ms on
        await Vibration.vibrate(pattern: [0, 500, 200, 500]);
        debugPrint('[NotificationService] Vibration triggered');
      }
    } catch (e) {
      debugPrint('[NotificationService] Vibration error: $e');
    }
  }

  /// Clear notification history for a new month (call on app start)
  Future<void> clearOldNotifications() async {
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    final shownNotifications = prefs.getStringList(_keyShownNotifications) ?? [];
    
    // Get current month key
    final currentMonthKey = '${DateTime.now().year}-${DateTime.now().month}';
    
    // Keep only current month's notifications
    final filteredNotifications = shownNotifications
        .where((key) => key.endsWith(currentMonthKey))
        .toList();
    
    if (filteredNotifications.length != shownNotifications.length) {
      await prefs.setStringList(_keyShownNotifications, filteredNotifications);
      debugPrint('[NotificationService] Cleared old notification history');
    }
  }

  /// Test notification (for debugging)
  Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      'Test Notification',
      'VFinance notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _warningChannelId,
          'Budget Warnings',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }
}

/// Global instance for easy access
final notificationService = NotificationService();
