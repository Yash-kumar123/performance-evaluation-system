import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/employee_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class EvaluationDetailsScreen extends StatefulWidget {
  final String evaluationId;

  const EvaluationDetailsScreen({super.key, required this.evaluationId});

  @override
  State<EvaluationDetailsScreen> createState() => _EvaluationDetailsScreenState();
}

class _EvaluationDetailsScreenState extends State<EvaluationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).fetchEvaluationDetails(widget.evaluationId);
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 5) return AppTheme.successColor;
    if (score >= 4) return AppTheme.primaryColor;
    if (score >= 3) return AppTheme.secondaryColor;
    if (score >= 2) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final empProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Evaluation Details',
        showBackButton: true,
        showDrawerButton: false,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Builder(
        builder: (context) {
          if (empProvider.isLoadingDetails) {
            return const LoadingWidget(message: 'Loading evaluation details...');
          }

          if (empProvider.errorDetails != null) {
            return CustomErrorWidget(
              message: empProvider.errorDetails!,
              onRetry: () => empProvider.fetchEvaluationDetails(widget.evaluationId),
            );
          }

          final eval = empProvider.selectedEvaluationDetails;
          if (eval == null) {
            return const Center(child: Text('Evaluation record not found.'));
          }

          final scores = (eval['scores'] as List<dynamic>?) ?? [];
          final employeeName = eval['employee_name'] ?? 'Employee';
          final managerName = eval['manager_name'] ?? 'Manager';
          final cycleName = eval['cycle_name'] ?? 'Monthly Review';
          final status = eval['status'] ?? 'SUBMITTED';
          final summaryComment = eval['summary_comment'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cycleName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Chip(
                              label: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: status == 'SUBMITTED' ? AppTheme.successColor : AppTheme.warningColor,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Employee: $employeeName', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.supervisor_account_rounded, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('Evaluator: $managerName', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        if (summaryComment != null && summaryComment.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Manager Summary:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summaryComment,
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5 Fixed Parameter Score Cards Section
                Text(
                  'Detailed 5-Parameter Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                Column(
                  children: scores.map((param) {
                    final pName = param['parameter_name'] ?? 'Parameter';
                    final score = (param['score'] as int?) ?? 0;
                    final comment = param['comment'] ?? 'No comment provided.';
                    final order = param['display_order'] ?? 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: Text(
                                    '$order',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(score).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getScoreColor(score).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: _getScoreColor(score)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$score / 5',
                                        style: TextStyle(
                                          color: _getScoreColor(score),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                comment,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
