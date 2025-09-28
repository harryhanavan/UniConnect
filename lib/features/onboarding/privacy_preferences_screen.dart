import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_tour_screen.dart';

class PrivacyPreferencesScreen extends StatefulWidget {
  const PrivacyPreferencesScreen({super.key});

  @override
  State<PrivacyPreferencesScreen> createState() => _PrivacyPreferencesScreenState();
}

class _PrivacyPreferencesScreenState extends State<PrivacyPreferencesScreen> {
  // Privacy settings
  String _profileVisibility = 'University';
  String _locationSharing = 'Friends';
  String _eventVisibility = 'Friends';
  String _studyGroupVisibility = 'University';
  bool _allowDirectMessages = true;
  bool _allowFriendRequests = true;
  bool _showOnlineStatus = true;
  bool _allowDataAnalytics = true;

  final List<String> _visibilityOptions = ['Public', 'University', 'Friends', 'Private'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Privacy preferences',
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
                'Your privacy matters',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose who can see your information and how you want to interact',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Privacy sections
              _buildVisibilitySection(),

              const SizedBox(height: 32),

              _buildInteractionSection(),

              const SizedBox(height: 32),

              _buildDataSection(),

              const SizedBox(height: 40),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
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

              const SizedBox(height: 24),

              // Info note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can change these settings anytime in your profile',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
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
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visibility Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildDropdownSetting(
          title: 'Profile Visibility',
          subtitle: 'Who can see your profile information',
          value: _profileVisibility,
          options: _visibilityOptions,
          onChanged: (value) => setState(() => _profileVisibility = value!),
          icon: Icons.person,
        ),

        const SizedBox(height: 16),

        _buildDropdownSetting(
          title: 'Location Sharing',
          subtitle: 'Who can see when you\'re on campus',
          value: _locationSharing,
          options: _visibilityOptions,
          onChanged: (value) => setState(() => _locationSharing = value!),
          icon: Icons.location_on,
        ),

        const SizedBox(height: 16),

        _buildDropdownSetting(
          title: 'Event Participation',
          subtitle: 'Who can see events you\'re attending',
          value: _eventVisibility,
          options: _visibilityOptions,
          onChanged: (value) => setState(() => _eventVisibility = value!),
          icon: Icons.event,
        ),

        const SizedBox(height: 16),

        _buildDropdownSetting(
          title: 'Study Groups',
          subtitle: 'Who can see your study group memberships',
          value: _studyGroupVisibility,
          options: _visibilityOptions,
          onChanged: (value) => setState(() => _studyGroupVisibility = value!),
          icon: Icons.group,
        ),
      ],
    );
  }

  Widget _buildInteractionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interaction Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildSwitchSetting(
          title: 'Allow Direct Messages',
          subtitle: 'Let other students send you messages',
          value: _allowDirectMessages,
          onChanged: (value) => setState(() => _allowDirectMessages = value),
          icon: Icons.message,
        ),

        _buildSwitchSetting(
          title: 'Allow Friend Requests',
          subtitle: 'Let other students send you friend requests',
          value: _allowFriendRequests,
          onChanged: (value) => setState(() => _allowFriendRequests = value),
          icon: Icons.person_add,
        ),

        _buildSwitchSetting(
          title: 'Show Online Status',
          subtitle: 'Let friends see when you\'re active',
          value: _showOnlineStatus,
          onChanged: (value) => setState(() => _showOnlineStatus = value),
          icon: Icons.circle,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data & Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildSwitchSetting(
          title: 'Analytics & Improvements',
          subtitle: 'Help improve UniConnect with anonymous usage data',
          value: _allowDataAnalytics,
          onChanged: (value) => setState(() => _allowDataAnalytics = value),
          icon: Icons.analytics,
        ),

        const SizedBox(height: 12),

        Text(
          'This helps us understand how students use the app and improve features. No personal information is shared.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    // In a real app, save privacy preferences
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppTourScreen(),
      ),
    );
  }
}