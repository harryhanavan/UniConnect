import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class InteractiveElementsSection extends StatefulWidget {
  const InteractiveElementsSection({super.key});

  @override
  State<InteractiveElementsSection> createState() => _InteractiveElementsSectionState();
}

class _InteractiveElementsSectionState extends State<InteractiveElementsSection> {
  bool _toggleValue = false;
  String _selectedChip = 'Technology';
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Interactive Elements'),
          _buildDescription(
            'Consistent interactive components ensure a cohesive user experience and predictable behavior.',
          ),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Buttons'),
          const SizedBox(height: 16),
          _buildButtonExamples(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Input Fields'),
          const SizedBox(height: 16),
          _buildInputExamples(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Tags & Chips'),
          const SizedBox(height: 16),
          _buildChipExamples(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Status Indicators'),
          const SizedBox(height: 16),
          _buildStatusExamples(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Navigation Elements'),
          const SizedBox(height: 16),
          _buildNavigationExamples(),
          
          const SizedBox(height: 30),
          _buildSectionTitle('Loading & Progress'),
          const SizedBox(height: 16),
          _buildLoadingExamples(),
          
          const SizedBox(height: 30),
          _buildInteractionGuidelines(),
          
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

  Widget _buildButtonExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Primary Buttons',
          'Main actions in each feature category',
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.socialColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Message Friend'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.societyColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Join Society'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.personalColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Event'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studyGroupColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Create Group'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        _buildComponentCard(
          'Secondary Buttons',
          'Secondary actions and alternatives',
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.socialColor,
                        side: BorderSide(color: AppColors.socialColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        _buildComponentCard(
          'Floating Action Buttons',
          'Primary actions that float above content',
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppColors.personalColor,
                heroTag: "fab1",
                child: const Icon(Icons.add, color: Colors.white),
              ),
              FloatingActionButton.extended(
                onPressed: () {},
                backgroundColor: AppColors.socialColor,
                foregroundColor: Colors.white,
                heroTag: "fab2",
                icon: const Icon(Icons.message),
                label: const Text('New Chat'),
              ),
              FloatingActionButton.small(
                onPressed: () {},
                backgroundColor: AppColors.societyColor,
                heroTag: "fab3",
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Text Fields',
          'Input fields with consistent styling',
          Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search students...',
                  hintText: 'Enter name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.personalColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        
        _buildComponentCard(
          'Switches & Toggles',
          'Boolean input controls',
          Column(
            children: [
              SwitchListTile(
                title: const Text('Show online status'),
                subtitle: const Text('Let friends see when you\'re available'),
                value: _toggleValue,
                onChanged: (value) {
                  setState(() {
                    _toggleValue = value;
                  });
                },
                activeColor: AppColors.socialColor,
              ),
              CheckboxListTile(
                title: const Text('Enable notifications'),
                subtitle: const Text('Receive push notifications for messages'),
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.personalColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Category Tags',
          'Filterable and selectable tags',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Technology', 'Creative', 'Sports', 'Cultural', 'Business']
                .map((category) => ChoiceChip(
                      label: Text(category),
                      selected: _selectedChip == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedChip = selected ? category : _selectedChip;
                        });
                      },
                      selectedColor: AppColors.societyColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _selectedChip == category 
                            ? AppColors.societyColor 
                            : AppColors.textSecondary,
                        fontWeight: _selectedChip == category 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ))
                .toList(),
          ),
        ),
        
        _buildComponentCard(
          'Status Chips',
          'Non-interactive status indicators',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: const Text('Online'),
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: const Text('In Class'),
                backgroundColor: AppColors.personalColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppColors.personalColor, fontSize: 12),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: const Text('Study Group'),
                backgroundColor: AppColors.studyGroupColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppColors.studyGroupColor, fontSize: 12),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Online Status Indicators',
          'User availability and presence',
          Column(
            children: [
              _buildStatusRow('Online', Colors.green),
              _buildStatusRow('Away', Colors.orange),
              _buildStatusRow('Busy', Colors.red),
              _buildStatusRow('Offline', Colors.grey),
            ],
          ),
        ),
        
        _buildComponentCard(
          'Badge Indicators',
          'Notification counts and alerts',
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBadgeExample(Icons.message, 3),
              _buildBadgeExample(Icons.notifications, 12),
              _buildBadgeExample(Icons.person_add, 1),
              _buildBadgeExample(Icons.event, 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Bottom Navigation',
          'Main app navigation tabs',
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedItemColor: AppColors.homeColor,
              unselectedItemColor: Colors.grey,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Societies',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Friends',
                ),
              ],
            ),
          ),
        ),
        
        _buildComponentCard(
          'List Tiles',
          'Navigational list items',
          Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.personalColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.settings, color: AppColors.personalColor),
                ),
                title: const Text('Settings'),
                subtitle: const Text('Customize your experience'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.socialColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.help, color: AppColors.socialColor),
                ),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingExamples() {
    return Column(
      children: [
        _buildComponentCard(
          'Progress Indicators',
          'Loading and progress states',
          Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Loading content...')),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.personalColor),
                    strokeWidth: 2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upload progress: 65%'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.65,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.socialColor),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        _buildComponentCard(
          'Skeleton Loaders',
          'Content placeholders while loading',
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(status),
        ],
      ),
    );
  }

  Widget _buildBadgeExample(IconData icon, int count) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentCard(String title, String description, Widget child) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.personalColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInteractionGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app_outlined, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Interaction Guidelines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text('• Maintain minimum 44px touch targets for accessibility'),
          const SizedBox(height: 6),
          const Text('• Use feature colors (AppColors) for primary actions'),
          const SizedBox(height: 6),
          const Text('• Provide visual feedback for all interactions (ripple, hover)'),
          const SizedBox(height: 6),
          const Text('• Use consistent border radius (8-12px) across elements'),
          const SizedBox(height: 6),
          const Text('• Include loading states for async operations'),
          const SizedBox(height: 6),
          const Text('• Ensure sufficient color contrast for text and backgrounds'),
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
            'Interactive Elements Code Examples',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '''// Primary button
ElevatedButton(
  onPressed: () => _handleAction(),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.socialColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('Join Society'),
)

// Search field
TextField(
  decoration: InputDecoration(
    labelText: 'Search...',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.personalColor),
    ),
  ),
)

// Status chip
Chip(
  label: Text('Online'),
  backgroundColor: Colors.green.withValues(alpha: 0.1),
  labelStyle: TextStyle(color: Colors.green, fontSize: 12),
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