import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/empty_state_widget.dart';

class PendingReviewsScreen extends StatelessWidget {
  const PendingReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);
    final pendingList = hrProvider.pendingManagers;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pending Manager Submissions'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await hrProvider.fetchDashboard();
        },
        child: pendingList.isEmpty
            ? const EmptyStateWidget(
                title: 'All Submissions Completed!',
                message: 'Every manager has finalized their team evaluations for this cycle.',
                icon: Icons.check_circle_outline_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: pendingList.length,
                itemBuilder: (context, index) {
                  final m = pendingList[index];
                  final name = m['manager_name'] ?? 'Manager';
                  final dept = m['department'] ?? 'Department';
                  final pending = (m['pending_submissions'] as int?) ?? 0;
                  final total = (m['total_direct_reports'] as int?) ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.warningColor.withOpacity(0.12),
                        child: const Icon(Icons.hourglass_top_rounded, color: AppTheme.warningColor),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text('$dept • $pending of $total pending reviews'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$pending Pending',
                          style: const TextStyle(
                            color: AppTheme.warningColor,
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
