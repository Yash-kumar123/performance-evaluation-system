import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/employee_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    provider.fetchCurrentEvaluation();
    provider.fetchScoreTrends();
  }

  Color _getScoreColor(double score) {
    if (score >= 4.5) return AppTheme.successColor;
    if (score >= 3.5) return AppTheme.primaryColor;
    if (score >= 2.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final empProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Employee Portal'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'E',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user?.fullName ?? 'Employee'}',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.jobTitle ?? 'Team Member'} • ${user?.department ?? ''}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                              ),
                              Text(
                                user?.companyName ?? '',
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/history'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('History'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('Profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Section Title
              Text(
                'Current Monthly Feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Current Evaluation Content
              if (empProvider.isLoadingCurrent)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: LoadingWidget(message: 'Loading evaluation details...'),
                  ),
                )
              else if (empProvider.errorCurrent != null)
                CustomErrorWidget(
                  message: empProvider.errorCurrent!,
                  onRetry: () => empProvider.fetchCurrentEvaluation(),
                )
              else if (empProvider.currentEvaluationData == null ||
                  empProvider.currentEvaluationData!['evaluation'] == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 48, color: AppTheme.warningColor),
                        const SizedBox(height: 12),
                        const Text(
                          'Evaluation Pending',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your direct manager has not submitted feedback for the active cycle yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildCurrentEvaluationCard(context, empProvider.currentEvaluationData!['evaluation']),
              ],

              const SizedBox(height: 28),

              // Parameter Score Trends Section
              Text(
                'Parameter Performance Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (empProvider.isLoadingTrends)
                const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
              else if (empProvider.scoreTrends.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No historical score trends recorded yet.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  ),
                )
              else
                _buildScoreTrendsList(empProvider.scoreTrends),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentEvaluationCard(BuildContext context, Map<String, dynamic> eval) {
    final scores = (eval['scores'] as List<dynamic>?) ?? [];
    double avgScore = 0;
    if (scores.isNotEmpty) {
      final total = scores.fold<int>(0, (sum, item) => sum + ((item['score'] as int?) ?? 0));
      avgScore = total / scores.length;
    }

    final evalId = eval['id'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval['cycle_name'] ?? 'Active Evaluation',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Evaluated by ${eval['manager_name'] ?? 'Manager'}',
                      style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(avgScore).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getScoreColor(avgScore).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppTheme.warningColor),
                      const SizedBox(width: 4),
                      Text(
                        avgScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: _getScoreColor(avgScore),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Scores Preview Grid
            Text(
              'Parameter Scores Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            Column(
              children: scores.map((item) {
                final score = (item['score'] as int?) ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['parameter_name'] ?? 'Parameter',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score.toDouble()).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$score / 5',
                          style: TextStyle(
                            color: _getScoreColor(score.toDouble()),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),

            if (eval['summary_comment'] != null && (eval['summary_comment'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Manager Comment: "${eval['summary_comment']}"',
                  style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/evaluation/$evalId'),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('View Full Score Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTrendsList(List<dynamic> trends) {
    return Column(
      children: trends.map((paramGroup) {
        final name = paramGroup['parameterName'] ?? 'Parameter';
        final history = (paramGroup['history'] as List<dynamic>?) ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: history.map((item) {
                      final score = (item['score'] as int?) ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score.toDouble()).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getScoreColor(score.toDouble()).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              item['cycleCode'] ?? '',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$score Score',
                              style: TextStyle(
                                color: _getScoreColor(score.toDouble()),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
