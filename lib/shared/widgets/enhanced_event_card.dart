import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/event_relationship_service.dart';
import '../../core/demo_data/demo_data_manager.dart';

/// Enhanced event card widget that shows EventV2 with attendance status and action buttons
class EnhancedEventCard extends StatefulWidget {
  final EventV2 event;
  final String userId;
  final Function(EventV2)? onEventTap;
  final Function(EventV2, EventRelationship)? onRelationshipChanged;
  final bool showFullDetails;

  const EnhancedEventCard({
    super.key,
    required this.event,
    required this.userId,
    this.onEventTap,
    this.onRelationshipChanged,
    this.showFullDetails = true,
  });

  @override
  State<EnhancedEventCard> createState() => _EnhancedEventCardState();
}

class _EnhancedEventCardState extends State<EnhancedEventCard> {
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  EventRelationship _currentRelationship = EventRelationship.none;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentRelationship = widget.event.getUserRelationship(widget.userId);
  }

  void _updateRelationship(EventRelationship newRelationship) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });

    final success = await _eventRelationshipService.updateEventRelationship(
      widget.userId, 
      widget.event.id, 
      newRelationship
    );

    if (success) {
      setState(() {
        _currentRelationship = newRelationship;
      });
      
      widget.onRelationshipChanged?.call(widget.event, newRelationship);
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getRelationshipMessage(newRelationship)),
            duration: const Duration(seconds: 2),
            backgroundColor: _getRelationshipColor(newRelationship),
          ),
        );
      }
    }

    setState(() {
      _isUpdating = false;
    });
  }

  String _getRelationshipMessage(EventRelationship relationship) {
    switch (relationship) {
      case EventRelationship.attendee:
        return 'Added to your calendar!';
      case EventRelationship.interested:
        return 'Marked as interested';
      case EventRelationship.none:
        return 'Removed from calendar';
      default:
        return 'Updated event status';
    }
  }

  Color _getRelationshipColor(EventRelationship relationship) {
    switch (relationship) {
      case EventRelationship.attendee:
        return AppColors.socialColor;
      case EventRelationship.interested:
        return AppColors.studyGroupColor;
      case EventRelationship.invited:
        return AppColors.personalColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getRelationshipIcon(EventRelationship relationship) {
    switch (relationship) {
      case EventRelationship.owner:
        return Icons.admin_panel_settings;
      case EventRelationship.organizer:
        return Icons.manage_accounts;
      case EventRelationship.attendee:
        return Icons.check_circle;
      case EventRelationship.invited:
        return Icons.mail_outline;
      case EventRelationship.interested:
        return Icons.star_outline;
      case EventRelationship.observer:
        return Icons.visibility;
      case EventRelationship.none:
        return Icons.add_circle_outline;
    }
  }

  String _getRelationshipLabel(EventRelationship relationship) {
    switch (relationship) {
      case EventRelationship.owner:
        return 'Owner';
      case EventRelationship.organizer:
        return 'Organizer';
      case EventRelationship.attendee:
        return 'Going';
      case EventRelationship.invited:
        return 'Invited';
      case EventRelationship.interested:
        return 'Interested';
      case EventRelationship.observer:
        return 'Visible';
      case EventRelationship.none:
        return 'Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = widget.event.societyId != null 
        ? _demoData.getSocietyById(widget.event.societyId!) 
        : null;
    
    final bool isPastEvent = widget.event.startTime.isBefore(DateTime.now());

    return Opacity(
      opacity: isPastEvent ? 0.7 : 1.0, // Reduce opacity for past events
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: ShapeDecoration(
          color: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shadows: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: InkWell(
          onTap: () => widget.onEventTap?.call(widget.event),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header with relationship status
              Row(
                children: [
                  // Event title
                  Expanded(
                    child: Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  
                  // Relationship status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRelationshipColor(_currentRelationship).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8), // Match calendar cards
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRelationshipIcon(_currentRelationship),
                          size: 14,
                          color: _getRelationshipColor(_currentRelationship),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRelationshipLabel(_currentRelationship),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getRelationshipColor(_currentRelationship),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Event details
              if (widget.showFullDetails) ...[
                // Time and location
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(widget.event.startTime),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (isPastEvent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Past',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Society info
                if (society != null)
                  Row(
                    children: [
                      // Society logo
                      Container(
                        width: 20,
                        height: 20,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8), // Match calendar cards
                        ),
                        child: society.logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: society.logoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.societyColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildSocietyLogoPlaceholder(society.category, society.name),
                              )
                            : _buildSocietyLogoPlaceholder(society.category, society.name),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          society.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 12),
              ],
              
              // Action buttons
              if (_canShowActionButtons())
                Row(
                  children: [
                    // Going button
                    if (_currentRelationship != EventRelationship.attendee)
                      Expanded(
                        child: _buildActionButton(
                          'Going',
                          Icons.check_circle,
                          AppColors.socialColor,
                          () => _updateRelationship(EventRelationship.attendee),
                        ),
                      ),
                    
                    if (_currentRelationship != EventRelationship.attendee) const SizedBox(width: 8),
                    
                    // Interested button
                    if (_currentRelationship != EventRelationship.interested && 
                        _currentRelationship != EventRelationship.attendee)
                      Expanded(
                        child: _buildActionButton(
                          'Interested',
                          Icons.star_outline,
                          AppColors.studyGroupColor,
                          () => _updateRelationship(EventRelationship.interested),
                        ),
                      ),
                    
                    if (_currentRelationship != EventRelationship.interested && 
                        _currentRelationship != EventRelationship.attendee) const SizedBox(width: 8),
                    
                    // Remove/Cancel button
                    if (_currentRelationship == EventRelationship.attendee || 
                        _currentRelationship == EventRelationship.interested)
                      Expanded(
                        child: _buildActionButton(
                          _currentRelationship == EventRelationship.attendee ? 'Remove' : 'Cancel',
                          Icons.close,
                          Colors.grey,
                          () => _updateRelationship(EventRelationship.none),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ); // End of Opacity wrapper
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: _isUpdating ? null : onPressed,
      icon: _isUpdating ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  bool _canShowActionButtons() {
    // Show action buttons for events user can manage attendance for
    return _currentRelationship != EventRelationship.owner &&
           _currentRelationship != EventRelationship.organizer;
  }

  String _formatEventTime(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);

    if (difference.inDays > 7) {
      return '${eventTime.day}/${eventTime.month}/${eventTime.year}';
    } else if (difference.inDays > 0) {
      return 'In ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inMinutes > -60) {
      return 'Starting now';
    } else {
      return 'Ended';
    }
  }

  Widget _buildSocietyLogoPlaceholder(String societyCategory, String societyName) {
    // Create a color based on society category
    final colors = {
      'Technology': Colors.blue,
      'Creative': Colors.purple,
      'Sports': Colors.green,
      'Cultural': Colors.orange,
      'Business': Colors.red,
      'Academic': Colors.indigo,
      'Entertainment': Colors.pink,
    };

    final color = colors[societyCategory] ?? Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.groups,
          color: color,
          size: 12,
        ),
      ),
    );
  }
}