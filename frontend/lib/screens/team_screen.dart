import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/manager_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/utils/responsive_utils.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'ALL';
  bool _initializedFilterFromUrl = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFilterFromUrl) {
      final uri = GoRouterState.of(context).uri;
      final queryFilter = uri.queryParameters['filter'];
      if (queryFilter != null && queryFilter.isNotEmpty) {
        _selectedFilter = queryFilter;
      }
      _initializedFilterFromUrl = true;
    }
  }

  void _loadData() {
    Provider.of<ManagerProvider>(context, listen: false).fetchTeamStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRegisterMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'Password123!');
    final titleController = TextEditingController(text: 'Team Member');
    final deptController = TextEditingController(text: 'Operations');
    final formKey = GlobalKey<FormState>();
    var obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Register New Team Member'),
          ],
        ),
        content: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a new employee to your direct reporting roster.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Karan Verma',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. karan@company.com',
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Temporary Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: obscurePassword ? 'Show password' : 'Hide password',
                        onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                      hintText: 'e.g. Senior Analyst',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: deptController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      hintText: 'e.g. Engineering',
                    ),
                  ),
                ],
              ),
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
              final mgrProvider = Provider.of<ManagerProvider>(context, listen: false);
              final success = await mgrProvider.addTeamMember(
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
                jobTitle: titleController.text.trim(),
                department: deptController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Team member registered successfully!' : (mgrProvider.errorAddMember ?? 'Registration failed.'),
                  ),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Register Member'),
          ),
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return AppTheme.successColor;
      case 'PENDING':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'SUBMITTED':
        return 'Submitted';
      case 'PENDING':
        return 'Draft Saved';
      default:
        return 'Not Started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgrProvider = Provider.of<ManagerProvider>(context);

    // Filter Logic
    final query = _searchController.text.trim().toLowerCase();
    final filteredTeam = mgrProvider.teamStatus.where((item) {
      final name = (item['employee_name'] ?? '').toString().toLowerCase();
      final title = (item['job_title'] ?? '').toString().toLowerCase();
      final status = item['status'] ?? 'NOT_STARTED';

      final matchesQuery = name.contains(query) || title.contains(query);
      final matchesFilter = _selectedFilter == 'ALL' ||
          status == _selectedFilter ||
          (_selectedFilter == 'PENDING' && (status == 'PENDING' || status == 'NOT_STARTED'));

      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Direct Team',
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/manager');
          }
        },
      ),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Search & Action Header Container
          Container(
            padding: ResponsiveUtils.screenPadding(context),
            color: Colors.white,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 520;
                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search direct reports...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: ResponsiveUtils.primaryButtonMinHeight,
                            child: ElevatedButton.icon(
                              onPressed: () => _showRegisterMemberDialog(context),
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text('Add Member'),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search direct reports...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showRegisterMemberDialog(context),
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Add Member'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Filter Status: ',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All Reports'),
                            const SizedBox(width: 8),
                            _buildFilterChip('PENDING', 'Pending Reviews'),
                            const SizedBox(width: 8),
                            _buildFilterChip('SUBMITTED', 'Submitted'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Direct Reports List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: Builder(
                builder: (context) {
                  if (mgrProvider.isLoadingTeam) {
                    return const LoadingWidget(message: 'Loading direct reports roster...');
                  }

                  if (mgrProvider.errorTeam != null) {
                    return CustomErrorWidget(
                      message: mgrProvider.errorTeam!,
                      onRetry: () => _loadData(),
                    );
                  }

                  if (filteredTeam.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Direct Reports Found',
                      message: 'No employees matched your current search or filter criteria.',
                      icon: Icons.person_search_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredTeam.length,
                    itemBuilder: (context, index) {
                      final emp = filteredTeam[index];
                      final empId = emp['employee_id'] as String;
                      final name = emp['employee_name'] ?? 'Employee';
                      final title = emp['job_title'] ?? 'Staff Member';
                      final status = emp['status'] ?? 'NOT_STARTED';
                      final evalId = emp['evaluation_id'] as String?;

                      final cycleId = mgrProvider.activeCycle?['id'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          isThreeLine: true,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(status),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    status == 'SUBMITTED'
                                        ? 'View'
                                        : status == 'PENDING'
                                            ? 'Continue Draft'
                                            : 'Evaluate',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
                          onTap: () {
                            if (status == 'SUBMITTED' && evalId != null) {
                              context.push('/evaluation/$evalId');
                            } else {
                              context.push(
                                Uri(
                                  path: '/manager/create-evaluation',
                                  queryParameters: {
                                    'employeeId': empId,
                                    'employeeName': name,
                                    'cycleId': cycleId,
                                    if (evalId != null) 'evaluationId': evalId,
                                  },
                                ).toString(),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }
}
