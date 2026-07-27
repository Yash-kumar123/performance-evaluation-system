import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Performance Evaluation System';
  static const String appLogoAsset = 'assets/branding/app_logo.png';

  // Production Render deployment URL
  static const String productionBaseUrl = 'https://performance-evaluation-system-gacb.onrender.com';

  // Dynamic Base URL for API Gateway:
  // - Web builds: dynamically targets current host domain + /api (works on Render and localhost)
  // - Native/Mobile builds: targets the live Render production deployment
  static String get apiBaseUrl {
    if (kIsWeb) {
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'https';
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final portStr = (Uri.base.hasPort && Uri.base.port != 80 && Uri.base.port != 443) ? ':${Uri.base.port}' : '';
      return '$scheme://$host$portStr/api';
    }
    // Non-web (Android, iOS, Desktop): use live Render deployment
    return '$productionBaseUrl/api';
  }

  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // 5 Fixed Evaluation Parameter Definitions
  static const List<Map<String, String>> fixedParameters = [
    {
      'code': 'WORK_QUALITY',
      'name': 'Quality of Work',
      'description': 'Accuracy, thoroughness, and standard of deliverables.'
    },
    {
      'code': 'PRODUCTIVITY',
      'name': 'Productivity & Efficiency',
      'description': 'Volume of work accomplished within target timelines.'
    },
    {
      'code': 'COMMUNICATION',
      'name': 'Communication & Teamwork',
      'description': 'Clarity, listening skills, and collaborative effectiveness.'
    },
    {
      'code': 'PROBLEM_SOLVING',
      'name': 'Problem Solving & Initiative',
      'description': 'Resourcefulness, critical thinking, and proactive drive.'
    },
    {
      'code': 'RELIABILITY',
      'name': 'Ownership & Reliability',
      'description': 'Dependability, accountability, and adherence to commitments.'
    },
  ];
}
