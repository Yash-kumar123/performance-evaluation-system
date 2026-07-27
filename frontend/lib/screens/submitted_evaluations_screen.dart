import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/manager_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/utils/responsive_utils.dart';

class SubmittedEvaluationsScreen extends StatelessWidget {
  const SubmittedEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mgrProvider = Provider.of<ManagerProvider>(context);
    final submittedList = mgrProvider.teamStatus.where((item) => item['status'] == 'SUBMITTED').toList();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Submitted Team Reviews',
        showBackButton: true,
        showDrawerButton: false,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: ResponsiveUtils.appBarBody(
        context: context,
        child: submittedList.isEmpty
          ? const EmptyStateWidget(
              title: 'No Finalized Submissions',
              message: 'You have not finalized any team evaluations for the active cycle yet.',
              icon: Icons.task_alt_rounded,
            )
          : ListView.builder(
              padding: ResponsiveUtils.screenPadding(context),
              itemCount: submittedList.length,
              itemBuilder: (context, index) {
                final item = submittedList[index];
                final evalId = item['evaluation_id'] as String?;
                final empName = item['employee_name'] ?? 'Employee';
                final jobTitle = item['job_title'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.successColor.withOpacity(0.12),
                      child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor),
                    ),
                    title: Text(
                      empName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(jobTitle),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondaryColor),
                    onTap: () {
                      if (evalId != null) {
                        context.push('/evaluation/$evalId');
                      }
                    },
                  ),
                );
              },
            ),
      ),
    );
  }
}
