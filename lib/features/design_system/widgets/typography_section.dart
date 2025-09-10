import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Typography System'),
          _buildDescription(
            'Consistent typography creates hierarchy and improves readability across the app.',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Headers & Titles'),
          const SizedBox(height: 16),
          _buildTypographyExample(
            'App Header',
            'UniMates',
            const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            Colors.transparent,
            'fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white',
            'Used in gradient headers across features',
          ),
          
          _buildTypographyExample(
            'Section Title',
            'Upcoming Events',
            const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            Colors.white,
            'fontSize: 20, fontWeight: FontWeight.bold',
            'Main section headings within screens',
          ),
          
          _buildTypographyExample(
            'Card Title',
            'Computer Science Lecture',
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            Colors.white,
            'fontSize: 16, fontWeight: FontWeight.w600',
            'Card titles and event names',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Body Text'),
          const SizedBox(height: 16),
          _buildTypographyExample(
            'Body Regular',
            'This is the standard body text used throughout the app for most content.',
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.textPrimary,
            ),
            Colors.white,
            'fontSize: 14, fontWeight: FontWeight.normal',
            'Default body text for content',
          ),
          
          _buildTypographyExample(
            'Body Medium',
            'Important information that needs slightly more emphasis than regular text.',
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            Colors.white,
            'fontSize: 14, fontWeight: FontWeight.w500',
            'Emphasized body text',
          ),
          
          _buildTypographyExample(
            'Body Small',
            'Secondary information and supporting details.',
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
            Colors.white,
            'fontSize: 12, color: AppColors.textSecondary',
            'Timestamps, metadata, subtitles',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Interactive Text'),
          const SizedBox(height: 16),
          _buildTypographyExample(
            'Button Text',
            'Join Society',
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            AppColors.societyColor,
            'fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white',
            'Text on buttons and CTAs',
          ),
          
          _buildTypographyExample(
            'Link Text',
            'View full schedule',
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.personalColor,
              decoration: TextDecoration.underline,
            ),
            Colors.white,
            'fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.personalColor',
            'Clickable links and navigation',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Specialized Text'),
          const SizedBox(height: 16),
          _buildTypographyExample(
            'Monospace Code',
            '#31E615',
            const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
            ),
            Colors.grey.shade100,
            'fontSize: 12, fontFamily: \'monospace\'',
            'Hex codes, technical identifiers',
          ),
          
          _buildTypographyExample(
            'Status Badge',
            'Online',
            const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
            Colors.green.withValues(alpha: 0.1),
            'fontSize: 10, fontWeight: FontWeight.w600',
            'Status indicators and badges',
          ),
          
          const SizedBox(height: 30),
          _buildUsageGuidelines(),
          
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

  Widget _buildTypographyExample(
    String label,
    String example,
    TextStyle style,
    Color backgroundColor,
    String styleCode,
    String usage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.personalColor,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Example text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: backgroundColor == Colors.transparent 
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
            child: Text(example, style: style),
          ),
          
          const SizedBox(height: 12),
          
          // Style code
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'TextStyle($styleCode)',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Usage description
          Text(
            usage,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Typography Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text('• Use consistent font weights: regular (400), medium (500), semi-bold (600), bold (700)'),
          const SizedBox(height: 6),
          const Text('• Maintain proper hierarchy with font sizes (28 → 20 → 16 → 14 → 12 → 10)'),
          const SizedBox(height: 6),
          const Text('• Use AppColors for text colors to maintain theme consistency'),
          const SizedBox(height: 6),
          const Text('• Reserve monospace fonts for technical content only'),
          const SizedBox(height: 6),
          const Text('• Ensure sufficient contrast ratios for accessibility'),
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
            'Typography Code Examples',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '''// Header styling
Text(
  'UniMates',
  style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)

// Card title
Text(
  event.title,
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
)

// Body text with color
Text(
  'Supporting information',
  style: TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  ),
)

// Button text
Text(
  'Join Society',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  ),
)''',
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