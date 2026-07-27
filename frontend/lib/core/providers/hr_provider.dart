import 'package:flutter/material.dart';
import '../services/api_client.dart';

class HRProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingDashboard = false;
  bool _isLoadingAction = false;
  bool _isLoadingUsers = false;
  bool _isLoadingProjectTeams = false;
  bool _isLoadingCycles = false;

  String? _errorDashboard;
  String? _errorAction;
  String? _errorUsers;
  String? _errorProjectTeams;
  String? _errorCycles;

  Map<String, dynamic>? _cycle;
  Map<String, dynamic>? _metrics;
  List<dynamic> _managers = [];
  List<dynamic> _pendingManagers = [];
  List<dynamic> _completedManagers = [];
  List<dynamic> _cyclesList = [];
  List<dynamic> _usersList = [];
  List<dynamic> _projectTeamsList = [];

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingAction => _isLoadingAction;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingProjectTeams => _isLoadingProjectTeams;
  bool get isLoadingCycles => _isLoadingCycles;

  String? get errorDashboard => _errorDashboard;
  String? get errorAction => _errorAction;
  String? get errorUsers => _errorUsers;
  String? get errorProjectTeams => _errorProjectTeams;
  String? get errorCycles => _errorCycles;

  Map<String, dynamic>? get cycle => _cycle;
  Map<String, dynamic>? get metrics => _metrics;
  List<dynamic> get managers => _managers;
  List<dynamic> get pendingManagers => _pendingManagers;
  List<dynamic> get completedManagers => _completedManagers;
  List<dynamic> get cyclesList => _cyclesList;
  List<dynamic> get usersList => _usersList;
  List<dynamic> get projectTeamsList => _projectTeamsList;

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

  /// Fetch All Project Teams (HR Feature)
  Future<void> fetchProjectTeams() async {
    _isLoadingProjectTeams = true;
    _errorProjectTeams = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/hr/project-teams');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _projectTeamsList = response.data['data'] ?? [];
      } else {
        _errorProjectTeams = response.data['message'] ?? 'Failed to load project teams.';
      }
    } catch (e) {
      _errorProjectTeams = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingProjectTeams = false;
      notifyListeners();
    }
  }

  /// Create New Project Team (HR Feature)
  Future<bool> createProjectTeam({
    required String name,
    String? code,
    String? description,
    String? leadManagerId,
    List<String>? memberIds,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/hr/project-teams', data: {
        'name': name,
        'code': code ?? '',
        'description': description ?? '',
        'leadManagerId': leadManagerId,
        'memberIds': memberIds ?? [],
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchProjectTeams();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to create project team.';
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

  /// Update Project Team (HR Feature)
  Future<bool> updateProjectTeam({
    required String teamId,
    required String name,
    String? code,
    String? description,
    String? leadManagerId,
    List<String>? memberIds,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/hr/project-teams/$teamId', data: {
        'name': name,
        'code': code ?? '',
        'description': description ?? '',
        'leadManagerId': leadManagerId,
        'memberIds': memberIds ?? [],
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchProjectTeams();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to update project team.';
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

  /// Delete Project Team (HR Feature)
  Future<bool> deleteProjectTeam(String teamId) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.delete('/hr/project-teams/$teamId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchProjectTeams();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to delete project team.';
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

  /// Fetch All Users / Team Members for Company (HR Teams Management)
  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    _errorUsers = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/hr/users');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _usersList = response.data['data'] ?? [];
      } else {
        _errorUsers = response.data['message'] ?? 'Failed to load team members.';
      }
    } catch (e) {
      _errorUsers = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Add New Team Member (HR Feature)
  Future<bool> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? jobTitle,
    String? department,
    String? managerId,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/hr/users', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        'jobTitle': jobTitle,
        'department': department,
        'managerId': managerId,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchUsers();
        await fetchDashboard();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to add team member.';
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

  /// Update Team Member Details (HR Feature)
  Future<bool> updateUser({
    required String userId,
    required String fullName,
    required String role,
    String? jobTitle,
    String? department,
    String? managerId,
    bool isActive = true,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/hr/users/$userId', data: {
        'fullName': fullName,
        'role': role,
        'jobTitle': jobTitle,
        'department': department,
        'managerId': managerId,
        'isActive': isActive,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchUsers();
        await fetchDashboard();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to update team member.';
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

  /// Delete / Deactivate Team Member (HR Feature)
  Future<bool> deleteUser(String userId) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.delete('/hr/users/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchUsers();
        await fetchDashboard();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to remove team member.';
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

  /// Fetch All Evaluation Cycles (Open to all authenticated roles)
  Future<void> fetchCycles() async {
    _isLoadingCycles = true;
    _errorCycles = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/hr/cycles');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _cyclesList = response.data['data'] ?? [];
      } else {
        _errorCycles = response.data['message'] ?? 'Failed to load evaluation cycles.';
      }
    } catch (e) {
      _errorCycles = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingCycles = false;
      notifyListeners();
    }
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

      if ((response.statusCode == 201 || response.statusCode == 200) && response.data['success'] == true) {
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

  /// Update Existing Review Cycle
  Future<bool> updateCycle({
    required String cycleId,
    required String name,
    required String startDate,
    required String endDate,
    bool isActive = true,
  }) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/hr/cycles/$cycleId', data: {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': isActive,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchDashboard();
        await fetchCycles();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to update review cycle.';
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

  /// Delete Review Cycle
  Future<bool> deleteCycle(String cycleId) async {
    _isLoadingAction = true;
    _errorAction = null;
    notifyListeners();

    try {
      final response = await _apiClient.delete('/hr/cycles/$cycleId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchDashboard();
        await fetchCycles();
        _isLoadingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorAction = response.data['message'] ?? 'Failed to delete review cycle.';
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
        await fetchUsers();
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

  // --- HR Performance Analytics Trends State ---
  bool _isLoadingAnalytics = false;
  String? _errorAnalytics;
  String _analyticsMode = 'CYCLES'; // 'CYCLES' | 'YEAR'
  int _selectedAnalyticsYear = DateTime.now().year;
  int _selectedAnalyticsCycleLimit = 5;
  String _selectedAnalyticsEmployeeId = 'ALL';
  Map<String, dynamic>? _analyticsData;

  bool get isLoadingAnalytics => _isLoadingAnalytics;
  String? get errorAnalytics => _errorAnalytics;
  String get analyticsMode => _analyticsMode;
  int get selectedAnalyticsYear => _selectedAnalyticsYear;
  int get selectedAnalyticsCycleLimit => _selectedAnalyticsCycleLimit;
  String get selectedAnalyticsEmployeeId => _selectedAnalyticsEmployeeId;
  Map<String, dynamic>? get analyticsData => _analyticsData;
  List<int> get availableAnalyticsYears => List<int>.from(_analyticsData?['availableYears'] ?? [DateTime.now().year]);
  List<dynamic> get analyticsEmployees => _analyticsData?['employees'] ?? [];
  List<dynamic> get analyticsTrendPoints => _analyticsData?['trendPoints'] ?? [];

  /// Fetch HR Performance Analytics Trends
  Future<void> fetchPerformanceAnalytics({
    String? mode,
    int? year,
    int? cycleLimit,
    String? employeeId,
  }) async {
    if (mode != null) _analyticsMode = mode;
    if (year != null) _selectedAnalyticsYear = year;
    if (cycleLimit != null) _selectedAnalyticsCycleLimit = cycleLimit;
    if (employeeId != null) _selectedAnalyticsEmployeeId = employeeId;

    _isLoadingAnalytics = true;
    _errorAnalytics = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/hr/analytics/performance', queryParameters: {
        'mode': _analyticsMode,
        'year': _selectedAnalyticsYear,
        'cycleLimit': _selectedAnalyticsCycleLimit,
        'employeeId': _selectedAnalyticsEmployeeId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        _analyticsData = response.data['data'];
        if (_analyticsData != null) {
          final years = availableAnalyticsYears;
          if (years.isNotEmpty && !years.contains(_selectedAnalyticsYear)) {
            _selectedAnalyticsYear = years.first;
          }
        }
      } else {
        _errorAnalytics = response.data['message'] ?? 'Failed to load performance analytics.';
      }
    } catch (e) {
      _errorAnalytics = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }
}
