import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_state.dart';
import '../../shared/models/user.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Profile'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'switch_andrea') {
                    appState.switchUser('user_001');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Andrea (Demo User)'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } else if (value == 'reset_onboarding') {
                    appState.resetOnboardingForDev();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Onboarding reset - app will restart'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'switch_andrea',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Switch to Andrea (Demo)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset_onboarding',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Reset Onboarding'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current User Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.socialColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            appState.isNewUser ? Icons.person_add : Icons.person,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            appState.isNewUser ? 'New User Profile' : 'Demo User Profile',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appState.isNewUser
                            ? 'You completed the onboarding and created a new profile.'
                            : 'You are using the demo profile (Andrea Fernandez).',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Details
                if (appState.isNewUser && appState.newUserData != null)
                  _buildNewUserProfile(appState.newUserData!)
                else
                  _buildDemoUserProfile(appState.currentUser),

                const SizedBox(height: 32),

                // Development Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Development Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Active User ID', appState.activeUserId ?? 'None'),
                      _buildInfoRow('Is New User', appState.isNewUser.toString()),
                      _buildInfoRow('Has Completed Onboarding', appState.hasCompletedOnboarding.toString()),
                      _buildInfoRow('Is Authenticated', appState.isAuthenticated.toString()),
                      const SizedBox(height: 12),
                      Text(
                        'Note: In a production app, new user data would be saved to a database and persist across sessions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewUserProfile(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New User Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Avatar
        if (userData['avatar'] != null)
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(userData['avatar']),
            ),
          ),

        const SizedBox(height: 20),

        // Basic Info
        _buildProfileSection('Account Information', [
          _buildProfileRow('Name', userData['name'] ?? 'Not provided'),
          _buildProfileRow('Email', userData['email'] ?? 'Not provided'),
          _buildProfileRow('University', userData['university'] ?? 'Not provided'),
          _buildProfileRow('Course', userData['course'] ?? 'Not provided'),
          _buildProfileRow('Year', userData['year'] ?? 'Not provided'),
        ]),

        const SizedBox(height: 24),

        // Profile Info
        _buildProfileSection('Profile Information', [
          _buildProfileRow('Bio', userData['bio']?.isNotEmpty == true ? userData['bio'] : 'Not provided'),
          _buildProfileRow('Pronouns', userData['pronouns']?.isNotEmpty == true ? userData['pronouns'] : 'Not provided'),
          _buildProfileRow('Setup Completed', userData['profileSetupCompleted']?.toString() ?? 'false'),
        ]),

        if (userData['interests'] != null && (userData['interests'] as List).isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildInterestsSection(List<String>.from(userData['interests'])),
        ],
      ],
    );
  }

  Widget _buildDemoUserProfile(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo User Profile (Andrea)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Avatar
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
        ),

        const SizedBox(height: 20),

        // Basic Info
        _buildProfileSection('Account Information', [
          _buildProfileRow('Name', user.name),
          _buildProfileRow('Email', user.email),
          _buildProfileRow('Course', user.course),
          _buildProfileRow('Year', user.year),
          _buildProfileRow('Status', user.status.name),
        ]),

        const SizedBox(height: 24),

        // Demo Data Stats
        _buildProfileSection('Demo Data Statistics', [
          _buildProfileRow('Friends', user.friendIds.length.toString()),
          _buildProfileRow('Societies', user.societyIds.length.toString()),
          _buildProfileRow('Current Location', user.currentBuilding ?? 'Unknown'),
          _buildProfileRow('Status Message', user.statusMessage ?? 'No status'),
        ]),
      ],
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}