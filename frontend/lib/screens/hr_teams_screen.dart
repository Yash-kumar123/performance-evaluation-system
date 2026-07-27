import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/hr_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/custom_error_widget.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/utils/responsive_utils.dart';

class HRTeamsScreen extends StatefulWidget {
  const HRTeamsScreen({super.key});

  @override
  State<HRTeamsScreen> createState() => _HRTeamsScreenState();
}

class _HRTeamsScreenState extends State<HRTeamsScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'ALL';
  String _selectedManagerId = 'ALL';
  bool _groupByManagerView = true; // Accordion hierarchy view by default

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
    var obscurePassword = true;

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
            content: SafeArea(
              child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', hintText: 'john@company.com'),
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
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
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

    // 1. Filter Users
    final filteredUsers = hrProvider.usersList.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final title = (u['job_title'] ?? '').toString().toLowerCase();
      final dept = (u['department'] ?? '').toString().toLowerCase();
      final role = u['role'] ?? 'EMPLOYEE';
      final managerId = u['manager_id'] as String?;

      final matchesQuery = name.contains(query) || email.contains(query) || title.contains(query) || dept.contains(query);
      final matchesRole = _selectedRoleFilter == 'ALL' || role == _selectedRoleFilter;
      final matchesManager = _selectedManagerId == 'ALL' || managerId == _selectedManagerId || u['id'] == _selectedManagerId;

      return matchesQuery && matchesRole && matchesManager;
    }).toList();

    // Extract list of managers for dropdown filter
    final managersList = hrProvider.usersList.where((u) => u['role'] == 'MANAGER' || u['role'] == 'HR').toList();

    // Grouping by Manager
    final Map<String, List<dynamic>> managerGroupMap = {};
    for (var u in filteredUsers) {
      final mId = (u['manager_id'] as String?) ?? 'UNASSIGNED';
      managerGroupMap.putIfAbsent(mId, () => []).add(u);
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Teams & Members Hierarchy',
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
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Filter & View Controller Bar
          Container(
            padding: ResponsiveUtils.screenPadding(context),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search members by name, title, department...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Manager Filter Dropdown & View Mode Switcher
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 560;
                    final managerDropdown = DropdownButtonFormField<String>(
                      value: _selectedManagerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Manager Team Dropdown',
                        prefixIcon: Icon(Icons.supervisor_account_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'ALL',
                          child: Text('All Manager Teams', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...managersList.map<DropdownMenuItem<String>>((m) {
                          final mId = m['id'] as String;
                          final mName = m['full_name'] as String? ?? 'Manager';
                          final dept = m['department'] as String? ?? '';
                          return DropdownMenuItem<String>(
                            value: mId,
                            child: Text('$mName ($dept team)', overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedManagerId = val);
                        }
                      },
                    );

                    final viewToggle = IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _groupByManagerView = !_groupByManagerView;
                        });
                      },
                      icon: Icon(
                        _groupByManagerView ? Icons.account_tree_rounded : Icons.list_alt_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      tooltip: _groupByManagerView ? 'Switch to Flat Directory' : 'Switch to Manager Accordion Tree',
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          managerDropdown,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerRight, child: viewToggle),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: managerDropdown),
                        const SizedBox(width: 12),
                        viewToggle,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Role Filter: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All Roles'),
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
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Directory Content (Grouped Manager Accordion vs Flat Directory)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => hrProvider.fetchUsers(),
              child: Builder(
                builder: (context) {
                  if (hrProvider.isLoadingUsers) {
                    return const LoadingWidget(message: 'Loading team directory & manager hierarchies...');
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

                  // 1. MANAGER ACCORDION TREE VIEW
                  if (_groupByManagerView) {
                    final managerCards = managersList.where((m) {
                      if (_selectedManagerId != 'ALL' && m['id'] != _selectedManagerId) {
                        return false;
                      }
                      return true;
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: managerCards.length,
                      itemBuilder: (context, index) {
                        final m = managerCards[index];
                        final mId = m['id'] as String;
                        final mName = m['full_name'] ?? 'Manager';
                        final mTitle = m['job_title'] ?? 'Manager';
                        final mDept = m['department'] ?? 'Department';
                        final mEmail = m['email'] ?? '';

                        // Direct reports under this manager
                        final reports = hrProvider.usersList.where((u) => u['manager_id'] == mId).toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.supervisor_account_rounded, color: AppTheme.primaryColor, size: 22),
                            ),
                            title: Text(
                              mName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('$mTitle • $mDept ($mEmail)'),
                            trailing: Chip(
                              label: Text(
                                '${reports.length} Direct Reports',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              side: BorderSide.none,
                            ),
                            children: [
                              Container(
                                color: AppTheme.backgroundColor,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: reports.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'No direct reports currently assigned to this manager.',
                                          style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondaryColor, fontSize: 13),
                                        ),
                                      )
                                    : Column(
                                        children: reports.map((emp) {
                                          final empId = emp['id'] as String;
                                          final empName = emp['full_name'] ?? 'Employee';
                                          final empEmail = emp['email'] ?? '';
                                          final empTitle = emp['job_title'] ?? 'Staff Member';
                                          final empDept = emp['department'] ?? 'General';
                                          final isActive = (emp['is_active'] as bool?) ?? true;

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            color: Colors.white,
                                            elevation: 0.5,
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                              leading: CircleAvatar(
                                                radius: 18,
                                                backgroundColor: AppTheme.successColor.withOpacity(0.12),
                                                child: Text(
                                                  empName.isNotEmpty ? empName[0].toUpperCase() : 'E',
                                                  style: const TextStyle(
                                                    color: AppTheme.successColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Text(
                                                    empName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                  if (!isActive) ...[
                                                    const SizedBox(width: 6),
                                                    const Text('(INACTIVE)', style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                ],
                                              ),
                                              subtitle: Text('$empTitle • $empDept ($empEmail)', style: const TextStyle(fontSize: 12)),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryColor),
                                                    tooltip: 'Edit / Reassign Manager',
                                                    onPressed: () => _showEditUserDialog(context, emp),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.person_off_rounded, size: 18, color: AppTheme.errorColor),
                                                    tooltip: 'Deactivate',
                                                    onPressed: () => _confirmDeleteUser(context, empId, empName),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // 2. FLAT DIRECTORY VIEW
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
      ),
    );
  }
}
