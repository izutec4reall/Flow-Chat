import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';
import '../../theme/theme_provider.dart';
import '../../theme/locale_provider.dart';
import '../../widgets/toggle_chip.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  bool _isLoading = false;

  void _signup() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('fillAllFields'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

        if (credential?.user != null) {
          final rawName = _nameController.text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final randomNum = DateTime.now().millisecondsSinceEpoch % 10000;
          final autoUsername = '$rawName$randomNum';

          final newUser = UserModel(
            uid: credential!.user!.uid,
            email: _emailController.text.trim(),
            displayName: _nameController.text.trim(),
            username: autoUsername,
          );
          await _userService.createUser(newUser);

          // Save FCM token after signup
          if (mounted) NotificationService.saveTokenForCurrentUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t(AuthService.getErrorKey(e))),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer2<ThemeProvider, LocaleProvider>(
            builder: (context, theme, locale, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToggleChip(
                  icon: Icons.dark_mode_outlined,
                  selectedIcon: Icons.dark_mode,
                  selected: theme.isDarkMode,
                  onTap: () => theme.toggleTheme(),
                ),
                const SizedBox(width: 8),
                ToggleChip(
                  icon: Icons.translate_outlined,
                  selectedIcon: Icons.translate,
                  selected: locale.currentLanguageCode == 'ar',
                  onTap: () {
                    final isAr = locale.currentLanguageCode == 'ar';
                    locale.setLocale(Locale(isAr ? 'en' : 'ar'));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.xl),
          child: Column(
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.forum,
                  size: 36,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppConstants.md),
              Text(
                context.t('joinFlow'),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppConstants.xs),
              Text(
                context.t('createAccount'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.xl),
              // Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('fullName'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppConstants.xs),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Alex Rivers',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.md),
              // Email field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('email'), style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppConstants.xs),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'alex.rivers@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.md),
              // Password field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('password'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppConstants.xs),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.lg),
              // Action Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signup,
                      child: Text(context.t('signUp')),
                    ),
              const SizedBox(height: AppConstants.xl),
              // Footer link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.t('alreadyHaveAccount'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.t('login')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
