import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
            title: const Text('Dashboard'),
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
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppTheme.primaryColor),
            title: const Text('Evaluation History'),
            onTap: () {
              Navigator.pop(context);
              context.go('/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
            ),
            onTap: () => _confirmLogout(context, authProvider),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
