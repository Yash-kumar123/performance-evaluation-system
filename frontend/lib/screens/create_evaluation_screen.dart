import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../core/config/app_theme.dart';
import '../core/providers/manager_provider.dart';
import '../core/widgets/custom_app_bar.dart';

class CreateEvaluationScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String cycleId;
  final String? evaluationId;

  const CreateEvaluationScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.cycleId,
    this.evaluationId,
  });

  @override
  State<CreateEvaluationScreen> createState() => _CreateEvaluationScreenState();
}

class _CreateEvaluationScreenState extends State<CreateEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryCommentController = TextEditingController();

  // 5 Fixed Parameters State Map: { parameterCode: { score: int, commentController: TextEditingController } }
  final Map<String, int> _scores = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize form controllers for all 5 fixed parameters
    for (final param in AppConfig.fixedParameters) {
      final code = param['code']!;
      _scores[code] = 4; // Default rating score
      _commentControllers[code] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _summaryCommentController.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitOrSaveDraft({required bool isSubmit}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete written comments (min 5 characters) for all 5 parameters.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final mgrProvider = Provider.of<ManagerProvider>(context, listen: false);

    final payloadScores = AppConfig.fixedParameters.map((param) {
      final code = param['code']!;
      return {
        'parameterCode': code,
        'parameterId': _getParameterIdForCode(code),
        'score': _scores[code] ?? 4,
        'comment': _commentControllers[code]!.text.trim(),
      };
    }).toList();

    final success = await mgrProvider.createOrUpdateEvaluation(
      cycleId: widget.cycleId,
      employeeId: widget.employeeId,
      scores: payloadScores,
      summaryComment: _summaryCommentController.text.trim(),
      submit: isSubmit,
      existingEvaluationId: widget.evaluationId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSubmit ? 'Evaluation submitted successfully!' : 'Evaluation draft saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/manager/team');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mgrProvider.errorSubmitting ?? 'Failed to save evaluation.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _getParameterIdForCode(String code) {
    switch (code) {
      case 'WORK_QUALITY':
        return '11111111-1111-1111-1111-111111111111';
      case 'PRODUCTIVITY':
        return '22222222-2222-2222-2222-222222222222';
      case 'COMMUNICATION':
        return '33333333-3333-3333-3333-333333333333';
      case 'PROBLEM_SOLVING':
        return '44444444-4444-4444-4444-444444444444';
      case 'RELIABILITY':
        return '55555555-5555-5555-5555-555555555555';
      default:
        return '11111111-1111-1111-1111-111111111111';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgrProvider = Provider.of<ManagerProvider>(context);
    final isLoading = mgrProvider.isLoadingSubmitting;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Evaluate ${widget.employeeName}',
        showDrawerButton: false,
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/manager/team');
          }
        },
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Banner
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          widget.employeeName.isNotEmpty ? widget.employeeName[0].toUpperCase() : 'E',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Monthly Evaluation Form (5 Fixed Parameters)',
                              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Parameter Ratings & Feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 5 Parameter Evaluation Input Cards
              ...AppConfig.fixedParameters.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final param = entry.value;
                final code = param['code']!;
                final name = param['name']!;
                final desc = param['description']!;
                final currentScore = _scores[code] ?? 4;

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '$index',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        // Score Selector (1 - 5 Chips)
                        const Text(
                          'Score Rating:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (scoreIdx) {
                            final scoreVal = scoreIdx + 1;
                            final isSelected = currentScore == scoreVal;

                            return ChoiceChip(
                              label: Text('$scoreVal ★'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _scores[code] = scoreVal;
                                  });
                                }
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Comment Text Input
                        TextFormField(
                          controller: _commentControllers[code],
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Written Feedback Comment',
                            hintText: 'Enter specific feedback for this parameter (min 5 chars)...',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 5) {
                              return 'Please write feedback (at least 5 characters).';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Overall Summary Comment Input Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Manager Summary (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _summaryCommentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter overall summary notes for this evaluation cycle...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons Row (Save Draft vs Submit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _submitOrSaveDraft(isSubmit: false),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submitOrSaveDraft(isSubmit: true),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Finalize & Submit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
