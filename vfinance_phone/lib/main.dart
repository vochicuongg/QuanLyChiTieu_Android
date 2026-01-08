import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/widget_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens.dart' hide SettingsScreen, LichSuScreen;
import 'services/auth_service.dart';
import 'services/transaction_service.dart'; // Cloud First: Firestore as single source of truth
import 'services/update_service.dart'; // In-app update service
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =================== GLOBAL STATE ===================
SharedPreferences? appPrefs;
String appLanguage = 'vi';
String appLanguageMode = 'auto'; // 'vi', 'en', or 'auto'
const String keyLanguage = 'app_language';

// Theme mode: 'light', 'dark', 'system'
String appThemeMode = 'dark';
const String keyThemeMode = 'theme_mode';
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Holds Guest data captured before login for migration to new account.
/// Set by SettingsScreen before navigating to LoginScreen, cleared after upload.
List<Map<String, dynamic>>? pendingMigrationData;

final RegExp _numberFormatRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

// =================== COLOR SCHEME ===================
// Primary color from logo (purple/violet)
const Color primaryColor = Color(0xFF195fc2);
const Color primaryLightColor = Color(0xFF415EEF);

// Dark theme colors0
const Color darkSurfaceColor = Color(0xFF1E1E2E);
const Color darkCardColor = Color(0xFF2D2D3F);

// Light theme colors  
const Color lightSurfaceColor = Color(0xFFF5F5F7);
const Color lightCardColor = Color(0xFFFFFFFF);

// Expense/Income colors
const Color expenseColor = Color(0xFFF08080);
const Color incomeColor = Color(0xFF4CAF93);

// =================== THEMES ===================
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.dark(
    primary: primaryColor,
    secondary: primaryLightColor,
    surface: darkSurfaceColor,
  ),
  scaffoldBackgroundColor: darkSurfaceColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkSurfaceColor,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: darkCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: darkCardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: primaryLightColor,
    surface: lightSurfaceColor,
  ),
  scaffoldBackgroundColor: lightSurfaceColor,
  appBarTheme: AppBarTheme(
    backgroundColor: lightSurfaceColor,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.black87,
    iconTheme: const IconThemeData(color: Colors.black87),
  ),
  cardTheme: CardThemeData(
    color: lightCardColor,
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: lightCardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notifications
  await notificationService.initialize();
  await notificationService.requestPermission();
  await notificationService.clearOldNotifications();
  
  SharedPreferences.getInstance().then((prefs) {
    appPrefs = prefs;
    // Load theme preference
    final savedTheme = prefs.getString(keyThemeMode);
    if (savedTheme != null) {
      appThemeMode = savedTheme;
      themeNotifier.value = _getThemeMode(savedTheme);
    }
  });
  
  runApp(const VFinanceRoot());
}

class VFinanceRoot extends StatelessWidget {
  const VFinanceRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VFinance',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Check if user has skipped login before
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    final skippedLogin = prefs.getBool('skipped_login') ?? false;
    
    if (authService.currentUser != null || skippedLogin) {
      _showLogin = false;
    }
    
    setState(() => _initialized = true);
    FlutterNativeSplash.remove();
  }

  void _onLoginSuccess() {
    setState(() => _showLogin = false);
  }

  void _onSkip() async {
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('skipped_login', true);
    setState(() => _showLogin = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showLogin) {
      return LoginScreen(
        onLoginSuccess: _onLoginSuccess,
        onSkip: _onSkip,
      );
    }

    return const VFinanceApp();
  }
}

ThemeMode _getThemeMode(String mode) {
  switch (mode) {
    case 'light': return ThemeMode.light;
    case 'dark': return ThemeMode.dark;
    default: return ThemeMode.system;
  }
}

void setThemeMode(String mode) async {
  appThemeMode = mode;
  themeNotifier.value = _getThemeMode(mode);
  final prefs = appPrefs ?? await SharedPreferences.getInstance();
  await prefs.setString(keyThemeMode, mode);
}

// =================== UTILS ===================
String dinhDangSo(int value) {
  return value.toString().replaceAllMapped(_numberFormatRegex, (m) => '${m[1]}.');
}

String dinhDangGio(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String dinhDangNgayDayDu(DateTime time) {
  final d = time.day.toString().padLeft(2, '0');
  final mo = time.month.toString().padLeft(2, '0');
  return '$d/$mo/${time.year}';
}

String dinhDangNgayHienThi(DateTime time) {
  final d = time.day.toString().padLeft(2, '0');
  final mo = time.month.toString().padLeft(2, '0');
  if (appLanguage == 'en') return '$mo/$d/${time.year}';
  return '$d/$mo/${time.year}';
}

String getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

String getOrdinalSuffix(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1: return '${day}st';
    case 2: return '${day}nd';
    case 3: return '${day}rd';
    default: return '${day}th';
  }
}

String getMonthKey(DateTime date) => '${date.month}/${date.year}';

// =================== FORMATTING ===================
String formatAmountWithCurrency(int vndAmount) {
  return '${dinhDangSo(vndAmount)} ₫';
}

// =================== MODEL ===================
class ChiTieuItem {
  final String? id;
  final int soTien;
  final DateTime thoiGian;
  final String? tenChiTieu;
  final String? subCategory; // Subcategory path (e.g., "nhaTro.tienDien")

  ChiTieuItem({this.id, required this.soTien, required this.thoiGian, this.tenChiTieu, this.subCategory});

  ChiTieuItem copyWith({String? id, int? soTien, DateTime? thoiGian, String? tenChiTieu, String? subCategory}) {
    return ChiTieuItem(
      id: id ?? this.id,
      soTien: soTien ?? this.soTien,
      thoiGian: thoiGian ?? this.thoiGian,
      tenChiTieu: tenChiTieu ?? this.tenChiTieu,
      subCategory: subCategory ?? this.subCategory,
    );
  }

  Map<String, dynamic> toJson() => {
    'soTien': soTien,
    'thoiGian': thoiGian.toIso8601String(),
    if (tenChiTieu != null) 'tenChiTieu': tenChiTieu,
    if (subCategory != null) 'subCategory': subCategory,
  };

  factory ChiTieuItem.fromJson(Map<String, dynamic> json) => ChiTieuItem(
    soTien: json['soTien'] as int,
    thoiGian: DateTime.parse(json['thoiGian'] as String),
    tenChiTieu: json['tenChiTieu'] as String?,
    subCategory: json['subCategory'] as String?,
  );
}

class HistoryEntry {
  final ChiTieuMuc muc;
  final ChiTieuItem item;
  HistoryEntry({required this.muc, required this.item});
}

// =================== CATEGORY ===================
enum ChiTieuMuc { soDu, nhaTro, hocPhi, thucAn, doUong, xang, muaSam, suaXe, khac, lichSu, caiDat }

extension ChiTieuMucX on ChiTieuMuc {
  String get ten {
    final isVi = appLanguage == 'vi';
    switch (this) {
      case ChiTieuMuc.soDu: return isVi ? 'Số dư' : 'Balance';
      case ChiTieuMuc.nhaTro: return isVi ? 'Nhà ở' : 'Housing';
      case ChiTieuMuc.hocPhi: return isVi ? 'Giáo dục' : 'Education';
      case ChiTieuMuc.thucAn: return isVi ? 'Thức ăn' : 'Food';
      case ChiTieuMuc.doUong: return isVi ? 'Đồ uống' : 'Drinks';
      case ChiTieuMuc.xang: return isVi ? 'Di chuyển' : 'Transportation';
      case ChiTieuMuc.muaSam: return isVi ? 'Mua sắm' : 'Shopping';
      case ChiTieuMuc.suaXe: return isVi ? 'Sửa chữa' : 'Repair';
      case ChiTieuMuc.khac: return isVi ? 'Khoản chi khác' : 'Other';
      case ChiTieuMuc.lichSu: return isVi ? 'Lịch sử' : 'History';
      case ChiTieuMuc.caiDat: return isVi ? 'Cài đặt' : 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case ChiTieuMuc.soDu: return Icons.account_balance_wallet_rounded;
      case ChiTieuMuc.nhaTro: return Icons.home_rounded;
      case ChiTieuMuc.hocPhi: return Icons.school_rounded;
      case ChiTieuMuc.thucAn: return Icons.restaurant_rounded;
      case ChiTieuMuc.doUong: return Icons.local_cafe_rounded;
      case ChiTieuMuc.xang: return Icons.local_gas_station_rounded;
      case ChiTieuMuc.muaSam: return Icons.shopping_bag_rounded;
      case ChiTieuMuc.suaXe: return Icons.build_rounded;
      case ChiTieuMuc.khac: return Icons.money_rounded;
      case ChiTieuMuc.lichSu: return Icons.history_rounded;
      case ChiTieuMuc.caiDat: return Icons.settings_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ChiTieuMuc.soDu: return incomeColor;
      case ChiTieuMuc.nhaTro: return Colors.blue;
      case ChiTieuMuc.hocPhi: return Colors.purple;
      case ChiTieuMuc.thucAn: return Colors.orange;
      case ChiTieuMuc.doUong: return Color(0xFFAE7152);
      case ChiTieuMuc.xang: return Colors.red;
      case ChiTieuMuc.muaSam: return Colors.pink;
      case ChiTieuMuc.suaXe: return Colors.teal;
      case ChiTieuMuc.khac: return Colors.grey;
      case ChiTieuMuc.lichSu: return Colors.blueGrey;
      case ChiTieuMuc.caiDat: return Colors.grey;
    }
  }
}

// =================== MAIN APP ===================
class VFinanceApp extends StatefulWidget {
  const VFinanceApp({super.key});
  @override
  State<VFinanceApp> createState() => _VFinanceAppState();
}

class _VFinanceAppState extends State<VFinanceApp> with WidgetsBindingObserver {
  final _widgetService = WidgetService();
  DateTime _currentDay = DateTime.now();
  bool _isLoading = true;
  int _selectedIndex = 2; // Default to Home (center)
  
  final Map<ChiTieuMuc, List<ChiTieuItem>> _chiTheoMuc = {
    for (final muc in ChiTieuMuc.values) muc: <ChiTieuItem>[],
  };

  final Map<String, Map<String, List<HistoryEntry>>> _lichSuThang = {};

  static const String _keyChiTheoMuc = 'chi_theo_muc';
  static const String _keyLichSuThang = 'lich_su_thang';

  int? _cachedTongHomNay;
  final Map<ChiTieuMuc, int> _cachedTongMuc = {};
  Timer? _dayCheckTimer;
  StreamSubscription<List<TransactionDoc>>? _transactionsSub; // Cloud First: listen to Firestore
  StreamSubscription? _authStateSub; // Listen to auth state changes

  static DateTime _asDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _invalidateCache() {
    _cachedTongHomNay = null;
    _cachedTongMuc.clear();
  }
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (appLanguage == 'vi') {
      if (hour >=5 && hour < 11) return '🌞 Buổi sáng vui vẻ nho';
      if (hour >= 11 && hour < 13) return '☀️ Nghỉ trưa thư giãn nhen';
      if (hour >= 13 && hour < 18) return '⛅ Buổi chiều mát mẻ nha';
      if (hour >= 18 && hour < 22) return '🌙 Buổi tối ấm áp nhé';
      return '🌠 Nghỉ ngơi sớm đi nè';
    } else {
      if (hour >= 5 && hour < 11) return '🌞 Have a great morning';
      if (hour >= 11 && hour < 13) return '☀️ Have a relaxing lunch break';
      if (hour >= 13 && hour < 18) return '⛅ Have a lovely afternoon';
      if (hour >=18 && hour < 22) return '🌙 Have a cozy evening';
      return '🌠 Have an early night';
    }
  }

  @override
  void initState() {
    super.initState();
    _currentDay = _asDate(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkPendingNavigation();
      // Silent update check on startup (after a delay to not block UI)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          UpdateService().checkForUpdate(context, isManual: false);
        }
      });
    });
    WidgetsBinding.instance.addObserver(this);
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkNewDay());
    
    // Cloud First: Subscribe to Firestore when user logs in
    _setupFirestoreSubscription();
    
    // Listen to auth state changes to re-subscribe when user logs in/out
    _authStateSub = authService.authStateChanges.listen((user) {
      if (user != null) {
         appPrefs?.setString('user_display_name', user.displayName ?? 'bạn');
      }
      _setupFirestoreSubscription();
    });
  }
  
  /// Setup or teardown Firestore subscription based on auth state
  void _setupFirestoreSubscription() {
    debugPrint('[Phone App] _setupFirestoreSubscription called, isLoggedIn=${transactionService.isLoggedIn}');
    _transactionsSub?.cancel();
    _transactionsSub = null;
    
    if (transactionService.isLoggedIn) {
      debugPrint('[Phone App] Subscribing to transactionsStream...');
      
      // Clear SharedPreferences transaction data to ensure Firestore is the only source
      final prefs = appPrefs;
      if (prefs != null) {
        prefs.remove(_keyChiTheoMuc);
        prefs.remove(_keyLichSuThang);
      } else {
        SharedPreferences.getInstance().then((p) {
          p.remove(_keyChiTheoMuc);
          p.remove(_keyLichSuThang);
        });
      }
      
      _transactionsSub = transactionService.transactionsStream.listen(_onTransactionsChanged);
    } else {
      // User logged out: Clear all data to prevent leakage
      debugPrint('[Phone App] User logged out. Clearing local data...');
      _firstSync = true;
      
      // Clear persistence cache immediately to prevent Smart Merge from uploading old data
      final prefs = appPrefs; 
      if (prefs != null) {
        prefs.remove(_keyChiTheoMuc);
        prefs.remove(_keyLichSuThang);
      } else {
        SharedPreferences.getInstance().then((p) {
           p.remove(_keyChiTheoMuc);
           p.remove(_keyLichSuThang);
        });
      }

      for (final muc in ChiTieuMuc.values) {
        if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
        _chiTheoMuc[muc] = <ChiTieuItem>[];
      }
      _lichSuThang.clear();
      _invalidateCache();
      if (mounted) setState(() {});
    }
  }
  
  bool _firstSync = true;
  
  /// Cloud First: Called when Firestore transactions change (from any device)
  void _onTransactionsChanged(List<TransactionDoc> transactions) async {
    // On first sync after login, CLEAR local data to prevent any duplication.
    // Then upload any pending migration data captured before login.
    if (_firstSync) {
      _firstSync = false;
      debugPrint('[Phone App] First sync after login. Clearing local data to start fresh from cloud...');
      
      // Clear SharedPreferences
      final prefs = appPrefs; 
      if (prefs != null) {
        await prefs.remove(_keyChiTheoMuc);
        await prefs.remove(_keyLichSuThang);
      } else {
        final p = await SharedPreferences.getInstance();
        await p.remove(_keyChiTheoMuc);
        await p.remove(_keyLichSuThang);
      }
      
      // Clear in-memory data
      for (final muc in ChiTieuMuc.values) {
        if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
        _chiTheoMuc[muc] = <ChiTieuItem>[];
      }
      _lichSuThang.clear();
      
      // Upload pending Guest migration data (if any)
      if (pendingMigrationData != null && pendingMigrationData!.isNotEmpty) {
        debugPrint('[Phone App] Uploading ${pendingMigrationData!.length} Guest items to new account...');
        try {
          final batch = FirebaseFirestore.instance.batch();
          final uid = authService.currentUser?.uid;
          if (uid != null) {
            final baseRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions');
            for (final item in pendingMigrationData!) {
              final doc = baseRef.doc();
              batch.set(doc, {
                'muc': item['muc'],
                'soTien': item['soTien'],
                'thoiGian': Timestamp.fromDate(DateTime.parse(item['thoiGian'])),
                'ghiChu': item['ghiChu'],
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            await batch.commit();
            debugPrint('[Phone App] Guest data migration successful!');
          }
        } catch (e) {
          debugPrint('[Phone App] Guest data migration failed: $e');
        } finally {
          pendingMigrationData = null; // Clear to prevent re-upload
        }
        return; // Stream will fire again with uploaded data
      }
    }

    // Standard Sync: Rebuild _chiTheoMuc from Firestore data
    for (final muc in ChiTieuMuc.values) {
      if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
      _chiTheoMuc[muc] = <ChiTieuItem>[];
    }
    _lichSuThang.clear();
    
    for (final tx in transactions) {
      try {
        final muc = ChiTieuMuc.values.firstWhere((m) => m.name == tx.muc);
        final item = ChiTieuItem(
          id: tx.id,
          soTien: tx.soTien, 
          thoiGian: tx.thoiGian,
          tenChiTieu: tx.ghiChu,
          subCategory: tx.subCategory,
        );
        
        if (_sameDay(item.thoiGian, _currentDay)) {
          _chiTheoMuc[muc]!.add(item);
        } else {
          // Add to history
          final monthKey = getMonthKey(item.thoiGian);
          final dayKey = dinhDangNgayDayDu(item.thoiGian);
          _lichSuThang.putIfAbsent(monthKey, () => {});
          _lichSuThang[monthKey]!.putIfAbsent(dayKey, () => []);
          _lichSuThang[monthKey]![dayKey]!.add(HistoryEntry(muc: muc, item: item));
        }
      } catch (_) {}
    }
    
    
    _invalidateCache();
    if (mounted) setState(() {});
    
    // Update Home Widget
    _updateWidget();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayCheckTimer?.cancel();
    _transactionsSub?.cancel(); // Cloud First: cancel Firestore subscription
    _authStateSub?.cancel(); // Cancel auth state listener
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNavigation();
    }
  }

  Future<void> _checkPendingNavigation() async {
    const channel = MethodChannel('vfinance/navigation');
    try {
      final String? route = await channel.invokeMethod('getLaunchRoute');
      if (route != null && mounted) {
        // Reset to root first to avoid stacking screens
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        if (route == 'add_income') {
           _moMuc(ChiTieuMuc.soDu);
        } else if (route == 'home') {
           setState(() => _selectedIndex = 2);
        }
      }
    } catch(e) {
      debugPrint('Nav error: $e');
    }
  }

  void _updateWidget() {
    try {
      // Calculate values using existing getters
      final balance = _allTimeIncome - _allTimeExpenses;
      final income = _monthlyIncome;
      final expense = _monthlyExpenses;
      final displayName = FirebaseAuth.instance.currentUser?.displayName;
      
      // Calculate daily expense from _chiTheoMuc (which contains today's items)
      int dailyExpense = 0;
      for (final muc in ChiTieuMuc.values) {
        if (muc == ChiTieuMuc.soDu || muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
        final items = _chiTheoMuc[muc] ?? [];
        for (final item in items) {
           dailyExpense += item.soTien;
        }
      }
      
      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}';

      _widgetService.updateWidgetData(
        balance: balance, 
        income: income, 
        expense: expense,
        appLanguage: appLanguage,
        displayName: displayName,
        dailyExpense: dailyExpense,
        dateString: dateStr,
      );
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }

  Future<void> _loadData() async {
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    
    final savedLanguage = prefs.getString(keyLanguage);
    if (savedLanguage == 'auto' || savedLanguage == null) {
      // Auto-detect device language
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      appLanguage = deviceLocale == 'vi' ? 'vi' : 'en';
      appLanguageMode = 'auto';
      if (savedLanguage == null) {
        await prefs.setString(keyLanguage, 'auto');
      }
    } else {
      appLanguage = savedLanguage;
      appLanguageMode = savedLanguage;
    }
    
    // Cloud First: Only load transaction data from SharedPreferences for guest mode
    // When logged in, Firestore is the single source of truth
    if (!transactionService.isLoggedIn) {
      final chiTheoMucJson = prefs.getString(_keyChiTheoMuc);
      if (chiTheoMucJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(chiTheoMucJson);
          for (final muc in ChiTieuMuc.values) {
            if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
            final mucName = muc.name;
            if (decoded.containsKey(mucName)) {
              final List<dynamic> items = decoded[mucName];
              _chiTheoMuc[muc] = items.map((e) => ChiTieuItem.fromJson(e as Map<String, dynamic>)).toList();
            }
          }
        } catch (_) {}
      }
      
      final lichSuThangJson = prefs.getString(_keyLichSuThang);
      if (lichSuThangJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(lichSuThangJson);
          for (final monthKey in decoded.keys) {
            final Map<String, dynamic> daysData = decoded[monthKey];
            _lichSuThang[monthKey] = {};
            for (final dayKey in daysData.keys) {
              final List<dynamic> entries = daysData[dayKey];
              _lichSuThang[monthKey]![dayKey] = entries.map((e) {
                final mucName = e['muc'] as String;
                final muc = ChiTieuMuc.values.firstWhere((m) => m.name == mucName);
                final item = ChiTieuItem.fromJson(e['item'] as Map<String, dynamic>);
                return HistoryEntry(muc: muc, item: item);
              }).toList();
            }
          }
        } catch (_) {}
      }
    }
    
    _invalidateCache();
    
    if (mounted) {
      setState(() => _isLoading = false);
      FlutterNativeSplash.remove();
    }
    
    // Update Home Widget logic
    _updateWidget();
  }
  
  // Cloud First: Migration no longer needed - TransactionService handles all data

  Future<void> _saveData() async {
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    
    // Cloud First: Only save transaction data to SharedPreferences for guest mode
    // When logged in, Firestore handles all transaction data
    if (!transactionService.isLoggedIn) {
      final Map<String, dynamic> chiTheoMucData = {};
      for (final muc in ChiTieuMuc.values) {
        if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
        chiTheoMucData[muc.name] = _chiTheoMuc[muc]!.map((e) => e.toJson()).toList();
      }
      await prefs.setString(_keyChiTheoMuc, jsonEncode(chiTheoMucData));
      
      final Map<String, dynamic> lichSuThangData = {};
      for (final monthKey in _lichSuThang.keys) {
        lichSuThangData[monthKey] = {};
        for (final dayKey in _lichSuThang[monthKey]!.keys) {
          lichSuThangData[monthKey][dayKey] = _lichSuThang[monthKey]![dayKey]!.map((e) => {
            'muc': e.muc.name,
            'item': e.item.toJson(),
          }).toList();
        }
      }
      await prefs.setString(_keyLichSuThang, jsonEncode(lichSuThangData));
    }
    
    // Save language setting
    await prefs.setString('app_language', appLanguage);
    
    // Update Home Widget
    _updateWidget();
  }

  void _checkNewDay() {
    final now = DateTime.now();
    if (!_sameDay(now, _currentDay)) {
      if (mounted) {
        setState(() {
          _luuLichSuNgayHomQua();
          _currentDay = _asDate(now);
          _invalidateCache();
        });
        _saveData();
      }
    }
  }

  void _luuLichSuNgayHomQua() {
    final ngayHomQua = _currentDay;
    final monthKey = getMonthKey(ngayHomQua);
    final dayKey = dinhDangNgayDayDu(ngayHomQua);

    final List<HistoryEntry> entries = [];
    _chiTheoMuc.forEach((muc, items) {
      if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) return;
      final itemsNgayHomQua = items.where((item) => _sameDay(item.thoiGian, ngayHomQua)).toList();
      for (final it in itemsNgayHomQua) {
        entries.add(HistoryEntry(muc: muc, item: it));
      }
    });

    if (entries.isNotEmpty) {
      _lichSuThang.putIfAbsent(monthKey, () => {});
      _lichSuThang[monthKey]![dayKey] = entries;

      for (final muc in ChiTieuMuc.values) {
        if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) continue;
        _chiTheoMuc[muc] = _chiTheoMuc[muc]!.where((item) => !_sameDay(item.thoiGian, ngayHomQua)).toList();
      }
    }
  }

  void _capNhatLichSuSauThayDoi(ChiTieuMuc muc, List<ChiTieuItem> danhSachMoi) {
    _chiTheoMuc[muc] = danhSachMoi.where((item) => _sameDay(item.thoiGian, _currentDay)).toList();

    final monthKey = getMonthKey(_currentDay);
    final dayKey = dinhDangNgayDayDu(_currentDay);

    final List<HistoryEntry> allCurrentDayEntries = [];
    _chiTheoMuc.forEach((mucKey, items) {
      if (mucKey == ChiTieuMuc.lichSu || mucKey == ChiTieuMuc.caiDat) return;
      for (final it in items.where((item) => _sameDay(item.thoiGian, _currentDay))) {
        allCurrentDayEntries.add(HistoryEntry(muc: mucKey, item: it));
      }
    });

    _lichSuThang.putIfAbsent(monthKey, () => {});
    _lichSuThang[monthKey]![dayKey] = allCurrentDayEntries;
    _invalidateCache();
    setState(() {});
    _saveData();
  }

  int _tongMuc(ChiTieuMuc muc) {
    if (_cachedTongMuc.containsKey(muc)) return _cachedTongMuc[muc]!;
    final list = _chiTheoMuc[muc] ?? <ChiTieuItem>[];
    final total = list.fold(0, (a, b) => _sameDay(b.thoiGian, _currentDay) ? a + b.soTien : a);
    _cachedTongMuc[muc] = total;
    return total;
  }

  int get _tongHomNay {
    if (_cachedTongHomNay != null) return _cachedTongHomNay!;
    _cachedTongHomNay = _chiTheoMuc.entries.fold<int>(0, (sum, entry) {
      if (entry.key == ChiTieuMuc.soDu || entry.key == ChiTieuMuc.lichSu || entry.key == ChiTieuMuc.caiDat) return sum;
      return sum + entry.value.fold<int>(0, (a, b) => _sameDay(b.thoiGian, _currentDay) ? a + b.soTien : a);
    });
    return _cachedTongHomNay!;
  }

  int get _monthlyIncome {
    final currentMonthKey = getMonthKey(_currentDay);
    final todayDayKey = dinhDangNgayDayDu(_currentDay);
    
    int totalIncome = (_chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
        .where((item) => _sameDay(item.thoiGian, _currentDay))
        .fold(0, (sum, item) => sum + item.soTien);
    
    final currentMonthData = _lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc == ChiTieuMuc.soDu) {
            totalIncome += entry.item.soTien;
          }
        }
      }
    }
    return totalIncome;
  }

  int get _monthlyExpenses {
    final currentMonthKey = getMonthKey(_currentDay);
    final todayDayKey = dinhDangNgayDayDu(_currentDay);
    
    int totalExpenses = _tongHomNay;
    
    final currentMonthData = _lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc != ChiTieuMuc.soDu) {
            totalExpenses += entry.item.soTien;
          }
        }
      }
    }
    return totalExpenses;
  }
  
  /// All-time income (sum of ALL soDu entries across ALL history)
  int get _allTimeIncome {
    final todayDayKey = dinhDangNgayDayDu(_currentDay);
    final currentMonthKey = getMonthKey(_currentDay);
    
    // Today's income (from _chiTheoMuc)
    int total = (_chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
        .where((item) => _sameDay(item.thoiGian, _currentDay))
        .fold(0, (sum, item) => sum + item.soTien);
    
    // All history income (excluding today to avoid double-counting)
    for (final monthEntry in _lichSuThang.entries) {
      for (final dayEntry in monthEntry.value.entries) {
        // Skip today's data since it's already counted from _chiTheoMuc
        if (monthEntry.key == currentMonthKey && dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc == ChiTieuMuc.soDu) {
            total += entry.item.soTien;
          }
        }
      }
    }
    return total;
  }
  
  /// All-time expenses (sum of ALL expense entries across ALL history)
  int get _allTimeExpenses {
    final todayDayKey = dinhDangNgayDayDu(_currentDay);
    final currentMonthKey = getMonthKey(_currentDay);
    
    // Today's expenses (from _tongHomNay)
    int total = _tongHomNay;
    
    // All history expenses (excluding today to avoid double-counting)
    for (final monthEntry in _lichSuThang.entries) {
      for (final dayEntry in monthEntry.value.entries) {
        // Skip today's data since it's already counted from _tongHomNay
        if (monthEntry.key == currentMonthKey && dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc != ChiTieuMuc.soDu) {
            total += entry.item.soTien;
          }
        }
      }
    }
    return total;
  }
  

  Future<void> _moMuc(ChiTieuMuc muc) async {
    if (muc == ChiTieuMuc.soDu) {
      final danhSachThuNhap = (_chiTheoMuc[muc] ?? [])
          .where((item) => _sameDay(item.thoiGian, _currentDay)).toList();
      
      int tongChiLichSu = 0;
      for (final monthData in _lichSuThang.values) {
        for (final dayData in monthData.values) {
          for (final entry in dayData) {
            if (entry.muc != ChiTieuMuc.soDu) tongChiLichSu += entry.item.soTien;
          }
        }
      }

      final updated = await Navigator.push<List<ChiTieuItem>>(
        context,
        MaterialPageRoute(
          builder: (_) => SoDuScreen(
            danhSachThuNhap: danhSachThuNhap,
            tongChiHomNay: _tongHomNay,
            tongChiLichSu: tongChiLichSu,
            currentDay: _currentDay,
            onDataChanged: (newList) => _capNhatLichSuSauThayDoi(muc, newList),
          ),
        ),
      );

      // Only use returned data for guest mode; logged in users get data from Firestore stream
      if (updated != null && !transactionService.isLoggedIn) {
        _capNhatLichSuSauThayDoi(muc, updated);
      }
      return;
    }

    // History and Settings are now handled by bottom navigation bar
    if (muc == ChiTieuMuc.lichSu) {
      setState(() => _selectedIndex = 3); // Switch to History tab
      return;
    }

    if (muc == ChiTieuMuc.caiDat) {
      setState(() => _selectedIndex = 4); // Switch to Settings tab
      return;
    }

    if (muc == ChiTieuMuc.khac) {
      final danhSachChiHienTai = (_chiTheoMuc[muc] ?? [])
          .where((item) => _sameDay(item.thoiGian, _currentDay)).toList();

      final updated = await Navigator.push<List<ChiTieuItem>>(
        context,
        MaterialPageRoute(
          builder: (_) => KhacTheoMucScreen(
            danhSachChiBanDau: danhSachChiHienTai,
            currentDay: _currentDay,
            onDataChanged: (newList) => _capNhatLichSuSauThayDoi(muc, newList),
          ),
        ),
      );

      // Only use returned data for guest mode; logged in users get data from Firestore stream
      if (updated != null && !transactionService.isLoggedIn) {
        _capNhatLichSuSauThayDoi(muc, updated);
      }
      return;
    }

    final danhSachChiHienTai = (_chiTheoMuc[muc] ?? [])
        .where((item) => _sameDay(item.thoiGian, _currentDay)).toList();

    final updated = await Navigator.push<List<ChiTieuItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => ChiTieuTheoMucScreen(
          muc: muc,
          danhSachChiBanDau: danhSachChiHienTai,
          currentDay: _currentDay,
          onDataChanged: (newList) => _capNhatLichSuSauThayDoi(muc, newList),
        ),
      ),
    );

    // Only use returned data for guest mode; logged in users get data from Firestore stream
    if (updated != null && !transactionService.isLoggedIn) {
      _capNhatLichSuSauThayDoi(muc, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build the 5 navigation screens
    final screens = [
      // 0: Statistics
      StatisticsScreen(
        chiTheoMuc: _chiTheoMuc,
        lichSuThang: _lichSuThang,
        currentDay: _currentDay,
        isVisible: _selectedIndex == 0,
      ),
      // 1: Budget
      BudgetScreen(
        chiTheoMuc: _chiTheoMuc,
        lichSuThang: _lichSuThang,
        currentDay: _currentDay,
        isVisible: _selectedIndex == 1,
      ),
      // 2: Home (center)
      HomeScreen(
        chiTheoMuc: _chiTheoMuc,
        lichSuThang: _lichSuThang,
        currentDay: _currentDay,
        allTimeIncome: _allTimeIncome,
        allTimeExpenses: _allTimeExpenses,
        monthlyIncome: _monthlyIncome,
        monthlyExpenses: _monthlyExpenses,
        tongHomNay: _tongHomNay,
        onCategoryTap: _moMuc,
      ),
      // 3: History
      HistoryScreen(
        lichSuThang: _lichSuThang,
        currentDay: _currentDay,
        currentData: _chiTheoMuc,
      ),
      // 4: Settings
      SettingsScreen(
        onLanguageChanged: () {
          if (mounted) {
            setState(() {});
            _saveData();
          }
        },
        chiTheoMuc: _chiTheoMuc,
        lichSuThang: _lichSuThang,
      ),
    ];

    return Scaffold(
      appBar: _selectedIndex == 2 ? AppBar(
        title: const Text('VFinance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        indicatorColor: const Color(0xff4CEEC8),
        destinations: [
          NavigationDestination(
            icon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.pie_chart_outline)),
            selectedIcon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.pie_chart)),
            label: appLanguage == 'vi' ? 'Thống kê' : 'Stats',
          ),
          NavigationDestination(
            icon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.account_balance_wallet_outlined)),
            selectedIcon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.account_balance_wallet)),
            label: appLanguage == 'vi' ? 'Ngân sách' : 'Budget',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_outlined, color: primaryColor),
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white),
            ),
            label: appLanguage == 'vi' ? 'Trang chủ' : 'Home',
          ),
          NavigationDestination(
            icon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.history_outlined)),
            selectedIcon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.history)),
            label: appLanguage == 'vi' ? 'Lịch sử' : 'History',
          ),
          NavigationDestination(
            icon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.settings_outlined)),
            selectedIcon: Container(height: 40, alignment: Alignment.center, child: const Icon(Icons.settings)),
            label: appLanguage == 'vi' ? 'Cài đặt' : 'Settings',
          ),
        ],
      ),
    );
  }
}

