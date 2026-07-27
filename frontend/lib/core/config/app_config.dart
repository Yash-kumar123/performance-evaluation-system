import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Performance Evaluation Tool';

  // Dynamic Base URL for API Gateway:
  // In Web builds (including Render deployment), dynamically targets current host domain + /api
  static String get apiBaseUrl {
    if (kIsWeb) {
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final portStr = (Uri.base.hasPort && Uri.base.port != 80 && Uri.base.port != 443) ? ':${Uri.base.port}' : '';
      return '$scheme://$host$portStr/api';
    }
    return 'http://localhost:5000/api';
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
