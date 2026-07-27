import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/empty_state_widget.dart';

class CompletedReviewsScreen extends StatelessWidget {
  const CompletedReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);
    final completedList = hrProvider.completedManagers;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Compliant Managers',
        showBackButton: true,
        showDrawerButton: false,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await hrProvider.fetchDashboard();
        },
        child: completedList.isEmpty
            ? const EmptyStateWidget(
                title: 'No Completed Managers Yet',
                message: 'No managers have 100% completed their team evaluations for this cycle yet.',
                icon: Icons.pending_actions_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: completedList.length,
                itemBuilder: (context, index) {
                  final m = completedList[index];
                  final name = m['manager_name'] ?? 'Manager';
                  final dept = m['department'] ?? 'Department';
                  final total = (m['total_direct_reports'] as int?) ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.successColor.withOpacity(0.12),
                        child: const Icon(Icons.verified_rounded, color: AppTheme.successColor),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text('$dept • $total of $total reviews submitted'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '100% Complete',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
