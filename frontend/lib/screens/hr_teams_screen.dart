import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/widgets/empty_state_widget.dart';

class HRTeamsScreen extends StatefulWidget {
  const HRTeamsScreen({super.key});

  @override
  State<HRTeamsScreen> createState() => _HRTeamsScreenState();
}

class _HRTeamsScreenState extends State<HRTeamsScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HRProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'Password123!');
    final titleController = TextEditingController();
    final deptController = TextEditingController();
    String selectedRole = 'EMPLOYEE';
    String? selectedManagerId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hrProvider = Provider.of<HRProvider>(context, listen: false);
          final managers = hrProvider.usersList.where((u) => u['role'] == 'MANAGER' || u['role'] == 'HR').toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Add Team Member'),
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
                      decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. John Doe'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address', hintText: 'john@company.com'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Initial Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee')),
                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                        DropdownMenuItem(value: 'HR', child: Text('HR Admin')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Job Title', hintText: 'e.g. Senior Developer'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deptController,
                      decoration: const InputDecoration(labelText: 'Department', hintText: 'e.g. Engineering'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedManagerId,
                      decoration: const InputDecoration(labelText: 'Assigned Direct Manager'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Top Executive / Manager)', style: TextStyle(color: AppTheme.textSecondaryColor)),
                        ),
                        ...managers.map<DropdownMenuItem<String?>>((m) {
                          return DropdownMenuItem<String?>(
                            value: m['id'] as String,
                            child: Text('${m['full_name']} (${m['job_title'] ?? m['role']})'),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setModalState(() => selectedManagerId = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final hrProv = Provider.of<HRProvider>(context, listen: false);
                  final success = await hrProv.createUser(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                    jobTitle: titleController.text.trim(),
                    department: deptController.text.trim(),
                    managerId: selectedManagerId,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Team member added successfully!' : (hrProv.errorAction ?? 'Failed to add user.')),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                },
                child: const Text('Add Member'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final nameController = TextEditingController(text: user['full_name'] ?? '');
    final titleController = TextEditingController(text: user['job_title'] ?? '');
    final deptController = TextEditingController(text: user['department'] ?? '');
    String selectedRole = user['role'] ?? 'EMPLOYEE';
    String? selectedManagerId = user['manager_id'] as String?;
    bool isActive = (user['is_active'] as bool?) ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hrProvider = Provider.of<HRProvider>(context, listen: false);
          final managers = hrProvider.usersList
              .where((u) => u['id'] != userId && (u['role'] == 'MANAGER' || u['role'] == 'HR'))
              .toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.manage_accounts_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Edit Team Member'),
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
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'System Role'),
                      items: const [
                        DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee')),
                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                        DropdownMenuItem(value: 'HR', child: Text('HR Admin')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Job Title'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deptController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedManagerId,
                      decoration: const InputDecoration(labelText: 'Assigned Direct Manager'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Top Executive)', style: TextStyle(color: AppTheme.textSecondaryColor)),
                        ),
                        ...managers.map<DropdownMenuItem<String?>>((m) {
                          return DropdownMenuItem<String?>(
                            value: m['id'] as String,
                            child: Text('${m['full_name']} (${m['job_title'] ?? m['role']})'),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setModalState(() => selectedManagerId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Account Active'),
                      value: isActive,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final hrProv = Provider.of<HRProvider>(context, listen: false);
                  final success = await hrProv.updateUser(
                    userId: userId,
                    fullName: nameController.text.trim(),
                    role: selectedRole,
                    jobTitle: titleController.text.trim(),
                    department: deptController.text.trim(),
                    managerId: selectedManagerId,
                    isActive: isActive,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Member details updated!' : (hrProv.errorAction ?? 'Update failed.')),
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

  void _confirmDeleteUser(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Team Member'),
        content: Text('Are you sure you want to deactivate "$name"? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final hrProv = Provider.of<HRProvider>(context, listen: false);
              final success = await hrProv.deleteUser(userId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Member deactivated successfully.' : (hrProv.errorAction ?? 'Deactivation failed.')),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HRProvider>(context);

    final query = _searchController.text.trim().toLowerCase();
    final filteredUsers = hrProvider.usersList.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final title = (u['job_title'] ?? '').toString().toLowerCase();
      final dept = (u['department'] ?? '').toString().toLowerCase();
      final role = u['role'] ?? 'EMPLOYEE';

      final matchesQuery = name.contains(query) || email.contains(query) || title.contains(query) || dept.contains(query);
      final matchesRole = _selectedRoleFilter == 'ALL' || role == _selectedRoleFilter;

      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Teams & Members Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Team Member',
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search members by name, email, department...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Role Filter: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All Members'),
                      selected: _selectedRoleFilter == 'ALL',
                      onSelected: (s) {
                        if (s) setState(() => _selectedRoleFilter = 'ALL');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Managers'),
                      selected: _selectedRoleFilter == 'MANAGER',
                      onSelected: (s) {
                        if (s) setState(() => _selectedRoleFilter = 'MANAGER');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Employees'),
                      selected: _selectedRoleFilter == 'EMPLOYEE',
                      onSelected: (s) {
                        if (s) setState(() => _selectedRoleFilter = 'EMPLOYEE');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Users List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => hrProvider.fetchUsers(),
              child: Builder(
                builder: (context) {
                  if (hrProvider.isLoadingUsers) {
                    return const LoadingWidget(message: 'Loading team directory...');
                  }

                  if (hrProvider.errorUsers != null) {
                    return CustomErrorWidget(
                      message: hrProvider.errorUsers!,
                      onRetry: () => hrProvider.fetchUsers(),
                    );
                  }

                  if (filteredUsers.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Team Members Found',
                      message: 'No users matched your current search or filter criteria.',
                      icon: Icons.people_outline_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      final userId = u['id'] as String;
                      final name = u['full_name'] ?? 'User';
                      final email = u['email'] ?? '';
                      final role = u['role'] ?? 'EMPLOYEE';
                      final title = u['job_title'] ?? 'Staff Member';
                      final dept = u['department'] ?? 'General';
                      final mgrName = u['manager_name'] as String?;
                      final isActive = (u['is_active'] as bool?) ?? true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (role == 'MANAGER'
                                            ? AppTheme.primaryColor
                                            : role == 'HR'
                                                ? AppTheme.secondaryColor
                                                : AppTheme.successColor)
                                        .withOpacity(0.12),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        color: role == 'MANAGER'
                                            ? AppTheme.primaryColor
                                            : role == 'HR'
                                                ? AppTheme.secondaryColor
                                                : AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            if (!isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.errorColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('INACTIVE', style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('$email • $dept', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      role,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                    backgroundColor: role == 'MANAGER'
                                        ? AppTheme.primaryColor
                                        : role == 'HR'
                                            ? AppTheme.secondaryColor
                                            : AppTheme.successColor,
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.work_outline_rounded, size: 16, color: AppTheme.textSecondaryColor),
                                  const SizedBox(width: 6),
                                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  if (mgrName != null) ...[
                                    const Icon(Icons.supervisor_account_rounded, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text('Manager: $mgrName', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                                  ]
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showEditUserDialog(context, u),
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Edit Member'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmDeleteUser(context, userId, name),
                                    icon: const Icon(Icons.person_off_rounded, size: 16, color: AppTheme.errorColor),
                                    label: const Text('Deactivate', style: TextStyle(color: AppTheme.errorColor)),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}
