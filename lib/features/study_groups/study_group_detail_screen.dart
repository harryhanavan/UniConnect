import 'package:flutter/material.dart';
import '../../shared/models/study_group.dart';
import '../../core/services/study_group_service.dart';
import '../../core/constants/app_colors.dart';

class StudyGroupDetailScreen extends StatefulWidget {
  final StudyGroup studyGroup;

  const StudyGroupDetailScreen({
    super.key,
    required this.studyGroup,
  });

  @override
  State<StudyGroupDetailScreen> createState() => _StudyGroupDetailScreenState();
}

class _StudyGroupDetailScreenState extends State<StudyGroupDetailScreen> {
  final StudyGroupService _studyGroupService = StudyGroupService();
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
  }

  void _checkMembershipStatus() {
    // TODO: Check if current user is a member of this study group
    // This would typically use a user ID from authentication service
    setState(() {
      _isJoined = widget.studyGroup.memberIds.contains('current_user_id');
    });
  }

  Future<void> _toggleMembership() async {
    setState(() => _isLoading = true);
    
    try {
      bool success;
      if (_isJoined) {
        success = await _studyGroupService.leaveStudyGroup(widget.studyGroup.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left study group successfully')),
          );
        }
      } else {
        success = await _studyGroupService.joinStudyGroup(widget.studyGroup.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined study group successfully')),
          );
        }
      }
      
      if (success) {
        setState(() => _isJoined = !_isJoined);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studyGroup.name),
        backgroundColor: AppColors.studyGroupColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _toggleMembership,
              icon: Icon(_isJoined ? Icons.exit_to_app : Icons.add),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.studyGroup.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.studyGroup.isActive ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.studyGroup.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.studyGroup.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.book, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Course: ${widget.studyGroup.courseCode}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Members: ${widget.studyGroup.memberIds.length}/${widget.studyGroup.maxMembers}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (widget.studyGroup.nextMeetingLocation != null && widget.studyGroup.nextMeetingLocation!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Location: ${widget.studyGroup.nextMeetingLocation}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Members section
            const Text(
              'Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (widget.studyGroup.memberIds.isEmpty)
                      const Center(
                        child: Text(
                          'No members yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.studyGroup.memberIds.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final memberId = widget.studyGroup.memberIds[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(memberId.substring(0, 1).toUpperCase()),
                            ),
                            title: Text('Member ${index + 1}'),
                            subtitle: Text('ID: $memberId'),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action button
            if (!_isJoined && !widget.studyGroup.isFull)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleMembership,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.studyGroupColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Join Study Group', style: TextStyle(fontSize: 16)),
                ),
              ),
            
            if (widget.studyGroup.isFull && !_isJoined)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Center(
                  child: Text(
                    'Study Group is Full',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            if (_isJoined)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _toggleMembership,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                          ),
                        )
                      : const Text('Leave Study Group', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}