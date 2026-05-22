import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final bool success;
    if (_isRegisterMode) {
      success = await notifier.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      success = await notifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    if (success && mounted) context.go('/home');
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      context.showSnackBar('Enter your email first', isError: true);
      return;
    }
    final success = await ref.read(authNotifierProvider.notifier).resetPassword(email);
    if (success && mounted) context.showSnackBar('Password reset email sent!');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.error != null) {
        context.showSnackBar(next.error!, isError: true);
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 38),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                Text(
                  _isRegisterMode ? 'Create Account' : 'Sign In',
                  style: AppTypography.displaySmall(),
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 6),

                Text(
                  'Practice speaking. Build confidence.',
                  style: AppTypography.bodyMedium(color: context.textSecondary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 120.ms),

                const SizedBox(height: 32),

                // Google button
                _GoogleButton(
                  isLoading: authState.isLoading,
                  onTap: () async {
                    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
                    if (success && context.mounted) context.go('/home');
                  },
                ).animate().fadeIn(delay: 160.ms),

                // Apple — iOS release only
                if (Platform.isIOS && kReleaseMode) ...[
                  const SizedBox(height: 12),
                  _AppleButton(
                    isLoading: authState.isLoading,
                    onTap: () async {
                      final success = await ref.read(authNotifierProvider.notifier).signInWithApple();
                      if (success && context.mounted) context.go('/home');
                    },
                  ).animate().fadeIn(delay: 200.ms),
                ],

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppTypography.labelMedium(color: context.textSecondary)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Name (register only)
                if (_isRegisterMode) ...[
                  _Field(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Email
                _Field(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Password
                _Field(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (_isRegisterMode && v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                // Forgot password
                if (!_isRegisterMode) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Tappable(
                      onTap: _forgotPassword,
                      child: Text('Forgot Password?', style: AppTypography.labelMedium(color: AppColors.primary)),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegisterMode ? 'Create Account' : 'Sign In',
                            style: AppTypography.titleMedium(color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle login / register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegisterMode ? 'Already have an account? ' : "Don't have an account? ",
                      style: AppTypography.bodyMedium(color: context.textSecondary),
                    ),
                    Tappable(
                      onTap: () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _nameController.clear();
                      }),
                      child: Text(
                        _isRegisterMode ? 'Sign In' : 'Sign Up',
                        style: AppTypography.bodyMedium(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'By continuing, you agree to our Terms & Privacy Policy.',
                  style: AppTypography.labelSmall(color: context.textTertiary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Button ────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/google_logo.svg', width: 22, height: 22),
            const SizedBox(width: 12),
            Text('Continue with Google', style: AppTypography.titleMedium()),
          ],
        ),
      ),
    );
  }
}

// ─── Apple Button ─────────────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AppleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple_rounded, size: 24),
            const SizedBox(width: 12),
            Text('Continue with Apple', style: AppTypography.titleMedium()),
          ],
        ),
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
