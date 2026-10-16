import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:hearme/core/constants/api_constants.dart';
import 'package:hearme/core/theme/app_theme.dart';

class AppUpdateService {
  static bool _hasPromptedThisSession = false;

  /// Silently check for update on app startup
  static Future<void> checkForUpdatesSilently(BuildContext context) async {
    if (_hasPromptedThisSession) return;
    try {
      final res = await http.get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.v2AppVersion}')).timeout(
        const Duration(seconds: 4),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverVersionCode = data['versionCode'] as int? ?? 1;
        if (serverVersionCode > ApiConstants.currentVersionCode) {
          _hasPromptedThisSession = true;
          if (context.mounted) {
            _showUpdateDialog(context, data);
          }
        }
      }
    } catch (_) {
      // Ignore network timeout on silent check
    }
  }

  /// Manually check for updates (e.g. from Settings or Drawer)
  static Future<void> checkForUpdatesManually(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryOrange),
                SizedBox(width: 16),
                Text('Checking for latest updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await http.get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.v2AppVersion}')).timeout(
        const Duration(seconds: 8),
      );
      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverVersionCode = data['versionCode'] as int? ?? 1;
        if (serverVersionCode > ApiConstants.currentVersionCode) {
          if (context.mounted) {
            _showUpdateDialog(context, data);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('MindSpace is up to date (v${ApiConstants.currentAppVersion})'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach update server: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, Map<String, dynamic> data) {
    final newVersion = data['version'] ?? 'Latest';
    final releaseNotes = data['releaseNotes'] ?? 'Performance improvements and bug fixes.';
    final apkUrl = data['apkUrl'] ?? '';
    final forceUpdate = data['forceUpdate'] == true;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_rounded, color: AppTheme.primaryOrange, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Update Available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Version $newVersion (Current: v${ApiConstants.currentAppVersion})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s New in this update:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                releaseNotes,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap "Update Now" to automatically install the latest build on your phone without losing your data.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              if (apkUrl.isNotEmpty) {
                final uri = Uri.parse(apkUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
              if (context.mounted && !forceUpdate) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
