import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'session_gate.dart';
import '../services/smart_time_log_api.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your username and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SmartTimeLogApi.instance.login(
        username: username,
        password: password,
      );
      if (mounted) {
        await SessionGate.routeAuthenticatedSession(context);
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.schedule,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      'SmartTimeLog',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Track your work hours effortlessly',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48.0),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Username',
                        style: ShadTheme.of(
                          context,
                        ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ShadInput(
                      controller: _usernameController,
                      placeholder: const Text('Enter your username'),
                      leading: const Icon(Icons.person_outline, size: 18),
                    ),
                    const SizedBox(height: 16.0),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: ShadTheme.of(
                          context,
                        ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ShadInput(
                      controller: _passwordController,
                      placeholder: const Text('Enter your password'),
                      obscureText: _obscurePassword,
                      leading: const Icon(Icons.lock_outline, size: 18),
                      trailing: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    const SizedBox(height: 24.0),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ShadButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ),
          // Theme Toggle Button
          Positioned(
            top: 16,
            right: 16,
            child: ThemeToggleButton(
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
