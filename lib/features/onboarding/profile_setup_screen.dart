import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_state.dart';
import 'privacy_preferences_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _bioController = TextEditingController();
  final _pronounsController = TextEditingController();
  String? _selectedAvatar;
  final List<String> _selectedInterests = [];

  // Predefined avatar options using DiceBear API
  final List<String> _avatarOptions = [
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student1&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student2&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student3&backgroundColor=d1d4f9',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student4&backgroundColor=ffd93d',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student5&backgroundColor=6bcf7f',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student6&backgroundColor=ffb5b5',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student7&backgroundColor=a8e6cf',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=student8&backgroundColor=ffc3a0',
  ];

  // Interest categories for university students
  final List<String> _interestOptions = [
    'Computer Science',
    'Engineering',
    'Design',
    'Business',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Psychology',
    'Literature',
    'History',
    'Philosophy',
    'Art',
    'Music',
    'Sports',
    'Gaming',
    'Photography',
    'Cooking',
    'Travel',
    'Fitness',
    'Yoga',
    'Meditation',
    'Volunteering',
    'Environment',
    'Technology',
    'AI/Machine Learning',
    'Startups',
    'Politics',
    'Economics',
    'Languages',
    'Drama/Theatre',
    'Dance',
    'Film',
    'Podcasts',
    'Reading',
    'Writing',
    'Research',
  ];

  @override
  void initState() {
    super.initState();
    // Set default avatar
    _selectedAvatar = _avatarOptions[0];
  }

  @override
  void dispose() {
    _bioController.dispose();
    _pronounsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Set up your profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(),

              const SizedBox(height: 32),

              // Header
              const Text(
                'Let\'s personalize your profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps other students get to know you better',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Avatar selection
              _buildAvatarSelection(),

              const SizedBox(height: 32),

              // Bio field
              _buildBioField(),

              const SizedBox(height: 24),

              // Pronouns field
              _buildPronounsField(),

              const SizedBox(height: 32),

              // Interests selection
              _buildInterestsSelection(),

              const SizedBox(height: 40),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue() ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _canContinue() ? 2 : 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              Center(
                child: TextButton(
                  onPressed: _handleSkip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: AppColors.primary,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[300],
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your avatar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = _selectedAvatar == avatar;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(avatar),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Write a short bio to help others connect with you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'e.g., I\'m studying IT and love coding. Always up for coffee and discussing the latest tech trends!',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            counterText: '${_bioController.text.length}/200',
          ),
          onChanged: (value) {
            setState(() {}); // Update character count
          },
        ),
      ],
    );
  }

  Widget _buildPronounsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pronouns (optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pronounsController,
          decoration: InputDecoration(
            hintText: 'e.g., they/them, she/her, he/him',
            prefixIcon: const Icon(Icons.person, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you interested in?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select at least 3 interests to help us connect you with like-minded people',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedInterests.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_selectedInterests.length} interests selected',
            style: TextStyle(
              fontSize: 14,
              color: _selectedInterests.length >= 3 ? AppColors.online : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  bool _canContinue() {
    return _selectedAvatar != null && _selectedInterests.length >= 3;
  }

  void _handleContinue() {
    if (_canContinue()) {
      // Update the user data with profile information
      final appState = Provider.of<AppState>(context, listen: false);
      final existingData = appState.newUserData ?? {};

      final updatedData = {
        ...existingData,
        'avatar': _selectedAvatar,
        'bio': _bioController.text,
        'pronouns': _pronounsController.text,
        'interests': _selectedInterests,
        'profileSetupCompleted': true,
      };

      appState.createNewUserFromOnboarding(updatedData);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PrivacyPreferencesScreen(),
        ),
      );
    }
  }

  void _handleSkip() {
    // Even if skipped, update with minimal profile data
    final appState = Provider.of<AppState>(context, listen: false);
    final existingData = appState.newUserData ?? {};

    final updatedData = {
      ...existingData,
      'avatar': _selectedAvatar,
      'bio': '',
      'pronouns': '',
      'interests': <String>[],
      'profileSetupCompleted': false,
    };

    appState.createNewUserFromOnboarding(updatedData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPreferencesScreen(),
      ),
    );
  }
}