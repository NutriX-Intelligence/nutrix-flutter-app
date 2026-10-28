import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/profile_form_fields.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late String _gender;
  late String _activityLevel;
  late String _goal;
  late String _dietType;
  late String _likes;
  late String _allergies;
  late String _dislikes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;

    _ageController = TextEditingController(text: user?.age.toString() ?? '25');
    _heightController = TextEditingController(text: user?.height.toString() ?? '170');
    _weightController = TextEditingController(text: user?.weight.toString() ?? '70');

    _likes = user?.likes ?? '';
    _allergies = user?.allergies ?? '';
    _dislikes = user?.dislikes ?? '';

    _gender = user?.gender ?? 'male';
    _activityLevel = user?.activityLevel ?? 'moderately_active';
    _goal = user?.goal ?? 'maintenance';
    _dietType = user?.dietType ?? 'Any';

    // Validate dietType
    const validDietTypes = ['Any', 'Non-Vegetarian', 'Eggetarian', 'Vegetarian', 'Jain', 'Vegan'];
    if (!validDietTypes.contains(_dietType)) {
      _dietType = 'Any';
    }
  }

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
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: const Text('Profile updated successfully!'),
               backgroundColor: AppColors.primary,
               behavior: SnackBarBehavior.floating,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
           );
           context.pop();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }
}
