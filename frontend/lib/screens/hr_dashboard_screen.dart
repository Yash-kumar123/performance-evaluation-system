import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/custom_app_bar.dart';
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
      final hrProvider = Provider.of<HRProvider>(context, listen: false);
      hrProvider.fetchDashboard();
      hrProvider.fetchCycles();
    });
  }

  void _showCreateCycleDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'August 2026 Evaluation');
    final codeController = TextEditingController(text: '2026-08');
    final startDateController = TextEditingController(text: '2026-08-01');
    final endDateController = TextEditingController(text: '2026-08-31');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Create Review Cycle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Specify the review cycle name, code, start date, and deadline for managers.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cycle Name',
                    hintText: 'e.g. August 2026 Evaluation',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Cycle Code (YYYY-MM)',
                    hintText: '2026-08',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start Date (YYYY-MM-DD)',
                    hintText: '2026-08-01',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End Date / Deadline (YYYY-MM-DD)',
                    hintText: '2026-08-31',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final hrProvider = Provider.of<HRProvider>(context, listen: false);
              final success = await hrProvider.createCycle(
                name: nameController.text.trim(),
                cycleCode: codeController.text.trim(),
                startDate: startDateController.text.trim(),
                endDate: endDateController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Evaluation cycle created successfully!' : (hrProvider.errorAction ?? 'Failed to create cycle.'),
                  ),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Create Cycle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'HR Compliance Portal'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: Builder(
        builder: (context) {
          if (hrProvider.isLoadingDashboard) {
            return const LoadingWidget(message: 'Loading HR metrics & manager compliance...');
          }

          if (hrProvider.errorDashboard != null) {
            return CustomErrorWidget(
              message: hrProvider.errorDashboard!,
              onRetry: () => hrProvider.fetchDashboard(),
            );
          }

          final cycleName = hrProvider.cycle?['name'] ?? 'Active Cycle';

          return RefreshIndicator(
            onRefresh: () => hrProvider.fetchDashboard(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cycle Banner & Create Cycle Action
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Company Compliance Oversight',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Current Cycle: $cycleName',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showCreateCycleDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Cycle'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Overview Summary Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return GridView.count(
                        crossAxisCount: isMobile ? 2 : 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isMobile ? 1.4 : 1.6,
                        children: [
                          _buildStatCard(
                            context,
                            title: 'Total Employees',
                            value: '${hrProvider.totalEmployees}',
                            icon: Icons.people_outline,
                            color: AppTheme.primaryColor,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Managers',
                            value: '${hrProvider.totalManagers}',
                            icon: Icons.supervisor_account_outlined,
                            color: AppTheme.secondaryColor,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Completed',
                            value: '${hrProvider.completedReviews}',
                            icon: Icons.check_circle_outline,
                            color: AppTheme.successColor,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Pending',
                            value: '${hrProvider.pendingReviews}',
                            icon: Icons.pending_actions_outlined,
                            color: AppTheme.warningColor,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Donut Chart & Completion Summary Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submission Compliance Ratio',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              SizedBox(
                                height: 140,
                                width: 140,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      PieChartSectionData(
                                        color: AppTheme.successColor,
                                        value: hrProvider.completedReviews.toDouble(),
                                        title: '${hrProvider.completedReviews}',
                                        radius: 30,
                                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                      ),
                                      PieChartSectionData(
                                        color: AppTheme.warningColor,
                                        value: hrProvider.draftReviews.toDouble(),
                                        title: '${hrProvider.draftReviews}',
                                        radius: 30,
                                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                      ),
                                      PieChartSectionData(
                                        color: AppTheme.errorColor.withOpacity(0.7),
                                        value: hrProvider.notStartedReviews.toDouble(),
                                        title: '${hrProvider.notStartedReviews}',
                                        radius: 30,
                                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendRow('Completed Submissions', AppTheme.successColor, hrProvider.completedReviews),
                                    const SizedBox(height: 8),
                                    _buildLegendRow('Drafts In-Progress', AppTheme.warningColor, hrProvider.draftReviews),
                                    const SizedBox(height: 8),
                                    _buildLegendRow('Not Started', AppTheme.errorColor.withOpacity(0.7), hrProvider.notStartedReviews),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Overall Completion: ${hrProvider.overallCompletionPercentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Action Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/hr/managers'),
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Managers Breakdown'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/hr/pending'),
                          icon: const Icon(Icons.pending_actions_rounded),
                          label: const Text('Pending Reviews'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
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

  Widget _buildLegendRow(String title, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
