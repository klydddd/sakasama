import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Login screen with email and password fields.
///
/// Green gradient header, large inputs, and Filipino text.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      // Check if the auth error wraps a network issue
      final msg = e.message.toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('host lookup') ||
          msg.contains('clientexception') ||
          msg.contains('connection')) {
        setState(
          () => _errorMessage =
              'Walang internet connection. Suriin ang iyong WiFi o data at subukan muli.',
        );
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('host lookup') ||
          msg.contains('clientexception') ||
          msg.contains('connection')) {
        setState(
          () => _errorMessage =
              'Walang internet connection. Suriin ang iyong WiFi o data at subukan muli.',
        );
      } else {
        setState(
          () => _errorMessage = 'May problema sa pag-login. Subukan ulit.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.darkGreen, AppColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/logos/logo (1).png',
                            width: 56,
                            height: 56,
                            color: Colors.white,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ],
                ),
              ),

              // ── Form ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.sectionSpacing),

                      Text(
                        AppStrings.loginTitle,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.sectionSpacing),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(
                            bottom: AppDimensions.itemSpacing,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.inputRadius,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(duration: 400.ms),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: AppStrings.email,
                          hintText: 'pangalan@email.com',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ilagay ang iyong email';
                          }
                          if (!value.contains('@')) {
                            return 'Hindi wastong email format';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.itemSpacing),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: AppStrings.password,
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ilagay ang iyong password';
                          }
                          if (value.length < 6) {
                            return 'Ang password ay dapat 6+ character';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.sectionSpacing),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.primaryButtonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(AppStrings.signIn),
                        ),
                      ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.itemSpacing),

                      // Register link
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/register'),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textGrey),
                              children: [
                                TextSpan(text: AppStrings.noAccount),
                                TextSpan(
                                  text: ' ${AppStrings.createAccount}',
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
