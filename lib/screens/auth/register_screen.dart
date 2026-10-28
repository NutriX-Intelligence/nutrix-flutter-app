import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/profile_form_fields.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderately_active';
  String _goal = 'maintenance';
  String _dietType = 'Any';
  String _likes = '';
  String _allergies = '';
  String _dislikes = '';
  bool _obscurePassword = true;
  bool _isCheckingEmail = false;
  int _step = 0; // 0 = account info, 1 = body metrics

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      final prefs = <Map<String, String>>[];
      if (_dietType != 'Any') prefs.add({'preference_type': 'diet_type', 'value': _dietType});
      if (_likes.trim().isNotEmpty) prefs.add({'preference_type': 'like', 'value': _likes.trim()});
      if (_allergies.trim().isNotEmpty) prefs.add({'preference_type': 'allergy', 'value': _allergies.trim()});
      if (_dislikes.trim().isNotEmpty) prefs.add({'preference_type': 'dislike', 'value': _dislikes.trim()});

      ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            age: int.tryParse(_ageController.text) ?? 25,
            gender: _gender,
            height: double.tryParse(_heightController.text) ?? 170,
            weight: double.tryParse(_weightController.text) ?? 70,
            activityLevel: _activityLevel,
            goal: _goal,
            preferences: prefs.isEmpty ? null : prefs,
          );
    }
  }

  Future<void> _handleContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isCheckingEmail = true);
    try {
      final email = _emailController.text.trim();
      final exists = await ref.read(authProvider.notifier).checkEmailExists(email);
      if (!mounted) return;

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An account with this email already exists.')),
        );
        return;
      }
      setState(() => _step = 1);
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => _step == 0 ? context.go('/login') : setState(() => _step = 0),
        ),
        title: Text(_step == 0 ? 'Create Account' : 'Your Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Step indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _step >= 1
                              ? AppColors.primary
                              : context.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (_step == 0) ...[
                  _buildStep0(),
                ] else ...[
                  _buildStep1(authState),
                ],

                const SizedBox(height: 24),
                if (_step == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isCheckingEmail ? null : _handleContinue,
            child: _isCheckingEmail
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Continue'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStep1(AuthState authState) {
    return Column(
      children: [
        ProfileFormFields(
          ageController: _ageController,
          heightController: _heightController,
          weightController: _weightController,
          gender: _gender,
          onGenderChanged: (v) => setState(() => _gender = v ?? 'male'),
          activityLevel: _activityLevel,
          onActivityLevelChanged: (v) => setState(() => _activityLevel = v ?? 'moderately_active'),
          goal: _goal,
          onGoalChanged: (v) => setState(() => _goal = v ?? 'maintenance'),
          dietType: _dietType,
          onDietTypeChanged: (v) => setState(() => _dietType = v ?? 'Any'),
          likes: _likes,
          onLikesChanged: (v) => _likes = v,
          allergies: _allergies,
          onAllergiesChanged: (v) => _allergies = v,
          dislikes: _dislikes,
          onDislikesChanged: (v) => _dislikes = v,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _handleRegister,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Create Account'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}
