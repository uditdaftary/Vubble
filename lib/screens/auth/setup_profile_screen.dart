import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillController = TextEditingController();

  final List<String> _skills = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firebaseUser = authService.currentUser;
      if (firebaseUser == null) return;

      final user = UserModel(
        userId: firebaseUser.uid,
        name: _nameController.text.trim(),
        email: firebaseUser.email ?? '',
        department: _departmentController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skills,
        verificationStatus: VerificationStatus.verified,
        createdAt: DateTime.now(),
      );

      await authService.createUserProfile(user);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up your profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how other students will see you.',
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 36),

                // Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Department
                TextFormField(
                  controller: _departmentController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your department';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Tell others what you can do...',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 8),

                // Skills
                Text(
                  'Skills',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Python, Graphic Design',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onFieldSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addSkill,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeSkill(skill),
                              backgroundColor: Colors.deepPurple[50],
                              labelStyle:
                                  const TextStyle(color: Colors.deepPurple),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 40),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enter Vubble',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
