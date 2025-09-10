import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class ColorPaletteSection extends StatelessWidget {
  const ColorPaletteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('UniConnect Color System'),
          _buildDescription(
            'Our 5-color system ensures visual consistency and helps users understand different feature categories.',
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('Primary Brand Colors'),
          _buildColorGrid([
            _ColorItem('Home/Main', AppColors.homeColor, '#8B5CF6', 'Primary actions, home screen'),
            _ColorItem('Personal', AppColors.personalColor, '#0D99FF', 'Calendar, timetables, personal events'),
            _ColorItem('Society', AppColors.societyColor, '#4CAF50', 'Clubs, organizations, society events'),
            _ColorItem('Social', AppColors.socialColor, '#31E615', 'Friends, messaging, social features'),
            _ColorItem('Study Groups', AppColors.studyGroupColor, '#FF7A00', 'Collaboration, study groups'),
          ]),
          
          const SizedBox(height: 30),
          _buildSectionTitle('UI Colors'),
          _buildColorGrid([
            _ColorItem('Background', AppColors.background, '#F8F9FA', 'Main app background'),
            _ColorItem('Surface', AppColors.surface, '#FFFFFF', 'Card and surface backgrounds'),
            _ColorItem('Error', AppColors.error, '#EF4444', 'Error states and danger actions'),
            _ColorItem('Success', AppColors.success, '#10B981', 'Success states and confirmations'),
            _ColorItem('Warning', AppColors.warning, '#FFC107', 'Warning states and alerts'),
          ]),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Text Colors'),
          _buildColorGrid([
            _ColorItem('Primary Text', AppColors.textPrimary, '#212529', 'Main content text'),
            _ColorItem('Secondary Text', AppColors.textSecondary, '#6C757D', 'Supporting text'),
            _ColorItem('Light Text', AppColors.textLight, '#ADB5BD', 'Disabled or subtle text'),
          ]),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Usage Guidelines'),
          _buildUsageExample(),
          
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

  Widget _buildColorGrid(List<_ColorItem> colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: colors.map((color) => _buildColorCard(color)).toList(),
      ),
    );
  }

  Widget _buildColorCard(_ColorItem colorItem) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color swatch
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: colorItem.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          
          // Color info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  colorItem.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _copyToClipboard(colorItem.hex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      colorItem.hex,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  colorItem.usage,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color Usage Examples',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Social feature example
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.socialColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Social Features', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Use bright green (#31E615) for friends, messaging, social interactions', 
                         style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Personal feature example
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.personalColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Features', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Use blue (#0D99FF) for calendar, personal events, timetables', 
                         style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
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
            'Code Example',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '''// Import the color constants
import 'package:app/core/constants/app_colors.dart';

// Use in your widgets
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.socialColor, 
        AppColors.socialColor.withValues(alpha: 0.8)
      ],
    ),
  ),
  child: Text(
    'Social Feature Header',
    style: TextStyle(color: Colors.white),
  ),
)

// For event type colors
Color eventColor = AppColors.getEventTypeColor('social');''',
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

class _ColorItem {
  final String name;
  final Color color;
  final String hex;
  final String usage;

  _ColorItem(this.name, this.color, this.hex, this.usage);
}