import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HeaderPatternsSection extends StatelessWidget {
  const HeaderPatternsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Header Patterns'),
          _buildDescription(
            'Consistent header styling creates brand recognition and helps users understand which feature they\'re using.',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Gradient Headers by Feature'),
          const SizedBox(height: 16),
          
          _buildHeaderExample(
            'Social Features Header',
            'UniMates',
            'Stay connected with friends',
            AppColors.socialColor,
            Icons.map,
            Icons.qr_code_scanner,
          ),
          
          _buildHeaderExample(
            'Personal Features Header',
            'My Calendar',
            'Plan your academic schedule',
            AppColors.personalColor,
            Icons.today,
            Icons.add,
          ),
          
          _buildHeaderExample(
            'Society Features Header',
            'Societies',
            'Connect with communities',
            AppColors.societyColor,
            Icons.search,
            Icons.favorite,
          ),
          
          _buildHeaderExample(
            'Study Groups Header',
            'Study Groups',
            'Collaborate with classmates',
            AppColors.studyGroupColor,
            Icons.group_add,
            Icons.book,
          ),
          
          _buildHeaderExample(
            'Home Features Header',
            'UniConnect',
            'Your university hub',
            AppColors.homeColor,
            Icons.notifications,
            Icons.account_circle,
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Header with Navigation'),
          const SizedBox(height: 16),
          _buildNavigationHeader(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Header with Tabs'),
          const SizedBox(height: 16),
          _buildTabHeader(),
          
          const SizedBox(height: 30),
          _buildHeaderGuidelines(),
          
          const SizedBox(height: 30),
          _buildCodeExample(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHeaderExample(
    String title,
    String headerText,
    String subtitle,
    Color color,
    IconData leftIcon,
    IconData rightIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(leftIcon, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(rightIcon, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildPatternLabel(title, _getColorName(color)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNavigationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.socialColor, AppColors.socialColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {},
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with Alex',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Online • Last seen now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ),
        _buildPatternLabel('Navigation Header', 'Back button + title + actions'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTabHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.personalColor, AppColors.personalColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Calendar',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Week of March 15, 2024',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.today, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              // Tab bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTab('Day', true),
                    const SizedBox(width: 20),
                    _buildTab('3 Days', false),
                    const SizedBox(width: 20),
                    _buildTab('Week', false),
                    const SizedBox(width: 20),
                    _buildTab('Month', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        _buildPatternLabel('Header with Tabs', 'Title + subtitle + tab navigation'),
      ],
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPatternLabel(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.personalColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == AppColors.socialColor) return 'Social Green (#31E615)';
    if (color == AppColors.personalColor) return 'Personal Blue (#0D99FF)';
    if (color == AppColors.societyColor) return 'Society Green (#4CAF50)';
    if (color == AppColors.studyGroupColor) return 'Study Orange (#FF7A00)';
    if (color == AppColors.homeColor) return 'Home Purple (#8B5CF6)';
    return 'Unknown Color';
  }

  Widget _buildHeaderGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Header Design Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text('• Use gradient backgrounds with feature colors from AppColors'),
          const SizedBox(height: 6),
          const Text('• Main title: 28px bold white text'),
          const SizedBox(height: 6),
          const Text('• Subtitle: 16px regular white70 text'),
          const SizedBox(height: 6),
          const Text('• Always include SafeArea for proper spacing'),
          const SizedBox(height: 6),
          const Text('• Use white icons with sufficient contrast'),
          const SizedBox(height: 6),
          const Text('• Maintain consistent padding (20px) around content'),
          const SizedBox(height: 6),
          const Text('• Include back button for navigation screens'),
        ],
      ),
    );
  }

  Widget _buildCodeExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Header Pattern Code Template',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '''Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.featureColor, 
          AppColors.featureColor.withValues(alpha: 0.8)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Title',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Feature subtitle',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.action, color: Colors.white),
                    onPressed: () => _handleAction(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}''',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}