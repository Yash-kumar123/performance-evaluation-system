import 'package:flutter/material.dart';
import '../services/api_client.dart';

class HRProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingDashboard = false;
  String? _errorDashboard;

  Map<String, dynamic>? _cycle;
  Map<String, dynamic>? _metrics;
  List<dynamic> _managers = [];
  List<dynamic> _pendingManagers = [];
  List<dynamic> _completedManagers = [];

  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get errorDashboard => _errorDashboard;

  Map<String, dynamic>? get cycle => _cycle;
  Map<String, dynamic>? get metrics => _metrics;
  List<dynamic> get managers => _managers;
  List<dynamic> get pendingManagers => _pendingManagers;
  List<dynamic> get completedManagers => _completedManagers;

  // Calculated HR Metrics
  int get totalEmployees => _metrics?['totalEmployees'] ?? 0;
  int get totalManagers => _metrics?['totalManagers'] ?? 0;
  int get completedReviews => _metrics?['completedReviews'] ?? 0;
  int get draftReviews => _metrics?['draftReviews'] ?? 0;
  int get notStartedReviews => _metrics?['notStartedReviews'] ?? 0;
  int get pendingReviews => draftReviews + notStartedReviews;
  
  double get overallCompletionPercentage {
    final total = completedReviews + pendingReviews;
    return total > 0 ? (completedReviews / total) * 100 : 0.0;
  }

  /// Fetch HR Compliance Dashboard
  Future<void> fetchDashboard({String? cycleId}) async {
    _isLoadingDashboard = true;
    _errorDashboard = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/hr/dashboard', queryParameters: {
        if (cycleId != null) 'cycleId': cycleId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _cycle = data['cycle'];
        _metrics = data['metrics'];
        _managers = _metrics?['managers'] ?? [];
        
        // Filter pending and completed managers
        _pendingManagers = _managers.where((m) => m['submission_status'] != 'COMPLETED').toList();
        _completedManagers = _managers.where((m) => m['submission_status'] == 'COMPLETED').toList();
      } else {
        _errorDashboard = response.data['message'] ?? 'Failed to load HR metrics.';
      }
    } catch (e) {
      _errorDashboard = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }
}
