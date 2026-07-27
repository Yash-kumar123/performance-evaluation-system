import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Branded application logo used consistently across splash, login, and drawer.
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  final String? semanticLabel;

  const AppLogo({
    super.key,
    required this.size,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '${AppConfig.appName} logo',
      image: true,
      child: Image.asset(
        'assets/branding/app_logo.png',
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
