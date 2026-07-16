import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(username, name: username);

    if (mounted) {
      setState(() { _isLoading = false; });
      if (!success) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Title
              Text('Smart', style: AppTheme.display.copyWith(color: AppColors.textPrimary)),
              Text('Wardrobe', style: AppTheme.display.copyWith(color: AppColors.gold)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your personal wardrobe intelligence.',
                style: AppTheme.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'All data stored locally on your device.',
                style: AppTheme.caption.copyWith(color: AppColors.textTertiary),
              ),
              const Spacer(),

              // Username
              Text('YOUR NAME', style: AppTheme.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _usernameController,
                style: AppTheme.body,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textTertiary, size: 20),
                ),
                onSubmitted: (_) => _login(),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTheme.caption.copyWith(color: AppColors.red)),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _login,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldHi],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1208)),
                              )
                            : Text('Enter Wardrobe', style: AppTheme.button),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
