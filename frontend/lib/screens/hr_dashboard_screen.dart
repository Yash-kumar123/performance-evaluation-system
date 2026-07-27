import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  String? _selectedFilterCycleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final hrProvider = Provider.of<HRProvider>(context, listen: false);
    hrProvider.fetchDashboard(cycleId: _selectedFilterCycleId);
    hrProvider.fetchCycles();
    hrProvider.fetchUsers();
  }

  void _showCreateCycleDialog(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context, listen: false);

    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final monthStr = nextMonth.month.toString().padLeft(2, '0');
    final yearStr = nextMonth.year.toString();

    final nameController = TextEditingController(text: 'Cycle Evaluation ($yearStr-$monthStr)');

    DateTime selectedStartDate = nextMonth;
    DateTime selectedEndDate = DateTime(nextMonth.year, nextMonth.month + 1, 0);

    final startDateController = TextEditingController(
      text: '$yearStr-$monthStr-01',
    );
    final endDateController = TextEditingController(
      text: '$yearStr-$monthStr-${selectedEndDate.day.toString().padLeft(2, '0')}',
    );

    final formKey = GlobalKey<FormState>();

    // Managers list from Users directory (role == MANAGER or compliance roster)
    final managersRoster = hrProvider.usersList.where((u) => u['role'] == 'MANAGER').toList();
    if (managersRoster.isEmpty && hrProvider.managers.isNotEmpty) {
      managersRoster.addAll(hrProvider.managers);
    }

    String selectedManagerId = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Create Review Cycle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure review period, assign manager scope, and set deadline.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 16),

                      // Cycle Name Input
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Cycle Name',
                          hintText: 'e.g. August 2026 Evaluation',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Manager Scope Dropdown with clean isExpanded layout
                      DropdownButtonFormField<String>(
                        value: selectedManagerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Manager Scope',
                          prefixIcon: Icon(Icons.supervisor_account_rounded, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'ALL',
                            child: Text(
                              'All Managers (Company-Wide)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...managersRoster.asMap().entries.map<DropdownMenuItem<String>>((entry) {
                            final idx = entry.key;
                            final m = entry.value;
                            final mId = (m['id'] as String?) ?? (m['manager_id'] as String?) ?? 'mgr_$idx';
                            final mName = (m['full_name'] as String?) ?? (m['manager_name'] as String?) ?? 'Manager';
                            final dept = (m['department'] as String?) ?? '';
                            return DropdownMenuItem<String>(
                              value: mId,
                              child: Text(
                                dept.isNotEmpty ? '$mName ($dept)' : mName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedManagerId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Start Date Picker Field
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedStartDate = picked;
                              final mStr = picked.month.toString().padLeft(2, '0');
                              final dStr = picked.day.toString().padLeft(2, '0');
                              startDateController.text = '${picked.year}-$mStr-$dStr';
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: startDateController,
                            decoration: const InputDecoration(
                              labelText: 'Start Date (Calendar Pick)',
                              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // End Date / Deadline Picker Field
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedEndDate = picked;
                              final mStr = picked.month.toString().padLeft(2, '0');
                              final dStr = picked.day.toString().padLeft(2, '0');
                              endDateController.text = '${picked.year}-$mStr-$dStr';
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: endDateController,
                            decoration: const InputDecoration(
                              labelText: 'End Date / Deadline (Calendar Pick)',
                              suffixIcon: Icon(Icons.event_available_rounded, size: 18),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
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
                    final hrProv = Provider.of<HRProvider>(context, listen: false);

                    // Derive cycle code automatically from start date
                    final sDate = selectedStartDate;
                    final derivedCode = '${sDate.year}-${sDate.month.toString().padLeft(2, '0')}';

                    final success = await hrProv.createCycle(
                      name: nameController.text.trim(),
                      cycleCode: derivedCode,
                      startDate: startDateController.text.trim(),
                      endDate: endDateController.text.trim(),
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Evaluation cycle created successfully!' : (hrProv.errorAction ?? 'Failed to create cycle.'),
                        ),
                        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    );
                  },
                  child: const Text('Create Cycle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'HR Compliance Portal'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: Builder(
        builder: (context) {
          if (hrProvider.isLoadingDashboard) {
            return const LoadingWidget(message: 'Loading HR metrics & manager compliance...');
          }

          if (hrProvider.errorDashboard != null) {
            return CustomErrorWidget(
              message: hrProvider.errorDashboard!,
              onRetry: () => hrProvider.fetchDashboard(),
            );
          }

          final cycleName = hrProvider.cycle?['name'] ?? 'Active Cycle';

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Cycle Creation Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evaluation Compliance Overview',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tenant Active Cycle: $cycleName',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateCycleDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Cycle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cycle Filter Dropdown Bar
                  if (hrProvider.cyclesList.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt_rounded, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Filter Review Cycle:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFilterCycleId ?? hrProvider.cycle?['id'],
                                  isExpanded: true,
                                  items: hrProvider.cyclesList.map<DropdownMenuItem<String>>((c) {
                                    final cId = c['id'] as String;
                                    final cName = c['name'] ?? 'Cycle';
                                    final cCode = c['cycle_code'] ?? '';
                                    final isActive = (c['is_active'] as bool?) ?? false;

                                    return DropdownMenuItem<String>(
                                      value: cId,
                                      child: Text(
                                        '$cName ($cCode)${isActive ? " • ACTIVE" : ""}',
                                        style: TextStyle(
                                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedFilterCycleId = val;
                                      });
                                      hrProvider.fetchDashboard(cycleId: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 4 Top Metric Analytics Cards Grid
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSummaryCard(
                        title: 'Total Active Employees',
                        value: '${hrProvider.totalEmployees}',
                        icon: Icons.people_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      _buildSummaryCard(
                        title: 'Total Managers',
                        value: '${hrProvider.totalManagers}',
                        icon: Icons.supervisor_account_rounded,
                        color: AppTheme.secondaryColor,
                      ),
                      _buildSummaryCard(
                        title: 'Completed Reviews',
                        value: '${hrProvider.completedReviews}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.successColor,
                      ),
                      _buildSummaryCard(
                        title: 'Pending Submissions',
                        value: '${hrProvider.pendingReviews}',
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warningColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overall Submission Progress Bar Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Overall Manager Submissions Compliance Rate',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${hrProvider.overallCompletionPercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: hrProvider.overallCompletionPercentage / 100.0,
                              minHeight: 12,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Manager-Wise Submission Compliance Breakdown Table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manager Submission Status Roster',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${hrProvider.managers.length} Managers',
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (hrProvider.managers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No manager submission records found for this cycle.',
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Manager Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Direct Reports', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Submission Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: hrProvider.managers.map((m) {
                            final name = m['manager_name'] ?? 'Manager';
                            final dept = m['department'] ?? 'General';
                            final totalReports = m['total_direct_reports'] ?? 0;
                            final completed = m['completed_submissions'] ?? 0;
                            final pending = m['pending_submissions'] ?? 0;
                            final status = m['submission_status'] ?? 'PENDING';

                            Color statusColor = AppTheme.warningColor;
                            if (status == 'COMPLETED') statusColor = AppTheme.successColor;
                            if (status == 'IN_PROGRESS') statusColor = AppTheme.primaryColor;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(dept)),
                                DataCell(Text('$totalReports Employees')),
                                DataCell(Text('$completed', style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold))),
                                DataCell(Text('$pending', style: TextStyle(color: pending > 0 ? AppTheme.warningColor : AppTheme.textSecondaryColor))),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      status.replaceAll('_', ' '),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                    backgroundColor: statusColor,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
