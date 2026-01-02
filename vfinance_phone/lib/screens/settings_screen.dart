import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';

/// Settings Screen - App settings with account, language, currency, theme
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLanguageChanged;
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;

  const SettingsScreen({
    super.key,
    this.onLanguageChanged,
    required this.chiTheoMuc,
    required this.lichSuThang,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage == 'vi' ? 'Cài đặt' : 'Settings', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Card
          _buildAccountCard(),
          const SizedBox(height: 8),
          // Language
          _buildLanguageCard(),
          const SizedBox(height: 8),
          // Theme
          _buildThemeCard(),
          const SizedBox(height: 8),
          // Check for Updates
          _buildUpdateCard(),
          const SizedBox(height: 8),
          
          // QR Code
          _buildQrCard(),
          const SizedBox(height: 8),
          // Version
          _buildVersionCard(),
          const SizedBox(height: 8),
          
          // Backup/Restore (logged in only)
          if (authService.currentUser != null) ...[
            const SizedBox(height: 24),
            Text(appLanguage == 'vi' ? 'Sao lưu & Khôi phục' : 'Backup & Restore',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 8),
            _buildBackupCard(),
            const SizedBox(height: 8),
            _buildRestoreCard(),
            const SizedBox(height: 8),
            _buildLogoutCard(),
          ] else ...[
            const SizedBox(height: 24),
            _buildLoginCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard() => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: authService.currentUser?.photoURL != null ? NetworkImage(authService.currentUser!.photoURL!) : null,
        child: authService.currentUser?.photoURL == null ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Text(authService.currentUser?.displayName ?? (appLanguage == 'vi' ? 'Khách' : 'Guest'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(authService.currentUser?.email ?? (appLanguage == 'vi' ? 'Chưa đăng nhập' : 'Not logged in'), style: const TextStyle(fontSize: 13)),
    ),
  );

  Widget _buildLanguageCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.language),
      title: Text(appLanguage == 'vi' ? 'Ngôn ngữ' : 'Language', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguageMode == 'auto' ? (appLanguage == 'vi' ? '📱 Tự động' : '📱 Auto') : (appLanguageMode == 'vi' ? '🇻🇳 Tiếng Việt' : '🇺🇸 English')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(),
    ),
  );



  Widget _buildThemeCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.brightness_6),
      title: Text(appLanguage == 'vi' ? 'Giao diện' : 'Theme', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguage == 'vi' ? appThemeMode == 'light' ? '🌕 Sáng' : appThemeMode == 'dark' ? '🌑 Tối' : '🌗 Hệ thống' : appThemeMode == 'light' ? '🌕 Light' : appThemeMode == 'dark' ? '🌑 Dark' : '🌗 System'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(),
    ),
  );

  Widget _buildVersionCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(appLanguage == 'vi' ? 'Phiên bản' : 'Version', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('1.0.0.adr-vochicuongg'),
      onTap: () => _showVersionDialog(),
    ),
  );

  Widget _buildUpdateCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.system_update),
      title: Text(appLanguage == 'vi' ? 'Kiểm tra cập nhật' : 'Check for Updates', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguage == 'vi' ? 'Tải phiên bản mới nhất' : 'Download the latest version'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => UpdateService().checkForUpdate(context, isManual: true),
    ),
  );

  Widget _buildQrCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.qr_code),
      title: Text(appLanguage == 'vi' ? 'Mã QR liên hệ' : 'Contact QR Code', style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => _showQRCodeDialog(),
    ),
  );

  Widget _buildBackupCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.cloud_upload, color: Colors.blue),
      title: Text(appLanguage == 'vi' ? 'Sao lưu dữ liệu' : 'Backup Data', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguage == 'vi' ? 'Lưu lên đám mây' : 'Save to cloud'),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLanguage == 'vi' ? 'Đang sao lưu...' : 'Backing up...')));
        final prefs = appPrefs ?? await SharedPreferences.getInstance();
        final allData = <String, dynamic>{for (var k in prefs.getKeys()) k: prefs.get(k)};
        await authService.backupData(allData);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLanguage == 'vi' ? 'Sao lưu thành công!' : 'Backup complete!')));
      },
    ),
  );

  Widget _buildRestoreCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.cloud_download, color: Colors.green),
      title: Text(appLanguage == 'vi' ? 'Khôi phục dữ liệu' : 'Restore Data', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguage == 'vi' ? 'Tải từ đám mây' : 'Download from cloud'),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLanguage == 'vi' ? 'Đang khôi phục...' : 'Restoring...')));
        final data = await authService.restoreData();
        if (data != null) {
          final prefs = appPrefs ?? await SharedPreferences.getInstance();
          for (final e in data.entries) {
            if (e.value is String) await prefs.setString(e.key, e.value);
            else if (e.value is int) await prefs.setInt(e.key, e.value);
            else if (e.value is double) await prefs.setDouble(e.key, e.value);
            else if (e.value is bool) await prefs.setBool(e.key, e.value);
          }
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appLanguage == 'vi' ? 'Khôi phục thành công!' : 'Restored!')));
        }
      },
    ),
  );

  Widget _buildLogoutCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: Text(appLanguage == 'vi' ? 'Đăng xuất' : 'Log Out', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      onTap: () async {
        final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
          title: Text(appLanguage == 'vi' ? 'Đăng xuất?' : 'Log Out?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(appLanguage == 'vi' ? 'Đăng xuất' : 'Log Out', style: const TextStyle(color: Colors.red))),
          ],
        ));
        if (confirm == true) {
          await authService.signOut();
          final prefs = appPrefs ?? await SharedPreferences.getInstance();
          await prefs.setBool('skipped_login', false);
          if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthWrapper()), (r) => false);
        }
      },
    ),
  );

  Widget _buildLoginCard() => Card(
    child: ListTile(
      leading: const Icon(Icons.login, color: Colors.blue),
      title: Text(appLanguage == 'vi' ? 'Đăng nhập' : 'Sign In', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      subtitle: Text(appLanguage == 'vi' ? 'Đăng nhập để đồng bộ dữ liệu' : 'Sign in to sync data'),
      onTap: () {
        // Capture guest data for migration
        final dataToMigrate = <Map<String, dynamic>>[];
        widget.chiTheoMuc.forEach((muc, items) {
          for (var item in items) dataToMigrate.add({'muc': muc.name, 'soTien': item.soTien, 'thoiGian': item.thoiGian.toIso8601String(), 'ghiChu': item.tenChiTieu});
        });
        widget.lichSuThang.forEach((_, days) => days.forEach((_, entries) {
          for (var e in entries) dataToMigrate.add({'muc': e.muc.name, 'soTien': e.item.soTien, 'thoiGian': e.item.thoiGian.toIso8601String(), 'ghiChu': e.item.tenChiTieu});
        }));
        if (dataToMigrate.isNotEmpty) pendingMigrationData = dataToMigrate;
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(
          onLoginSuccess: () { Navigator.pop(context); if (mounted) setState(() {}); },
          onSkip: () { pendingMigrationData = null; Navigator.pop(context); },
        )));
      },
    ),
  );

  void _showLanguageDialog() async {
    final newLang = await showDialog<String>(context: context, builder: (c) => SimpleDialog(
      title: Text(appLanguage == 'vi' ? 'Chọn ngôn ngữ' : 'Select Language'),
      children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'vi'), child: const Text('🇻🇳 Tiếng Việt')),
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'en'), child: const Text('🇺🇸 English')),
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'auto'), child: Text(appLanguage == 'vi' ? '📱 Tự động' : '📱 Auto')),
      ],
    ));
    if (newLang != null && newLang != appLanguageMode) {
      setState(() {
        appLanguageMode = newLang;
        appLanguage = newLang == 'auto' ? (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'vi' ? 'vi' : 'en') : newLang;
      });
      final prefs = appPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(keyLanguage, newLang);
      widget.onLanguageChanged?.call();
    }
  }



  void _showThemeDialog() async {
    final newTheme = await showDialog<String>(context: context, builder: (c) => SimpleDialog(
      title: Text(appLanguage == 'vi' ? 'Chọn giao diện' : 'Select Theme'),
      children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'light'), child: Text(appLanguage=='vi'?'🌕 Sáng':'🌕 Light')),
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'dark'), child: Text(appLanguage=='vi'?'🌑 Tối':'🌑 Dark')),
        SimpleDialogOption(onPressed: () => Navigator.pop(c, 'system'), child: Text(appLanguage=='vi'?'🌗 Hệ thống':'🌗 System')),
      ],
    ));
    if (newTheme != null && newTheme != appThemeMode) setState(() => setThemeMode(newTheme));
  }

  void _showVersionDialog() => showDialog(context: context, builder: (c) => AlertDialog(
    title: const Text('VFinance', textAlign: TextAlign.center),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('1.0.0.adr-vochicuongg', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(appLanguage == 'vi' ? 'Quản lý chi tiêu\n© 2025-vochicuongg.' : 'Expense Manager\n© 2025-vochicuongg.', textAlign: TextAlign.center),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(appLanguage == 'vi' ? 'Đóng' : 'Close'))],
  ));

  void _showQRCodeDialog() => showDialog(context: context, builder: (c) => AlertDialog(
    title: const Text('QR Code', textAlign: TextAlign.center),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/images/qr_code.png', width: 200, height: 200),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(appLanguage == 'vi' ? 'Đóng' : 'Close'))],
  ));
}


