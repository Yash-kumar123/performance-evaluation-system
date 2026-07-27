import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/widgets/custom_app_bar.dart';
import '../core/widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Profile'),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      child: Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'User Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        user?.role ?? 'EMPLOYEE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Details List Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.work_outline_rounded,
                      title: 'Job Title',
                      value: user?.jobTitle ?? 'Not Specified',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.corporate_fare_rounded,
                      title: 'Department',
                      value: user?.department ?? 'General',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.business_rounded,
                      title: 'Company Tenant',
                      value: user?.companyName ?? 'Organization',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
