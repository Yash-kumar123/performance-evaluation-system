import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class HRPerformanceChartWidget extends StatelessWidget {
  final List<dynamic> trendPoints;

  const HRPerformanceChartWidget({
    super.key,
    required this.trendPoints,
  });

  String _formatMonthLabel(Map<String, dynamic> point) {
    final startDate = point['startDate'] as String?;
    if (startDate != null && startDate.isNotEmpty) {
      final parsed = DateTime.tryParse(startDate);
      if (parsed != null) {
        return DateFormat('MMMM yyyy').format(parsed);
      }
    }

    final cycleName = (point['cycleName'] as String?) ?? '';
    if (cycleName.isNotEmpty) return cycleName;

    return (point['cycleCode'] as String?) ?? 'Unknown Month';
  }

  Map<String, dynamic>? _bestPerformingPoint() {
    Map<String, dynamic>? best;
    double bestScore = 0;
    for (final p in trendPoints) {
      final score = (p['avgScore'] as num? ?? 0).toDouble();
      if (score > bestScore) {
        bestScore = score;
        best = p as Map<String, dynamic>;
      }
    }
    return best;
  }

  Map<String, dynamic>? _lowestPerformingPoint() {
    Map<String, dynamic>? lowest;
    double? lowestScore;
    for (final p in trendPoints) {
      final score = (p['avgScore'] as num? ?? 0).toDouble();
      if (score <= 0) continue;
      if (lowestScore == null || score < lowestScore) {
        lowestScore = score;
        lowest = p as Map<String, dynamic>;
      }
    }
    return lowest;
  }

  @override
  Widget build(BuildContext context) {
    if (trendPoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, size: 48, color: AppTheme.textSecondaryColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'No evaluation performance records found for the selected filter.',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final validScores = trendPoints.map<double>((p) => (p['avgScore'] as num? ?? 0.0).toDouble()).toList();
    final nonZeroScores = validScores.where((s) => s > 0).toList();

    final avgScore = nonZeroScores.isNotEmpty ? nonZeroScores.reduce((a, b) => a + b) / nonZeroScores.length : 0.0;
    final totalSubmissions = trendPoints.fold<int>(0, (sum, p) => sum + (p['submittedCount'] as int? ?? 0));

    final bestPoint = _bestPerformingPoint();
    final lowestPoint = _lowestPerformingPoint();

    final Map<String, List<double>> paramMap = {};
    for (final p in trendPoints) {
      final map = p['parameterScores'] as Map<String, dynamic>? ?? {};
      map.forEach((key, val) {
        final score = (val as num? ?? 0).toDouble();
        if (score > 0) {
          paramMap.putIfAbsent(key, () => []).add(score);
        }
      });
    }

    final Map<String, double> avgParamScores = {};
    paramMap.forEach((key, list) {
      avgParamScores[key] = list.reduce((a, b) => a + b) / list.length;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildStatBadge(
              label: 'Overall Average',
              primaryValue: '${avgScore.toStringAsFixed(2)} / 5',
              color: AppTheme.primaryColor,
            ),
            if (bestPoint != null)
              _buildStatBadge(
                label: 'Best Performing Month',
                primaryValue: _formatMonthLabel(bestPoint),
                secondaryValue: '${(bestPoint['avgScore'] as num).toDouble().toStringAsFixed(2)} / 5',
                color: AppTheme.successColor,
              )
            else
              _buildStatBadge(
                label: 'Best Performing Month',
                primaryValue: 'N/A',
                color: AppTheme.successColor,
              ),
            if (lowestPoint != null)
              _buildStatBadge(
                label: 'Lowest Performing Month',
                primaryValue: _formatMonthLabel(lowestPoint),
                secondaryValue: '${(lowestPoint['avgScore'] as num).toDouble().toStringAsFixed(2)} / 5',
                color: AppTheme.warningColor,
              )
            else
              _buildStatBadge(
                label: 'Lowest Performing Month',
                primaryValue: 'N/A',
                color: AppTheme.warningColor,
              ),
            _buildStatBadge(
              label: 'Total Reviews',
              primaryValue: '$totalSubmissions',
              color: AppTheme.secondaryColor,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: ResponsiveUtils.chartHeight(context, compact: 180, expanded: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtleColor),
              ),
              child: CustomPaint(
                size: Size(constraints.maxWidth, ResponsiveUtils.chartHeight(context, compact: 180, expanded: 220)),
                painter: PerformanceTrendPainter(trendPoints: trendPoints),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (avgParamScores.isNotEmpty) ...[
          const Text(
            'Evaluation Parameter Averages',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...avgParamScores.entries.map((e) {
            final paramCode = e.key;
            final score = e.value;
            final cleanName = paramCode.replaceAll('_', ' ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cleanName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Text('${score.toStringAsFixed(2)} / 5.0', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score / 5.0,
                      minHeight: 8,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 4.0 ? AppTheme.successColor : (score >= 3.0 ? AppTheme.primaryColor : AppTheme.warningColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String primaryValue,
    String? secondaryValue,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryValue,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
          if (secondaryValue != null) ...[
            const SizedBox(height: 2),
            Text(
              secondaryValue,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.9)),
            ),
          ],
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }
}

class PerformanceTrendPainter extends CustomPainter {
  final List<dynamic> trendPoints;

  PerformanceTrendPainter({required this.trendPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (trendPoints.isEmpty) return;

    const double paddingLeft = 32.0;
    const double paddingBottom = 24.0;
    const double paddingTop = 16.0;
    const double paddingRight = 16.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 1; i <= 5; i++) {
      final double y = paddingTop + chartHeight - ((i / 5.0) * chartHeight);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: '$i.0',
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - 6));
    }

    final int pointCount = trendPoints.length;
    final double stepX = pointCount > 1 ? chartWidth / (pointCount - 1) : chartWidth / 2;

    final linePath = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < pointCount; i++) {
      final p = trendPoints[i];
      final double score = (p['avgScore'] as num? ?? 0.0).toDouble();
      final double x = pointCount > 1 ? paddingLeft + (i * stepX) : paddingLeft + (chartWidth / 2);
      final double y = paddingTop + chartHeight - ((score.clamp(0.0, 5.0) / 5.0) * chartHeight);

      points.add(Offset(x, y));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, paddingTop + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == pointCount - 1) {
        fillPath.lineTo(x, paddingTop + chartHeight);
        fillPath.close();
      }

      final cycleCode = (p['cycleCode'] as String? ?? 'C${i + 1}').replaceAll('Cycle Evaluation ', '');
      textPainter.text = TextSpan(
        text: cycleCode.length > 8 ? cycleCode.substring(0, 8) : cycleCode,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - paddingBottom + 6));
    }

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primaryColor.withOpacity(0.3),
        AppTheme.primaryColor.withOpacity(0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = AppTheme.primaryColor;
    final whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final double score = (trendPoints[i]['avgScore'] as num? ?? 0.0).toDouble();

      canvas.drawCircle(pt, 5, pointPaint);
      canvas.drawCircle(pt, 2.5, whitePaint);

      if (score > 0) {
        textPainter.text = TextSpan(
          text: score.toStringAsFixed(1),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pt.dx - (textPainter.width / 2), pt.dy - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant PerformanceTrendPainter oldDelegate) {
    return oldDelegate.trendPoints != trendPoints;
  }
}
