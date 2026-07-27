import 'package:flutter/material.dart';
import '../services/api_client.dart';

class EmployeeProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // State Variables
  bool _isLoadingCurrent = false;
  bool _isLoadingHistory = false;
  bool _isLoadingTrends = false;
  bool _isLoadingDetails = false;

  String? _errorCurrent;
  String? _errorHistory;
  String? _errorTrends;
  String? _errorDetails;

  Map<String, dynamic>? _currentEvaluationData;
  List<dynamic> _evaluationHistory = [];
  List<dynamic> _scoreTrends = [];
  Map<String, dynamic>? _selectedEvaluationDetails;

  // Getters
  bool get isLoadingCurrent => _isLoadingCurrent;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingTrends => _isLoadingTrends;
  bool get isLoadingDetails => _isLoadingDetails;

  String? get errorCurrent => _errorCurrent;
  String? get errorHistory => _errorHistory;
  String? get errorTrends => _errorTrends;
  String? get errorDetails => _errorDetails;

  Map<String, dynamic>? get currentEvaluationData => _currentEvaluationData;
  List<dynamic> get evaluationHistory => _evaluationHistory;
  List<dynamic> get scoreTrends => _scoreTrends;
  Map<String, dynamic>? get selectedEvaluationDetails => _selectedEvaluationDetails;

  /// Fetch Current Month's Evaluation
  Future<void> fetchCurrentEvaluation() async {
    _isLoadingCurrent = true;
    _errorCurrent = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/employees/evaluations/current');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentEvaluationData = response.data['data'];
      } else {
        _errorCurrent = response.data['message'] ?? 'Failed to load current evaluation.';
      }
    } catch (e) {
      _errorCurrent = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingCurrent = false;
      notifyListeners();
    }
  }

  /// Fetch Evaluation History Timeline
  Future<void> fetchEvaluationHistory() async {
    _isLoadingHistory = true;
    _errorHistory = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/employees/evaluations/history');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _evaluationHistory = response.data['data'] ?? [];
      } else {
        _errorHistory = response.data['message'] ?? 'Failed to load evaluation history.';
      }
    } catch (e) {
      _errorHistory = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Fetch Parameter Score Trends
  Future<void> fetchScoreTrends() async {
    _isLoadingTrends = true;
    _errorTrends = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/employees/evaluations/trends');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _scoreTrends = response.data['data'] ?? [];
      } else {
        _errorTrends = response.data['message'] ?? 'Failed to load score trends.';
      }
    } catch (e) {
      _errorTrends = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingTrends = false;
      notifyListeners();
    }
  }

  /// Fetch Specific Evaluation Details by ID
  Future<void> fetchEvaluationDetails(String evaluationId) async {
    _isLoadingDetails = true;
    _errorDetails = null;
    _selectedEvaluationDetails = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/evaluations/$evaluationId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _selectedEvaluationDetails = response.data['data'];
      } else {
        _errorDetails = response.data['message'] ?? 'Failed to load evaluation details.';
      }
    } catch (e) {
      _errorDetails = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }
}
