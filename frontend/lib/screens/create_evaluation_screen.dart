import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../core/config/app_theme.dart';
import '../core/providers/manager_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/loading_widget.dart';
import '../core/utils/responsive_utils.dart';

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

  final Map<String, int> _scores = {};
  String? _evaluationId;
  bool _isReadOnly = false;
  bool _isLoadingDraft = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    for (final param in AppConfig.fixedParameters) {
      _scores[param['code']!] = 4;
    }
    _evaluationId = widget.evaluationId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingEvaluation());
  }

  @override
  void dispose() {
    _summaryCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingEvaluation() async {
    if (_evaluationId == null || _evaluationId!.isEmpty) return;

    setState(() {
      _isLoadingDraft = true;
      _loadError = null;
    });

    final mgrProvider = Provider.of<ManagerProvider>(context, listen: false);
    final eval = await mgrProvider.fetchEvaluationById(_evaluationId!);

    if (!mounted) return;

    if (eval == null) {
      setState(() {
        _isLoadingDraft = false;
        _loadError = 'Unable to load saved evaluation.';
      });
      return;
    }

    final status = eval['status'] as String? ?? 'PENDING';
    if (status == 'SUBMITTED') {
      setState(() => _isLoadingDraft = false);
      context.pushReplacement('/evaluation/$_evaluationId');
      return;
    }

    final scores = (eval['scores'] as List<dynamic>?) ?? [];
    for (final item in scores) {
      final code = item['parameter_code'] as String?;
      final score = (item['score'] as int?) ?? 4;
      if (code != null) {
        _scores[code] = score;
      }
    }

    _summaryCommentController.text = (eval['summary_comment'] as String?) ?? '';

    setState(() {
      _isLoadingDraft = false;
      _isReadOnly = false;
    });
  }

  Future<void> _submitOrSaveDraft({required bool isSubmit}) async {
    if (_isReadOnly) return;

    final mgrProvider = Provider.of<ManagerProvider>(context, listen: false);

    final payloadScores = AppConfig.fixedParameters.map((param) {
      final code = param['code']!;
      return {
        'parameterCode': code,
        'parameterId': _getParameterIdForCode(code),
        'score': _scores[code] ?? 4,
        'comment': '',
      };
    }).toList();

    final effectiveCycleId = widget.cycleId.isNotEmpty
        ? widget.cycleId
        : (mgrProvider.activeCycle?['id'] as String? ?? '');

    final saved = await mgrProvider.createOrUpdateEvaluation(
      cycleId: effectiveCycleId,
      employeeId: widget.employeeId,
      scores: payloadScores,
      summaryComment: _summaryCommentController.text.trim(),
      submit: isSubmit,
      existingEvaluationId: _evaluationId,
    );

    if (!mounted) return;

    if (saved != null) {
      final savedId = saved['id'] as String?;
      if (savedId != null) {
        _evaluationId = savedId;
      }

      if (isSubmit) {
        setState(() => _isReadOnly = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSubmit ? 'Evaluation submitted successfully!' : 'Evaluation draft saved successfully!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      if (isSubmit) {
        context.pop();
      }
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

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/manager/team');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgrProvider = Provider.of<ManagerProvider>(context);
    final isLoading = mgrProvider.isLoadingSubmitting;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: CustomAppBar(
          title: _isReadOnly ? 'View ${widget.employeeName}' : 'Evaluate ${widget.employeeName}',
          showDrawerButton: false,
          showBackButton: true,
          onBackPressed: _handleBack,
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: _isLoadingDraft
            ? const LoadingWidget(message: 'Loading saved draft...')
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadExistingEvaluation,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ResponsiveUtils.appBarBody(
                    context: context,
                    scrollable: true,
                    child: ResponsiveUtils.constrainedContent(
                      context,
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_evaluationId != null && !_isReadOnly)
                              Card(
                                color: AppTheme.warningColor.withOpacity(0.08),
                                child: const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded, color: AppTheme.warningColor, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Draft in progress — changes are saved with Save Draft (status: PENDING).',
                                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_evaluationId != null && !_isReadOnly) const SizedBox(height: 12),
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
                                          Text(
                                            _isReadOnly
                                                ? 'Submitted evaluation (read-only)'
                                                : 'Monthly Evaluation Form (5 Fixed Parameters)',
                                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
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
                              'Parameter Ratings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ...AppConfig.fixedParameters.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final param = entry.value;
                              final code = param['code']!;
                              final name = param['name']!;
                              final desc = param['description']!;
                              final currentScore = _scores[code] ?? 4;

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
                                      const Text(
                                        'Score Rating:',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: List.generate(5, (scoreIdx) {
                                          final scoreVal = scoreIdx + 1;
                                          final isSelected = currentScore == scoreVal;

                                          return Semantics(
                                            label: 'Score $scoreVal out of 5',
                                            selected: isSelected,
                                            child: ChoiceChip(
                                              label: Text('$scoreVal ★'),
                                              selected: isSelected,
                                              selectedColor: AppTheme.primaryColor,
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              onSelected: _isReadOnly
                                                  ? null
                                                  : (selected) {
                                                      if (selected) {
                                                        setState(() => _scores[code] = scoreVal);
                                                      }
                                                    },
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
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
                                      readOnly: _isReadOnly,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter overall summary notes for this evaluation cycle...',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!_isReadOnly) ...[
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 480;
                                  final saveDraftButton = SizedBox(
                                    height: ResponsiveUtils.primaryButtonMinHeight,
                                    width: isCompact ? double.infinity : null,
                                    child: OutlinedButton(
                                      onPressed: isLoading ? null : () => _submitOrSaveDraft(isSubmit: false),
                                      child: const Text('Save Draft'),
                                    ),
                                  );
                                  final submitButton = SizedBox(
                                    height: ResponsiveUtils.primaryButtonMinHeight,
                                    width: isCompact ? double.infinity : null,
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
                                  );

                                  if (isCompact) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        saveDraftButton,
                                        const SizedBox(height: 12),
                                        submitButton,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: saveDraftButton),
                                      const SizedBox(width: 16),
                                      Expanded(child: submitButton),
                                    ],
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
