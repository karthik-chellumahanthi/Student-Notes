import 'package:package_info_plus/package_info_plus.dart';
import 'remote_config_service.dart';
import 'dart:math' as math;

class UpdateService {
  static Future<bool> needsForceUpdate() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    String currentVersion = info.version;

    return RemoteConfigService.forceUpdate &&
        _isVersionLower(currentVersion, RemoteConfigService.minVersion);
  }

  static Future<bool> hasOptionalUpdate() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    String currentVersion = info.version;

    return _isVersionLower(currentVersion, RemoteConfigService.latestVersion);
  }

  // Helper to accurately compare semantic versions like 1.0.1 vs 1.0.10
  static bool _isVersionLower(String current, String required) {
    try {
      List<int> curr = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> req = required.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < math.max(curr.length, req.length); i++) {
        int c = i < curr.length ? curr[i] : 0;
        int r = i < req.length ? req[i] : 0;
        if (c < r) return true;
        if (c > r) return false;
      }
      return false; // Equal versions
    } catch (e) {
      return false; // Fallback safely
    }
  }
}
