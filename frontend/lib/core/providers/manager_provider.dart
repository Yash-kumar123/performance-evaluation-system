import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ManagerProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingTeam = false;
  bool _isLoadingSubmitting = false;
  String? _errorTeam;
  String? _errorSubmitting;

  Map<String, dynamic>? _activeCycle;
  List<dynamic> _teamStatus = [];
  List<dynamic> _directReports = [];

  bool get isLoadingTeam => _isLoadingTeam;
  bool get isLoadingSubmitting => _isLoadingSubmitting;
  String? get errorTeam => _errorTeam;
  String? get errorSubmitting => _errorSubmitting;

  Map<String, dynamic>? get activeCycle => _activeCycle;
  List<dynamic> get teamStatus => _teamStatus;
  List<dynamic> get directReports => _directReports;

  // Calculated Metrics
  int get totalReports => _teamStatus.length;
  int get completedCount => _teamStatus.where((item) => item['status'] == 'SUBMITTED').length;
  int get pendingCount => _teamStatus.where((item) => item['status'] == 'PENDING' || item['status'] == 'NOT_STARTED').length;
  double get completionPercentage => totalReports > 0 ? (completedCount / totalReports) * 100 : 0.0;

  /// Fetch Team Evaluation Status
  Future<void> fetchTeamStatus() async {
    _isLoadingTeam = true;
    _errorTeam = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/managers/team-status');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _activeCycle = data['cycle'];
        _teamStatus = data['teamStatus'] ?? [];
      } else {
        _errorTeam = response.data['message'] ?? 'Failed to load team status.';
      }
    } catch (e) {
      _errorTeam = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingTeam = false;
      notifyListeners();
    }
  }

  /// Fetch Direct Reports List
  Future<void> fetchDirectReports() async {
    try {
      final response = await _apiClient.get('/managers/reports');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _directReports = response.data['data'] ?? [];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Submit or Save Draft Evaluation
  Future<bool> createOrUpdateEvaluation({
    required String cycleId,
    required String employeeId,
    required List<Map<String, dynamic>> scores,
    String? summaryComment,
    bool submit = false,
    String? existingEvaluationId,
  }) async {
    _isLoadingSubmitting = true;
    _errorSubmitting = null;
    notifyListeners();

    try {
      late final dynamic response;

      if (existingEvaluationId != null && existingEvaluationId.isNotEmpty) {
        // Update existing draft
        response = await _apiClient.put('/managers/evaluations/$existingEvaluationId', data: {
          'scores': scores,
          'summaryComment': summaryComment ?? '',
          'submit': submit,
        });
      } else {
        // Create new evaluation
        response = await _apiClient.post('/managers/evaluations', data: {
          'cycleId': cycleId,
          'employeeId': employeeId,
          'scores': scores,
          'summaryComment': summaryComment ?? '',
          'submit': submit,
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTeamStatus(); // Refresh team status
        _isLoadingSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorSubmitting = response.data['message'] ?? 'Failed to save evaluation.';
        _isLoadingSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorSubmitting = e.toString().replaceAll('Exception:', '').trim();
      _isLoadingSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
