import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens.dart';
import 'services/auth_service.dart';
import 'services/transaction_service.dart'; // Cloud First: Firestore as single source of truth
import 'screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =================== GLOBAL STATE ===================
SharedPreferences? appPrefs;
String appLanguage = 'vi';
String appLanguageMode = 'auto'; // 'vi', 'en', or 'auto'
const String keyLanguage = 'app_language';
String appCurrency = 'đ';
const String keyCurrency = 'app_currency';
double exchangeRate = 0.00004;
const String keyExchangeRate = 'exchange_rate';
bool isLoadingRate = false;

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
const Color primaryColor = Color(0xFF6C5CE7);
const Color primaryLightColor = Color(0xFFA29BFE);

// Dark theme colors
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

// =================== CURRENCY ===================
Future<double> fetchExchangeRate() async {
  try {
    isLoadingRate = true;
    final response = await http.get(
      Uri.parse('https://open.er-api.com/v6/latest/VND'),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usdRate = data['rates']['USD'];
      if (usdRate != null) {
        exchangeRate = (usdRate as num).toDouble();
        final prefs = appPrefs ?? await SharedPreferences.getInstance();
        await prefs.setDouble(keyExchangeRate, exchangeRate);
      }
    }
  } catch (e) {
    debugPrint('Exchange rate fetch failed: $e');
  } finally {
    isLoadingRate = false;
  }
  return exchangeRate;
}

int convertAmount(int vndAmount) {
  if (appCurrency == 'đ') return vndAmount;
  return (vndAmount * exchangeRate).toInt();
}

String formatAmountWithCurrency(int vndAmount) {
  if (appCurrency == 'đ') {
    return '${dinhDangSo(vndAmount)} đ';
  } else {
    final usdDouble = vndAmount * exchangeRate;
    return '\$${_formatUsdWithCommas(usdDouble)}';
  }
}

String _formatUsdWithCommas(double amount) {
  final intPart = amount.truncate();
  final decimalPart = ((amount - intPart) * 100).round();
  final intStr = intPart.toString().replaceAllMapped(_numberFormatRegex, (m) => '${m[1]},');
  return '$intStr.${decimalPart.toString().padLeft(2, '0')}';
}

// =================== MODEL ===================
class ChiTieuItem {
  final String? id;
  final int soTien;
  final DateTime thoiGian;
  final String? tenChiTieu;

  ChiTieuItem({this.id, required this.soTien, required this.thoiGian, this.tenChiTieu});

  ChiTieuItem copyWith({String? id, int? soTien, DateTime? thoiGian, String? tenChiTieu}) {
    return ChiTieuItem(
      id: id ?? this.id,
      soTien: soTien ?? this.soTien,
      thoiGian: thoiGian ?? this.thoiGian,
      tenChiTieu: tenChiTieu ?? this.tenChiTieu,
    );
  }

  Map<String, dynamic> toJson() => {
    'soTien': soTien,
    'thoiGian': thoiGian.toIso8601String(),
    if (tenChiTieu != null) 'tenChiTieu': tenChiTieu,
  };

  factory ChiTieuItem.fromJson(Map<String, dynamic> json) => ChiTieuItem(
    soTien: json['soTien'] as int,
    thoiGian: DateTime.parse(json['thoiGian'] as String),
    tenChiTieu: json['tenChiTieu'] as String?,
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
      case ChiTieuMuc.nhaTro: return isVi ? 'Nhà trọ' : 'Rent';
      case ChiTieuMuc.hocPhi: return isVi ? 'Học phí' : 'Tuition';
      case ChiTieuMuc.thucAn: return isVi ? 'Thức ăn' : 'Food';
      case ChiTieuMuc.doUong: return isVi ? 'Đồ uống' : 'Drinks';
      case ChiTieuMuc.xang: return isVi ? 'Xăng' : 'Gas';
      case ChiTieuMuc.muaSam: return isVi ? 'Mua sắm' : 'Shopping';
      case ChiTieuMuc.suaXe: return isVi ? 'Sửa xe' : 'Repair';
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
      case ChiTieuMuc.doUong: return Colors.brown;
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

class _VFinanceAppState extends State<VFinanceApp> {
  DateTime _currentDay = DateTime.now();
  bool _isLoading = true;
  
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkNewDay());
    
    // Cloud First: Subscribe to Firestore when user logs in
    _setupFirestoreSubscription();
    
    // Listen to auth state changes to re-subscribe when user logs in/out
    _authStateSub = authService.authStateChanges.listen((_) {
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
  }
  
  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    _transactionsSub?.cancel(); // Cloud First: cancel Firestore subscription
    _authStateSub?.cancel(); // Cancel auth state listener
    super.dispose();
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
    
    final savedCurrency = prefs.getString(keyCurrency);
    if (savedCurrency != null) appCurrency = savedCurrency;
    
    final savedExchangeRate = prefs.getDouble(keyExchangeRate);
    if (savedExchangeRate != null) exchangeRate = savedExchangeRate;
    
    fetchExchangeRate().then((rate) {
      if (mounted) {
        setState(() {});
        _saveData();
      }
    });
    
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
    
    _invalidateCache();
    
    if (mounted) {
      setState(() => _isLoading = false);
      FlutterNativeSplash.remove();
    }
  }
  
  // Cloud First: Migration no longer needed - TransactionService handles all data

  Future<void> _saveData() async {
    final prefs = appPrefs ?? await SharedPreferences.getInstance();
    
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
    await prefs.setString('app_language', appLanguage);
    await prefs.setString('app_currency', appCurrency);
    await prefs.setDouble('exchange_rate', exchangeRate);
    
    // Cloud First: Transactions are now saved directly to Firestore via TransactionService
    // _saveData only saves settings locally
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
    // Today's income
    int total = (_chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
        .where((item) => _sameDay(item.thoiGian, _currentDay))
        .fold(0, (sum, item) => sum + item.soTien);
    
    // All history income
    for (final monthData in _lichSuThang.values) {
      for (final dayData in monthData.values) {
        for (final entry in dayData) {
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
    // Today's expenses
    int total = _tongHomNay;
    
    // All history expenses
    for (final monthData in _lichSuThang.values) {
      for (final dayData in monthData.values) {
        for (final entry in dayData) {
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

      if (updated != null) _capNhatLichSuSauThayDoi(muc, updated);
      return;
    }

    if (muc == ChiTieuMuc.lichSu) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LichSuScreen(
            lichSuThang: _lichSuThang,
            currentDay: _currentDay,
            currentData: _chiTheoMuc,
          ),
        ),
      );
      return;
    }

    if (muc == ChiTieuMuc.caiDat) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            onLanguageChanged: () {
              if (mounted) {
                setState(() {});
                _saveData();
              }
            },
            chiTheoMuc: _chiTheoMuc,
            lichSuThang: _lichSuThang,
          ),
        ),
      );
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

      if (updated != null) _capNhatLichSuSauThayDoi(muc, updated);
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

    if (updated != null) _capNhatLichSuSauThayDoi(muc, updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }


    // Balance = All-time income - All-time expenses (persists across months/years)
    final remaining = _allTimeIncome - _allTimeExpenses;
    final categories = ChiTieuMuc.values.where((m) => 
      m != ChiTieuMuc.lichSu && m != ChiTieuMuc.caiDat).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VFinance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _moMuc(ChiTieuMuc.lichSu),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _moMuc(ChiTieuMuc.caiDat),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4355F0), Color(0xFF2BC0E4), Color(0xFF4FF2C6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, ${FirebaseAuth.instance.currentUser?.displayName ?? (appLanguage == 'vi' ? 'Khách' : 'User')}.',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLanguage == 'vi' ? 'Số dư còn lại' : 'Remaining Balance',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0 
                        ? formatAmountWithCurrency(remaining)
                        : '-${formatAmountWithCurrency(remaining.abs())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BalanceInfo(
                        label: appLanguage == 'vi' ? 'Thu nhập' : 'Income',
                        amount: formatAmountWithCurrency(_monthlyIncome),
                        icon: Icons.add_circle_outline,
                        color: Colors.greenAccent,
                      ),
                      _BalanceInfo(
                        label: appLanguage == 'vi' ? 'Chi tiêu' : 'Expenses',
                        amount: formatAmountWithCurrency(_monthlyExpenses),
                        icon: Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Today's spending
            Text(
              appLanguage == 'vi'
                  ? 'Tổng chi tiêu ${_currentDay.day}/${_currentDay.month}:'
                  : 'Spending ${getMonthName(_currentDay.month)} ${getOrdinalSuffix(_currentDay.day)}:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatAmountWithCurrency(_tongHomNay),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: expenseColor),
            ),
            
            const SizedBox(height: 24),
            
            // Categories Grid
            Text(
              appLanguage == 'vi' ? 'Danh mục' : 'Categories',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final muc = categories[index];
                int displayAmount;
                if (muc == ChiTieuMuc.soDu) {
                  displayAmount = (_chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
                      .where((item) => _sameDay(item.thoiGian, _currentDay))
                      .fold(0, (sum, item) => sum + item.soTien);
                } else {
                  displayAmount = _tongMuc(muc);
                }
                
                return _MobileCategoryCard(
                  icon: muc.icon,
                  label: muc.ten,
                  amount: displayAmount,
                  color: muc.color,
                  isBalance: muc == ChiTieuMuc.soDu,
                  onTap: () => _moMuc(muc),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _BalanceInfo({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _MobileCategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;
  final bool isBalance;
  final VoidCallback onTap;

  const _MobileCategoryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.onTap,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (amount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formatAmountWithCurrency(amount),
                  style: TextStyle(
                    color: isBalance ? incomeColor : expenseColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
