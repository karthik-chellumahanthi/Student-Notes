import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1), // 1 hour for prod
        ),
      );

      // Set default values before fetching
      await _remoteConfig.setDefaults(const {
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'show_ads': false,
        'download_ad_enabled': false,
        'maintenance_mode': false,
        'maintenance_message': 'App is under maintenance. Please try again later.',
        'playstore_url': 'https://play.google.com/store/apps/details?id=com.karthik.studentnotes',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Ignore if fetch fails (e.g. offline), will use defaults or last fetched values
    }
  }

  static String get minVersion => _remoteConfig.getString('min_version');
  static String get latestVersion => _remoteConfig.getString('latest_version');
  static bool get forceUpdate => _remoteConfig.getBool('force_update');
  static bool get showAds => _remoteConfig.getBool('show_ads');
  static bool get downloadAdEnabled => _remoteConfig.getBool('download_ad_enabled');
  static bool get maintenanceMode => _remoteConfig.getBool('maintenance_mode');
  static String get maintenanceMessage => _remoteConfig.getString('maintenance_message');
  static String get playStoreUrl => _remoteConfig.getString('playstore_url');
}
