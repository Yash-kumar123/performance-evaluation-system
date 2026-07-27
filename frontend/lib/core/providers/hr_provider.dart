import 'package:flutter/material.dart';
import '../services/api_client.dart';

class HRProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingDashboard = false;
  bool _isLoadingAction = false;
  String? _errorDashboard;
  String? _errorAction;

  Map<String, dynamic>? _cycle;
  Map<String, dynamic>? _metrics;
  List<dynamic> _managers = [];
  List<dynamic> _pendingManagers = [];
  List<dynamic> _completedManagers = [];
  List<dynamic> _cyclesList = [];

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingAction => _isLoadingAction;
  String? get errorDashboard => _errorDashboard;
  String? get errorAction => _errorAction;

  Map<String, dynamic>? get cycle => _cycle;
  Map<String, dynamic>? get metrics => _metrics;
  List<dynamic> get managers => _managers;
  List<dynamic> get pendingManagers => _pendingManagers;
  List<dynamic> get completedManagers => _completedManagers;
  List<dynamic> get cyclesList => _cyclesList;

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

  /// Fetch All Evaluation Cycles
  Future<void> fetchCycles() async {
    try {
      final response = await _apiClient.get('/hr/cycles');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _cyclesList = response.data['data'] ?? [];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Create New Review Cycle (HR Date-Wise Feature)
  Future<bool> createCycle({
    required String name,
    required String cycleCode,
    required String startDate,
    required String endDate,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/hr/cycles', data: {
        'name': name,
        'cycleCode': cycleCode,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': true,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchDashboard();
        await fetchCycles();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to create review cycle.';
        _isLoadingAction = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorAction = e.toString().replaceAll('Exception:', '').trim();
      _isLoadingAction = false;
      notifyListeners();
      return false;
    }
  }

  /// Assign Manager to Employee (HR Feature)
  Future<bool> assignManager({
    required String employeeId,
    required String managerId,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.patch('/hr/assign-manager', data: {
        'employeeId': employeeId,
        'managerId': managerId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchDashboard();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to assign manager.';
        _isLoadingAction = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorAction = e.toString().replaceAll('Exception:', '').trim();
      _isLoadingAction = false;
      notifyListeners();
      return false;
    }
  }
}
