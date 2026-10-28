import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/profile_form_fields.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isSaving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      try {
        final prefs = <Map<String, String>>[];
        if (_dietType != 'Any') prefs.add({'preference_type': 'diet_type', 'value': _dietType});
        if (_likes.trim().isNotEmpty) prefs.add({'preference_type': 'like', 'value': _likes.trim()});
        if (_allergies.trim().isNotEmpty) prefs.add({'preference_type': 'allergy', 'value': _allergies.trim()});
        if (_dislikes.trim().isNotEmpty) prefs.add({'preference_type': 'dislike', 'value': _dislikes.trim()});

        await ref.read(authProvider.notifier).updateProfile(
              age: int.tryParse(_ageController.text) ?? 25,
              gender: _gender,
              height: double.tryParse(_heightController.text) ?? 170,
              weight: double.tryParse(_weightController.text) ?? 70,
              activityLevel: _activityLevel,
              goal: _goal,
              preferences: prefs.isEmpty ? null : prefs,
            );
        if (mounted) {
           context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
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
                Text(
                  'Since you signed in with Google, we need a few more details to accurately calculate your personalized nutrition targets.',
                  style: TextStyle(fontSize: 14, color: context.textMuted),
                ),
                const SizedBox(height: 24),
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
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Profile'),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
          ),
        ),
      ),
    );
  }
}
