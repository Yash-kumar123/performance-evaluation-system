import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/employee_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/utils/responsive_utils.dart';

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
      final empProvider = Provider.of<EmployeeProvider>(context, listen: false);
      empProvider.fetchEvaluationDetails(widget.evaluationId);
      empProvider.fetchScoreTrends();
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
    final user = Provider.of<AuthProvider>(context).user;
    final empProvider = Provider.of<EmployeeProvider>(context);
    final isManagerOrHR = user?.role == 'MANAGER' || user?.role == 'HR';

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Evaluation Score Sheet',
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

          return ResponsiveUtils.appBarBody(
            context: context,
            scrollable: true,
            child: ResponsiveUtils.constrainedContent(
              context,
              Column(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                cycleName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                            Text('Employee: $employeeName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

                // Employee Growth Progression Graph Section (ONLY FOR MANAGER & HR)
                if (isManagerOrHR && empProvider.scoreTrends.isNotEmpty) ...[
                  Text(
                    'Employee Growth & Assessment Graph',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildEmployeeGrowthGraph(empProvider.scoreTrends),
                  const SizedBox(height: 24),
                ],

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
          ),
          );
        },
      ),
    );
  }

  /// Clean & Fixed Employee Growth Graph for Manager/HR
  Widget _buildEmployeeGrowthGraph(List<dynamic> trends) {
    final Set<String> cycleCodesSet = {};
    for (var p in trends) {
      final history = (p['history'] as List<dynamic>?) ?? [];
      for (var h in history) {
        if (h['cycleCode'] != null) cycleCodesSet.add(h['cycleCode'] as String);
      }
    }
    final cycleCodes = cycleCodesSet.toList()..sort();

    if (cycleCodes.isEmpty) return const SizedBox.shrink();

    final Map<String, double> cycleAvgScores = {};
    for (var code in cycleCodes) {
      int totalScore = 0;
      int count = 0;
      for (var p in trends) {
        final history = (p['history'] as List<dynamic>?) ?? [];
        for (var h in history) {
          if (h['cycleCode'] == code) {
            totalScore += (h['score'] as int?) ?? 0;
            count++;
          }
        }
      }
      cycleAvgScores[code] = count > 0 ? (totalScore / count) : 0.0;
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < cycleCodes.length; i++) {
      final code = cycleCodes[i];
      final avg = cycleAvgScores[code] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), avg));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppTheme.successColor, size: 22),
                SizedBox(width: 8),
                Text(
                  'Manager & HR Assessment Graph',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tracks employee score improvement across May, June, and July cycles.',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: ResponsiveUtils.chartHeight(context, compact: 180, expanded: 220),
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 5,
                  minX: 0,
                  maxX: (cycleCodes.length - 1).toDouble() > 0 ? (cycleCodes.length - 1).toDouble() : 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: AppTheme.borderSubtleColor, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, meta) => Text('${val.toInt()}★', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1.0, // Fixed: Ensures clean single step per cycle code
                        getTitlesWidget: (val, meta) {
                          final idx = val.round();
                          if ((val - idx).abs() < 0.05 && idx >= 0 && idx < cycleCodes.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                cycleCodes[idx],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.successColor,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6,
                          color: AppTheme.successColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.successColor.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
