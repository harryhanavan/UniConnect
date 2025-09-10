import 'package:flutter/material.dart';
import '../../../shared/models/society.dart';
import '../../../core/constants/app_colors.dart';

class SocietyCard extends StatelessWidget {
  final Society society;
  final VoidCallback onJoinPressed;

  const SocietyCard({
    super.key,
    required this.society,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Logo
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.societyColor.withValues(alpha: 0.1),
                    child: Text(
                      society.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.societyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          society.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            society.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getCategoryColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Join button
                  ElevatedButton(
                    onPressed: onJoinPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: society.isJoined 
                          ? AppColors.textLight 
                          : AppColors.societyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(society.isJoined ? 'Leave' : 'Join'),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                society.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tags and member count
              Row(
                children: [
                  // Tags
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: society.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Member count
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${society.memberCount} members',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (society.category.toLowerCase()) {
      case 'technology':
        return AppColors.personalColor;  // Technology societies use personal/blue
      case 'creative':
        return AppColors.societyColor;
      case 'sports':
        return AppColors.studyGroupColor;  // Sports societies use orange
      case 'cultural':
        return AppColors.personalColor;
      case 'business':
        return AppColors.warning;
      default:
        return AppColors.societyColor;  // Default societies use green
    }
  }
}