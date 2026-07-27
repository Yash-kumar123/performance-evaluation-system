import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/employee_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/widgets/empty_state_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).fetchEvaluationHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final empProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Evaluation History',
        showBackButton: true,
        showDrawerButton: false,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await empProvider.fetchEvaluationHistory();
        },
        child: Builder(
          builder: (context) {
            if (empProvider.isLoadingHistory) {
              return const LoadingWidget(message: 'Loading evaluation history...');
            }

            if (empProvider.errorHistory != null) {
              return CustomErrorWidget(
                message: empProvider.errorHistory!,
                onRetry: () => empProvider.fetchEvaluationHistory(),
              );
            }

            final history = empProvider.evaluationHistory;

            if (history.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Evaluation Records',
                message: 'You do not have any historical submitted reviews yet.',
                icon: Icons.history_toggle_off_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final evalId = item['evaluation_id'] as String;
                final cycleName = item['cycle_name'] ?? 'Monthly Evaluation';
                final cycleCode = item['cycle_code'] ?? '';
                final managerName = item['manager_name'] ?? 'Manager';
                final managerJobTitle = item['manager_job_title'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cycleName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cycleCode,
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Evaluated by: $managerName ($managerJobTitle)'),
                          if (item['summary_comment'] != null && (item['summary_comment'] as String).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '"${item['summary_comment']}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondaryColor),
                    onTap: () {
                      context.go('/evaluation/$evalId');
                    },
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
