import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/employee_provider.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/utils/responsive_utils.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  String? _selectedCycleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final empProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final hrProvider = Provider.of<HRProvider>(context, listen: false);

    hrProvider.fetchCycles();
    empProvider.fetchCurrentEvaluation(cycleId: _selectedCycleId);
    empProvider.fetchScoreTrends();
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
    final hrProvider = Provider.of<HRProvider>(context);

    final cycles = hrProvider.cyclesList;
    final currentEval = empProvider.currentEvaluationData?['evaluation'];
    final activeCycle = empProvider.currentEvaluationData?['cycle'];
    final scores = (currentEval?['scores'] as List<dynamic>?) ?? [];

    double avgScore = 0;
    if (scores.isNotEmpty) {
      final total = scores.fold<int>(0, (sum, item) => sum + ((item['score'] as int?) ?? 0));
      avgScore = total / scores.length;
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Performance Portal'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: ResponsiveUtils.appBarBody(
          context: context,
          scrollable: true,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Executive Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
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
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'E',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Employee Dashboard',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.jobTitle ?? 'Staff Member'} • ${user?.department ?? 'General'}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
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
              const SizedBox(height: 20),

              // Cycle Toggle Selector Bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Select Evaluation Review Period:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: cycles.map((c) {
                            final cId = c['id'] as String;
                            final cName = c['name'] ?? 'Cycle';
                            final cCode = c['cycle_code'] ?? '';
                            final isSelected = (_selectedCycleId == null && (c['is_active'] == true || cId == activeCycle?['id'])) || _selectedCycleId == cId;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('$cName ($cCode)'),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCycleId = cId;
                                    });
                                    empProvider.fetchCurrentEvaluation(cycleId: cId);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // KPI Stats Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Cycle Rating',
                      value: avgScore > 0 ? '${avgScore.toStringAsFixed(1)} ★' : 'N/A',
                      color: avgScore > 0 ? _getScoreColor(avgScore) : AppTheme.textSecondaryColor,
                      icon: Icons.star_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Review Status',
                      value: currentEval != null ? (currentEval['status'] == 'SUBMITTED' ? 'Completed' : 'Draft') : 'Pending',
                      color: currentEval != null
                          ? (currentEval['status'] == 'SUBMITTED' ? AppTheme.successColor : AppTheme.warningColor)
                          : AppTheme.textSecondaryColor,
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Navigation Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: ResponsiveUtils.isCompact(context) ? double.infinity : null,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/cycles'),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('Review Cycles'),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.isCompact(context) ? double.infinity : null,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/history'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('History'),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.isCompact(context) ? double.infinity : null,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('Profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Current Monthly Evaluation Card
              Text(
                'Evaluation Feedback & Scores',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

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
                  onRetry: () => empProvider.fetchCurrentEvaluation(cycleId: _selectedCycleId),
                )
              else if (currentEval == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 48, color: AppTheme.warningColor),
                        const SizedBox(height: 12),
                        Text(
                          'No Evaluation Submitted for ${activeCycle?['name'] ?? 'Selected Cycle'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your direct manager has not finalized ratings for this review period yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildCurrentEvaluationCard(context, currentEval),

              const SizedBox(height: 28),

              // Parameter Score Trends Section (Clean Cards)
              Text(
                'Parameter Ratings Evolution',
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

  Widget _buildMetricCard({required String title, required String value, required Color color, required IconData icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
          ],
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
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
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

            // Scores Progress Bar View
            const Text(
              '5 Parameter Scores Breakdown:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 14),
            Column(
              children: scores.map((item) {
                final score = (item['score'] as int?) ?? 0;
                final progress = score / 5.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['parameter_name'] ?? 'Parameter',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$score / 5 Stars',
                            style: TextStyle(
                              color: _getScoreColor(score.toDouble()),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppTheme.borderSubtleColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score.toDouble())),
                        ),
                      ),
                      if (item['comment'] != null && (item['comment'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Feedback: "${item['comment']}"',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

            if (eval['summary_comment'] != null && (eval['summary_comment'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Manager Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                    const SizedBox(height: 4),
                    Text(
                      '"${eval['summary_comment']}"',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textPrimaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),
            Semantics(
              button: true,
              label: 'View official score sheet',
              child: ResponsiveUtils.primaryButton(
                onPressed: () => context.push('/evaluation/$evalId'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('View Official Score Sheet'),
                  ],
                ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score.toDouble()).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getScoreColor(score.toDouble()).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              item['cycleCode'] ?? '',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppTheme.warningColor),
                                const SizedBox(width: 2),
                                Text(
                                  '$score.0',
                                  style: TextStyle(
                                    color: _getScoreColor(score.toDouble()),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
