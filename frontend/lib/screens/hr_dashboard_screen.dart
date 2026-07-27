import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<HRProvider>(context, listen: false).fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final hrProvider = Provider.of<HRProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'HR Compliance Portal'),
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
              // Company Overview Header Card
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
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.domain_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.companyName ?? 'Organization HR Portal',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active Cycle: ${hrProvider.cycle?['name'] ?? 'July 2026 Evaluation'}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
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

              // Action Shortcuts
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/hr/managers'),
                      icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                      label: const Text('All Managers'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/hr/pending'),
                      icon: const Icon(Icons.pending_actions_rounded, size: 18),
                      label: const Text('Pending'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/hr/completed'),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Compliant'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Overview Metrics Section
              Text(
                'Company Overview Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (hrProvider.isLoadingDashboard)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: LoadingWidget(message: 'Loading HR compliance dashboard...'),
                  ),
                )
              else if (hrProvider.errorDashboard != null)
                CustomErrorWidget(
                  message: hrProvider.errorDashboard!,
                  onRetry: () => _loadData(),
                )
              else ...[
                // Metrics Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildHRMetricCard(
                        context,
                        title: 'Total Employees',
                        value: '${hrProvider.totalEmployees}',
                        icon: Icons.people_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHRMetricCard(
                        context,
                        title: 'Total Managers',
                        value: '${hrProvider.totalManagers}',
                        icon: Icons.supervisor_account_rounded,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHRMetricCard(
                        context,
                        title: 'Completed Reviews',
                        value: '${hrProvider.completedReviews}',
                        icon: Icons.task_alt_rounded,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHRMetricCard(
                        context,
                        title: 'Pending Reviews',
                        value: '${hrProvider.pendingReviews}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Charts Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall Submission Progress',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${hrProvider.overallCompletionPercentage.toStringAsFixed(0)}% Complete',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Donut Chart Visualization
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 45,
                              sections: [
                                PieChartSectionData(
                                  color: AppTheme.successColor,
                                  value: hrProvider.completedReviews.toDouble(),
                                  title: '${hrProvider.completedReviews}',
                                  radius: 35,
                                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: AppTheme.warningColor,
                                  value: hrProvider.pendingReviews.toDouble(),
                                  title: '${hrProvider.pendingReviews}',
                                  radius: 35,
                                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Completed Reviews', AppTheme.successColor),
                            const SizedBox(width: 24),
                            _buildLegendItem('Pending Reviews', AppTheme.warningColor),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHRMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
