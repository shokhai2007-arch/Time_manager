import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoUpdater {
  static const String _repoUrl =
      'https://api.github.com/repos/shokhai2007-arch/Time_manager/releases/latest';

  static Future<bool> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersionTag = data['tag_name'] as String;
        final apkUrl = _getApkUrl(data['assets']);

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion =
            packageInfo.version; // Typically something like 1.0.0

        // In a real app we'd parse semver properly. For simplicity, we just check if it contains the version
        // or just consider any mismatch / specific naming convention.
        // As a simple example:
        if (latestVersionTag != 'v$currentVersion' && apkUrl != null) {
          // Trigger URL launcher to download/install
          await launchUrl(Uri.parse(apkUrl),
              mode: LaunchMode.externalApplication);
          return true;
        }
      }
    } catch (e) {
      // Handle error implicitly
    }
    return false;
  }

  static String? _getApkUrl(List<dynamic> assets) {
    for (var asset in assets) {
      if (asset['name'].toString().endsWith('.apk')) {
        return asset['browser_download_url'];
      }
    }
    return null;
  }
}
