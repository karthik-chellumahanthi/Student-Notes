import 'package:flutter/material.dart';
import '../services/screen_security_service.dart';

/// A widget that prevents screenshots and screen recordings while active
class SecureWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const SecureWidget({super.key, required this.child, this.enabled = true});

  @override
  State<SecureWidget> createState() => _SecureWidgetState();
}

class _SecureWidgetState extends State<SecureWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _enableSecureMode();
    }
  }

  @override
  void didUpdateWidget(SecureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _enableSecureMode();
      } else {
        _disableSecureMode();
      }
    }
  }

  @override
  void dispose() {
    _disableSecureMode();
    super.dispose();
  }

  Future<void> _enableSecureMode() async {
    await ScreenSecurityService.enableSecureMode();
  }

  Future<void> _disableSecureMode() async {
    await ScreenSecurityService.disableSecureMode();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
