import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class ReviewCyclesScreen extends StatefulWidget {
  const ReviewCyclesScreen({super.key});

  @override
  State<ReviewCyclesScreen> createState() => _ReviewCyclesScreenState();
}

class _ReviewCyclesScreenState extends State<ReviewCyclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HRProvider>(context, listen: false).fetchCycles();
    });
  }

  void _showEditCycleDialog(BuildContext context, Map<String, dynamic> cycle) {
    final cycleId = cycle['id'] as String;
    final nameController = TextEditingController(text: cycle['name'] ?? '');
    final startDateController = TextEditingController(text: (cycle['start_date'] as String? ?? '').split('T')[0]);
    final endDateController = TextEditingController(text: (cycle['end_date'] as String? ?? '').split('T')[0]);
    bool isActive = (cycle['is_active'] as bool?) ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Edit Review Cycle'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Cycle Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: startDateController,
                      decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: endDateController,
                      decoration: const InputDecoration(labelText: 'End Date / Deadline (YYYY-MM-DD)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Set as Active Cycle'),
                      value: isActive,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setModalState(() {
                          isActive = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final hrProvider = Provider.of<HRProvider>(context, listen: false);
                  final success = await hrProvider.updateCycle(
                    cycleId: cycleId,
                    name: nameController.text.trim(),
                    startDate: startDateController.text.trim(),
                    endDate: endDateController.text.trim(),
                    isActive: isActive,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Review cycle updated successfully!' : (hrProvider.errorAction ?? 'Update failed.')),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCycle(BuildContext context, String cycleId, String cycleName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review Cycle'),
        content: Text('Are you sure you want to delete "$cycleName"? Associated evaluations will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final hrProvider = Provider.of<HRProvider>(context, listen: false);
              final success = await hrProvider.deleteCycle(cycleId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Review cycle deleted successfully.' : (hrProvider.errorAction ?? 'Delete failed.')),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hrProvider = Provider.of<HRProvider>(context);
    final isHR = authProvider.isHR;
    final cycles = hrProvider.cyclesList;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Evaluation Review Cycles'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await hrProvider.fetchCycles();
        },
        child: Builder(
          builder: (context) {
            if (hrProvider.isLoadingCycles) {
              return const LoadingWidget(message: 'Loading review cycles...');
            }

            if (hrProvider.errorCycles != null) {
              return CustomErrorWidget(
                message: hrProvider.errorCycles!,
                onRetry: () => hrProvider.fetchCycles(),
              );
            }

            if (cycles.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Review Cycles Found',
                message: 'No evaluation cycles have been created for this company yet.',
                icon: Icons.calendar_month_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final c = cycles[index];
                final cycleId = c['id'] as String;
                final name = c['name'] ?? 'Evaluation Cycle';
                final startDate = (c['start_date'] as String? ?? '').split('T')[0];
                final endDate = (c['end_date'] as String? ?? '').split('T')[0];
                final isActive = (c['is_active'] as bool?) ?? false;

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
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppTheme.successColor : AppTheme.primaryColor).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: isActive ? AppTheme.successColor : AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Chip(
                              label: Text(
                                isActive ? 'ACTIVE CYCLE' : 'CLOSED',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              backgroundColor: isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Period: $startDate to $endDate',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (isHR) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showEditCycleDialog(context, c),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _confirmDeleteCycle(context, cycleId, name),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.errorColor),
                                label: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                              ),
                            ],
                          ),
                        ],
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
