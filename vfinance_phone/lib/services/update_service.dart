import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // For appLanguage

/// Self-hosted in-app update service using GitHub releases
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // GitHub raw URL for version.json
  static const String _versionJsonUrl = 
      'https://raw.githubusercontent.com/vochicuongg/QuanLyChiTieu_Android/main/version.json';

  bool _isChecking = false;

  /// Extract semantic version including build number
  String _extractSemVer(String version) {
    // Match X.Y.Z potentially followed by +build
    final match = RegExp(r'^(\d+\.\d+\.\d+(\+[a-zA-Z0-9\.-]+)?)').firstMatch(version);
    return match?.group(1) ?? '0.0.0';
  }

  /// Check for updates
  /// [isManual] - If true, shows "up to date" message when no update available
  Future<void> checkForUpdate(BuildContext context, {bool isManual = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = _extractSemVer(packageInfo.version);
      final currentVersion = Version.parse(currentVersionStr);

      // Fetch remote version info
      final response = await http.get(Uri.parse(_versionJsonUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (isManual && context.mounted) {
          _showSnackBar(context, appLanguage == 'vi' 
              ? 'Không thể kiểm tra cập nhật' 
              : 'Unable to check for updates');
        }
        return;
      }

      final data = jsonDecode(response.body);
      final remoteVersionStr = data['version'] as String;
      final downloadUrl = data['downloadUrl'] as String;
      final releaseNotes = data['releaseNotes'] as String? ?? '';

      final remoteVersion = Version.parse(remoteVersionStr);

      // Compare versions (including build number if main versions are equal)
      bool hasUpdate = remoteVersion > currentVersion;
      
      // If main versions are equal, check build numbers
      if (!hasUpdate && remoteVersion == currentVersion) {
        final remoteBuild = remoteVersion.build;
        final currentBuild = currentVersion.build;
        
        if (remoteBuild.isNotEmpty && currentBuild.isNotEmpty) {
           // Compare first build component if integers
           try {
             final r = int.parse(remoteBuild.first.toString());
             final c = int.parse(currentBuild.first.toString());
             if (r > c) hasUpdate = true;
           } catch (_) {}
        }
      }

      if (hasUpdate) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            downloadUrl: downloadUrl,
            newVersion: remoteVersionStr,
            currentVersion: packageInfo.version,
            releaseNotes: releaseNotes,
          );
        }
      } else if (isManual && context.mounted) {
        _showSnackBar(context, appLanguage == 'vi' 
            ? 'Bạn đang sử dụng phiên bản mới nhất!' 
            : 'You are using the latest version!');
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      if (isManual && context.mounted) {
        _showSnackBar(context, appLanguage == 'vi' 
            ? 'Lỗi kiểm tra cập nhật: $e' 
            : 'Update check error: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUpdateDialog(
    BuildContext context, {
    required String downloadUrl,
    required String newVersion,
    required String currentVersion,
    required String releaseNotes,
  }) {
    final isVi = appLanguage == 'vi';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF4CAF93)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isVi ? 'Cập nhật mới' : 'Update Available',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVi 
                  ? 'Phiên bản mới $newVersion đã sẵn sàng!'
                  : 'Version $newVersion is available!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isVi 
                  ? 'Phiên bản hiện tại: $currentVersion'
                  : 'Current version: $currentVersion',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                isVi ? 'Có gì mới:' : 'What\'s new:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  releaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isVi ? 'Để sau' : 'Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadApk(context, downloadUrl);
            },
            icon: const Icon(Icons.download, size: 18),
            label: Text(isVi ? 'Tải xuống' : 'Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF93),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadApk(BuildContext context, String url) async {
    final isVi = appLanguage == 'vi';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          _showSnackBar(context, isVi 
              ? 'Đang mở trình tải xuống...' 
              : 'Opening download...');
        }
      } else {
        if (context.mounted) {
          _showSnackBar(context, isVi 
              ? 'Không thể mở liên kết tải xuống' 
              : 'Unable to open download link');
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        _showSnackBar(context, isVi 
            ? 'Lỗi tải xuống: $e' 
            : 'Download error: $e');
      }
    }
  }
}
