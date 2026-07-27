import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close drawer
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false, // UserAccountsDrawerHeader handles top safely
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              accountName: Text(
                user?.fullName ?? 'User Profile',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                '${user?.email ?? ''} • ${user?.companyName ?? ''}',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
              currentAccountPicture: ClipOval(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(4),
                  child: const AppLogo(size: 56),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                AppConfig.appName,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
              title: const Text('Dashboard'),
              minLeadingWidth: 24,
              minVerticalPadding: 12,
              onTap: () {
                Navigator.pop(context);
                if (authProvider.isHR) {
                  context.go('/hr');
                } else if (authProvider.isManager) {
                  context.go('/manager');
                } else {
                  context.go('/employee');
                }
              },
            ),
            if (authProvider.isHR) ...[
              ListTile(
                leading: const Icon(Icons.groups_rounded, color: AppTheme.primaryColor),
                title: const Text('Teams Hierarchy'),
                minLeadingWidth: 24,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/hr/teams');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_tree_rounded, color: AppTheme.primaryColor),
                title: const Text('Project Teams'),
                minLeadingWidth: 24,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/hr/project-teams');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
              title: const Text('Review Cycles'),
              minLeadingWidth: 24,
              onTap: () {
                Navigator.pop(context);
                context.go('/cycles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppTheme.primaryColor),
              title: const Text('Evaluation History'),
              minLeadingWidth: 24,
              onTap: () {
                Navigator.pop(context);
                context.go('/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
              title: const Text('My Profile'),
              minLeadingWidth: 24,
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            const Divider(),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Logout from application',
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                ),
                minLeadingWidth: 24,
                minVerticalPadding: 12,
                onTap: () => _confirmLogout(context, authProvider),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
