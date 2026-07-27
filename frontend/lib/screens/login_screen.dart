import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../core/config/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/utils/responsive_utils.dart';
import '../core/widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user?.fullName}! (${user?.companyName})'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Automatic Role-based Navigation
      if (user?.role == 'HR') {
        context.go('/hr');
      } else if (user?.role == 'MANAGER') {
        context.go('/manager');
      } else {
        context.go('/employee');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Authentication failed.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _fillPresetCredentials(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: ResponsiveUtils.scrollPadding(
              context,
              base: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
            ),
            child: ResponsiveUtils.constrainedContent(
              context,
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Centered Box Container Structure
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtleColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Gradient Top Box Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              const AppLogo(size: 88),
                              const SizedBox(height: 12),
                              Text(
                                AppConfig.appName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Single Universal Login Portal',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Content Box
                        Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Input Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'name@company.com',
                                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email address.';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Input Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Error Message Banner if any
                                if (authProvider.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Submit Button
                                Semantics(
                                  button: true,
                                  label: 'Sign in to your account',
                                  child: ResponsiveUtils.primaryButton(
                                    onPressed: isLoading ? null : _handleLogin,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Multi-Company Quick Demo Presets Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtleColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, color: AppTheme.primaryColor, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Quick Demo Login Presets (Multi-Tenant Demo)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Company 1: Ashoka Textiles
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.business_rounded, color: AppTheme.primaryColor, size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ashoka Textiles (Enterprise Hierarchy)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.admin_panel_settings, size: 13),
                                    label: const Text('Neha (HR Admin)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('hr@ashoka.com', 'Password123!'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.shield_outlined, size: 13),
                                    label: const Text('Rajesh (COO)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('coo@ashoka.com', 'Password123!'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.supervisor_account, size: 13),
                                    label: const Text('Priya (Manager)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('priya@ashoka.com', 'Password123!'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.person_outline, size: 13),
                                    label: const Text('Aarav (Employee)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('aarav@ashoka.com', 'Password123!'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Company 2: Bright Path Consulting
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storefront_rounded, color: AppTheme.secondaryColor, size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    'Bright Path Consulting (Flat Structure)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.admin_panel_settings, size: 13),
                                    label: const Text('Siddharth (HR Head)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('hr@brightpath.com', 'Password123!'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.workspace_premium, size: 13),
                                    label: const Text('Vikram (Founder & Mgr)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('founder@brightpath.com', 'Password123!'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.person_outline, size: 13),
                                    label: const Text('Aditi (Consultant)', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _fillPresetCredentials('aditi@brightpath.com', 'Password123!'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
