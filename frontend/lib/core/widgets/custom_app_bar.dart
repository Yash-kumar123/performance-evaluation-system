import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showDrawerButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showDrawerButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return AppBar(
      title: Text(title),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              label: Text(
                user.role,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              side: BorderSide.none,
            ),
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
