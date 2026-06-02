import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;

  const UpdateDialog({super.key, required this.isForceUpdate});

  static void show(BuildContext context, {required bool isForceUpdate}) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: UpdateDialog(isForceUpdate: isForceUpdate),
      ),
    );
  }

  void _launchPlayStore() async {
    final url = Uri.parse(RemoteConfigService.playStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isForceUpdate ? Icons.warning_amber_rounded : Icons.system_update,
            color: isForceUpdate ? Colors.red : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(isForceUpdate ? "Update Required" : "Update Available"),
        ],
      ),
      content: Text(
        isForceUpdate
            ? "A new version of Student Notes is available and is required to continue. Please update to the latest version."
            : "A new version of Student Notes is available with new features and improvements. Would you like to update?",
        style: const TextStyle(fontSize: 15),
      ),
      actions: [
        if (!isForceUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later", style: TextStyle(color: Colors.grey)),
          ),
        ElevatedButton(
          onPressed: _launchPlayStore,
          style: ElevatedButton.styleFrom(
            backgroundColor: isForceUpdate ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Update Now"),
        ),
      ],
    );
  }
}
