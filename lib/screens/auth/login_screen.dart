import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../utils/translations.dart';
import '../../theme/theme_provider.dart';
import '../../theme/locale_provider.dart';
import '../../widgets/toggle_chip.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('fillAllFields')),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Save FCM token after successful login
      if (mounted) NotificationService.saveTokenForCurrentUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t(AuthService.getErrorKey(e))),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user != null && mounted) {
        setState(() => _isLoading = true);
        final user = credential!.user!;
        // Check if user doc exists; if not, create one
        final existing = await _userService.getUser(user.uid);
        if (existing == null) {
          final rawName = (user.displayName ?? user.email!.split('@')[0])
              .replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final randomNum = DateTime.now().millisecondsSinceEpoch % 10000;
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            username: '$rawName$randomNum',
            photoUrl: user.photoURL,
          );
          await _userService.createUser(newUser);
        }
        // Save FCM token after Google Sign-In
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

  void _showForgotPasswordDialog() {
    final emailController =
        TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(context.t('resetPassword')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('resetPasswordDesc')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'alex.rivers@example.com',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.t('cancel')),
                ),
                isResetting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : FilledButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(context.t('enterEmail'))),
                            );
                            return;
                          }
                          setDialogState(() => isResetting = true);
                          try {
                            await _authService.sendPasswordResetEmail(email);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        context.t('resetLinkSent', args: [email]))),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isResetting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                         Text(context.t(AuthService.getErrorKey(e)))),
                              );
                            }
                          }
                        },
                        child: Text(context.t('sendResetLink')),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A1628), const Color(0xFF000000)]
                : [const Color(0xFFF0F4FF), colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                    child: Column(
                      children: [
                        // Theme & Language controls
                        Consumer2<ThemeProvider, LocaleProvider>(
                          builder: (context, theme, locale, _) => Row(
                            mainAxisAlignment: MainAxisAlignment.end,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withAlpha(180),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(60),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.forum_rounded,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.t('appName'),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('welcomeBack'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        hint: context.t('emailAddress'),
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        hint: context.t('password'),
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                          ),
                          child: Text(
                            context.t('forgotPassword'),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: colorScheme.primary, strokeWidth: 2.5))
                            : FilledButton(
                                onPressed: _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: Text(context.t('signIn')),
                              ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: colorScheme.outlineVariant
                                      .withAlpha(100))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              context.t('or'),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: colorScheme.outlineVariant
                                      .withAlpha(100))),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Google Login
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 20,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 22),
                          ),
                          label: Text(context.t('continueWithGoogle')),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color:
                                  colorScheme.outlineVariant.withAlpha(120),
                            ),
                            foregroundColor: colorScheme.onSurface,
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.t('noAccount'),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              context.t('signUp'),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(60),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 15 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withAlpha(150),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
