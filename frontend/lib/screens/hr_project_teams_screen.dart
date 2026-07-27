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

class HRProjectTeamsScreen extends StatefulWidget {
  const HRProjectTeamsScreen({super.key});

  @override
  State<HRProjectTeamsScreen> createState() => _HRProjectTeamsScreenState();
}

class _HRProjectTeamsScreenState extends State<HRProjectTeamsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hrProvider = Provider.of<HRProvider>(context, listen: false);
      hrProvider.fetchProjectTeams();
      hrProvider.fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    String? selectedLeadManagerId;
    List<String> selectedMemberIds = [];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hrProvider = Provider.of<HRProvider>(context, listen: false);
          final managers = hrProvider.usersList.where((u) => u['role'] == 'MANAGER' || u['role'] == 'HR').toList();
          final allUsers = hrProvider.usersList;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.group_add_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Create Project Team'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Project Team Name', hintText: 'e.g. Mobile App Automation'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Project Code', hintText: 'e.g. PRJ-MOBILE-2026'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description / Scope'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedLeadManagerId,
                      decoration: const InputDecoration(labelText: 'Assigned Lead Manager'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned', style: TextStyle(color: AppTheme.textSecondaryColor)),
                        ),
                        ...managers.map<DropdownMenuItem<String?>>((m) {
                          return DropdownMenuItem<String?>(
                            value: m['id'] as String,
                            child: Text('${m['full_name']} (${m['job_title'] ?? m['role']})'),
                          );
                        }),
                      ],
                      onChanged: (v) => setModalState(() => selectedLeadManagerId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Team Members:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderSubtleColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final u = allUsers[index];
                          final uId = u['id'] as String;
                          final uName = u['full_name'] as String? ?? 'User';
                          final isSelected = selectedMemberIds.contains(uId);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(uName),
                            subtitle: Text('${u['role']} • ${u['job_title'] ?? ''}'),
                            value: isSelected,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedMemberIds.add(uId);
                                } else {
                                  selectedMemberIds.remove(uId);
                                }
                              });
                            },
                          );
                        },
                      ),
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
                  final success = await hrProv.createProjectTeam(
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    description: descController.text.trim(),
                    leadManagerId: selectedLeadManagerId,
                    memberIds: selectedMemberIds,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Project team created successfully!' : (hrProv.errorAction ?? 'Creation failed.')),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                },
                child: const Text('Create Team'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, Map<String, dynamic> team) {
    final teamId = team['id'] as String;
    final nameController = TextEditingController(text: team['name'] ?? '');
    final codeController = TextEditingController(text: team['code'] ?? '');
    final descController = TextEditingController(text: team['description'] ?? '');
    String? selectedLeadManagerId = team['lead_manager_id'] as String?;
    
    final membersList = (team['members'] as List<dynamic>?) ?? [];
    List<String> selectedMemberIds = membersList.map<String>((m) => m['id'] as String).toList();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hrProvider = Provider.of<HRProvider>(context, listen: false);
          final managers = hrProvider.usersList.where((u) => u['role'] == 'MANAGER' || u['role'] == 'HR').toList();
          final allUsers = hrProvider.usersList;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Edit Project Team'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Project Team Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Project Code'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description / Scope'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedLeadManagerId,
                      decoration: const InputDecoration(labelText: 'Assigned Lead Manager'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned', style: TextStyle(color: AppTheme.textSecondaryColor)),
                        ),
                        ...managers.map<DropdownMenuItem<String?>>((m) {
                          return DropdownMenuItem<String?>(
                            value: m['id'] as String,
                            child: Text('${m['full_name']} (${m['job_title'] ?? m['role']})'),
                          );
                        }),
                      ],
                      onChanged: (v) => setModalState(() => selectedLeadManagerId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Team Members:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderSubtleColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final u = allUsers[index];
                          final uId = u['id'] as String;
                          final uName = u['full_name'] as String? ?? 'User';
                          final isSelected = selectedMemberIds.contains(uId);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(uName),
                            subtitle: Text('${u['role']} • ${u['job_title'] ?? ''}'),
                            value: isSelected,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedMemberIds.add(uId);
                                } else {
                                  selectedMemberIds.remove(uId);
                                }
                              });
                            },
                          );
                        },
                      ),
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
                  final success = await hrProv.updateProjectTeam(
                    teamId: teamId,
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    description: descController.text.trim(),
                    leadManagerId: selectedLeadManagerId,
                    memberIds: selectedMemberIds,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Project team updated successfully!' : (hrProv.errorAction ?? 'Update failed.')),
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

  void _confirmDeleteTeam(BuildContext context, String teamId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project Team'),
        content: Text('Are you sure you want to delete the project team "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final hrProv = Provider.of<HRProvider>(context, listen: false);
              final success = await hrProv.deleteProjectTeam(teamId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Project team deleted.' : (hrProv.errorAction ?? 'Delete failed.')),
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
    final hrProvider = Provider.of<HRProvider>(context);
    final teams = hrProvider.projectTeamsList;

    final query = _searchController.text.trim().toLowerCase();
    final filteredTeams = teams.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final code = (t['code'] ?? '').toString().toLowerCase();
      final desc = (t['description'] ?? '').toString().toLowerCase();
      final mgr = (t['lead_manager_name'] ?? '').toString().toLowerCase();

      return name.contains(query) || code.contains(query) || desc.contains(query) || mgr.contains(query);
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Project Teams Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Create Project Team',
            onPressed: () => _showCreateTeamDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          Container(
            padding: ResponsiveUtils.screenPadding(context),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search project teams by name, project code, manager...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => hrProvider.fetchProjectTeams(),
              child: Builder(
                builder: (context) {
                  if (hrProvider.isLoadingProjectTeams) {
                    return const LoadingWidget(message: 'Loading project teams...');
                  }

                  if (hrProvider.errorProjectTeams != null) {
                    return CustomErrorWidget(
                      message: hrProvider.errorProjectTeams!,
                      onRetry: () => hrProvider.fetchProjectTeams(),
                    );
                  }

                  if (filteredTeams.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Project Teams Found',
                      message: 'No project teams have been created yet. Tap + to add a project team.',
                      icon: Icons.account_tree_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final t = filteredTeams[index];
                      final teamId = t['id'] as String;
                      final name = t['name'] ?? 'Project Team';
                      final code = t['code'] ?? '';
                      final desc = t['description'] ?? '';
                      final mgrName = t['lead_manager_name'] as String?;
                      final members = (t['members'] as List<dynamic>?) ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.account_tree_rounded, color: AppTheme.secondaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (code.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text('Code: $code', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      '${members.length} Members',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                    backgroundColor: AppTheme.primaryColor,
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.supervisor_account_rounded, size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    mgrName != null ? 'Lead Manager: $mgrName' : 'Lead Manager: Unassigned',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showEditTeamDialog(context, t),
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Edit Team'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmDeleteTeam(context, teamId, name),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.errorColor),
                                    label: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
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
