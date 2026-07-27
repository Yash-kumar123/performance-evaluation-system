import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showDrawerButton;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showDrawerButton = true,
    this.showBackButton,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final bool canGoBack = showBackButton ?? (context.canPop() && !showDrawerButton);
    final isCompact = ResponsiveUtils.isCompact(context);

    return AppBar(
      title: Text(title),
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: onBackPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // Fallback navigation by role if pop stack is empty
                      if (user?.role == 'HR') {
                        context.go('/hr');
                      } else if (user?.role == 'MANAGER') {
                        context.go('/manager');
                      } else {
                        context.go('/employee');
                      }
                    }
                  },
            )
          : null,
      actions: [
        if (user != null && !isCompact)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Semantics(
              label: 'Signed in as ${user.fullName}, role ${user.role}',
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
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
