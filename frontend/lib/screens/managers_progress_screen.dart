import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/widgets/empty_state_widget.dart';

class ManagersProgressScreen extends StatefulWidget {
  const ManagersProgressScreen({super.key});

  @override
  State<ManagersProgressScreen> createState() => _ManagersProgressScreenState();
}

class _ManagersProgressScreenState extends State<ManagersProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HRProvider>(context, listen: false).fetchDashboard();
    });
  }

  Color _getBadgeColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppTheme.successColor;
      case 'IN_PROGRESS':
        return AppTheme.primaryColor;
      default:
        return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manager Submission Progress'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await hrProvider.fetchDashboard();
        },
        child: Builder(
          builder: (context) {
            if (hrProvider.isLoadingDashboard) {
              return const LoadingWidget(message: 'Loading manager submission list...');
            }

            if (hrProvider.errorDashboard != null) {
              return CustomErrorWidget(
                message: hrProvider.errorDashboard!,
                onRetry: () => hrProvider.fetchDashboard(),
              );
            }

            final managers = hrProvider.managers;

            if (managers.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Managers Found',
                message: 'No managers found in the active tenant company.',
                icon: Icons.supervisor_account_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final m = managers[index];
                final name = m['manager_name'] ?? 'Manager';
                final dept = m['department'] ?? 'Department';
                final totalReports = (m['total_direct_reports'] as int?) ?? 0;
                final completed = (m['completed_submissions'] as int?) ?? 0;
                final pending = (m['pending_submissions'] as int?) ?? 0;
                final status = m['submission_status'] ?? 'PENDING';

                final double progress = totalReports > 0 ? (completed / totalReports) : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dept,
                                      style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Chip(
                              label: Text(
                                status,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              backgroundColor: _getBadgeColor(status),
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Submissions Progress Counts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Direct Reports: $totalReports',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Submitted: $completed / $totalReports',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: completed == totalReports ? AppTheme.successColor : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppTheme.borderSubtleColor,
                            color: _getBadgeColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
