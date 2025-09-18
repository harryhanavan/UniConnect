import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/event_migration_service.dart';
import '../../core/utils/event_display_properties.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';

/// Demo screen to showcase enhanced event system
class EnhancedEventDemoScreen extends StatefulWidget {
  const EnhancedEventDemoScreen({super.key});

  @override
  State<EnhancedEventDemoScreen> createState() => _EnhancedEventDemoScreenState();
}

class _EnhancedEventDemoScreenState extends State<EnhancedEventDemoScreen> {
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  List<EventV2> _events = [];
  EventCategory? _selectedCategory;
  EventRelationship? _selectedRelationship;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    final events = await _demoData.enhancedEvents;
    
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }
  
  List<EventV2> get _filteredEvents {
    var filtered = _events;
    
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory!).toList();
    }
    
    if (_selectedRelationship != null) {
      filtered = filtered.where((e) => 
        e.getUserRelationship(_demoData.currentUser.id) == _selectedRelationship!
      ).toList();
    }
    
    // Sort by display priority
    filtered.sort((a, b) {
      final propsA = EventDisplayProperties.fromEventV2(a, _demoData.currentUser.id);
      final propsB = EventDisplayProperties.fromEventV2(b, _demoData.currentUser.id);
      return propsB.displayPriority.compareTo(propsA.displayPriority);
    });
    
    return filtered;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Event System Demo'),
        backgroundColor: AppColors.personalColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                _buildStats(),
                Expanded(child: _buildEventList()),
              ],
            ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category filter
              DropdownButton<EventCategory?>(
                value: _selectedCategory,
                hint: const Text('All Categories'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...EventCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.toString().split('.').last),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              
              // Relationship filter
              DropdownButton<EventRelationship?>(
                value: _selectedRelationship,
                hint: const Text('All Relationships'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Relationships'),
                  ),
                  ...EventRelationship.values.map((relationship) {
                    return DropdownMenuItem(
                      value: relationship,
                      child: Text(relationship.toString().split('.').last),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedRelationship = value);
                },
              ),
              
              // Clear filters button
              if (_selectedCategory != null || _selectedRelationship != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedRelationship = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStats() {
    final categoryStats = <EventCategory, int>{};
    for (final event in _filteredEvents) {
      categoryStats[event.category] = (categoryStats[event.category] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing ${_filteredEvents.length} events',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: categoryStats.entries.map((entry) {
              // Simple category color mapping for demo
              Color color;
              IconData icon;
              switch (entry.key) {
                case EventCategory.academic:
                  color = const Color(0xFF2196F3);
                  icon = Icons.school;
                  break;
                case EventCategory.social:
                  color = const Color(0xFF8BC34A);
                  icon = Icons.people;
                  break;
                case EventCategory.society:
                  color = const Color(0xFF4CAF50);
                  icon = Icons.group;
                  break;
                case EventCategory.personal:
                  color = const Color(0xFF9C27B0);
                  icon = Icons.person;
                  break;
                case EventCategory.university:
                  color = const Color(0xFFFF9800);
                  icon = Icons.account_balance;
                  break;
                default:
                  color = Colors.grey;
                  icon = Icons.event;
              }
              return Chip(
                avatar: Icon(icon, size: 16, color: color),
                label: Text('${entry.key.toString().split('.').last}: ${entry.value}'),
                backgroundColor: color.withAlpha(25),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventList() {
    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text('No events match the selected filters'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return _buildEnhancedEventCard(event);
      },
    );
  }
  
  Widget _buildEnhancedEventCard(EventV2 event) {
    final displayProps = EventDisplayProperties.fromEventV2(
      event, 
      _demoData.currentUser.id,
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: displayProps.primaryColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(
                      displayProps.categoryIcon,
                      color: displayProps.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: displayProps.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayProps.categoryLabel,
                        style: TextStyle(
                          color: displayProps.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Sub-type and relationship
                Row(
                  children: [
                    if (displayProps.subTypeLabel != null) ...[
                      Icon(Icons.label_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        displayProps.subTypeLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (displayProps.relationshipBadge != null) ...[
                      Icon(Icons.person_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        displayProps.relationshipBadge!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Time and location
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Privacy and badges
                if (displayProps.privacyIcon != null || displayProps.badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (displayProps.privacyIcon != null)
                        Icon(
                          displayProps.privacyIcon,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ...displayProps.badges.map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badge.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badge.icon, size: 12, color: badge.color),
                              const SizedBox(width: 2),
                              Text(
                                badge.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: badge.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showEventDetails(EventV2 event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final displayProps = EventDisplayProperties.fromEventV2(
          event,
          _demoData.currentUser.id,
        );
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Event details
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Event Properties (Phase 2)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildDetailRow('Category', event.category.toString().split('.').last),
                  _buildDetailRow('Sub-Type', EventTypeHelper.getSubTypeDisplayName(event.subType)),
                  _buildDetailRow('Origin', event.origin.toString().split('.').last),
                  _buildDetailRow('Privacy', event.privacyLevel.toString().split('.').last),
                  _buildDetailRow('Sharing', event.sharingPermission.toString().split('.').last),
                  _buildDetailRow('Discoverability', event.discoverability.toString().split('.').last),
                  
                  if (event.isRecurring)
                    _buildDetailRow('Recurring', event.recurringPattern ?? 'Yes'),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Participants',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildDetailRow('Creator', event.creatorId),
                  _buildDetailRow('Organizers', event.organizerIds.length.toString()),
                  _buildDetailRow('Attendees', event.attendeeIds.length.toString()),
                  _buildDetailRow('Invited', event.invitedIds.length.toString()),
                  _buildDetailRow('Interested', event.interestedIds.length.toString()),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Your Relationship',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: displayProps.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: displayProps.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayProps.relationshipBadge ?? 'No direct relationship',
                          style: TextStyle(
                            color: displayProps.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}