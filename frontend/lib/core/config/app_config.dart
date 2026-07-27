class AppConfig {
  static const String appName = 'Performance Evaluation Tool';
  
  // Base URL for API Gateway (Configurable for local vs web vs emulator)
  // For Android Emulator use: http://10.0.2.2:5000/api
  // For iOS/Web/Desktop use: http://localhost:5000/api
  static const String apiBaseUrl = 'http://localhost:5000/api';

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
