import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/timetable_service.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';

class TimetableManagementScreen extends StatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  State<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DemoDataManager _demoData = DemoDataManager.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Timetable Management'),
        backgroundColor: AppColors.personalColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Import', icon: Icon(Icons.cloud_download)),
            Tab(text: 'Manual Entry', icon: Icon(Icons.edit_calendar)),
            Tab(text: 'Current Schedule', icon: Icon(Icons.view_agenda)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ImportTab(),
          _ManualEntryTab(),
          _CurrentScheduleTab(),
        ],
      ),
    );
  }
}

class _ImportTab extends StatefulWidget {
  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  String? selectedSystem;
  bool isConnecting = false;
  final TimetableService _timetableService = TimetableService.instance;

  final List<Map<String, dynamic>> availableSystems = [
    {
      'name': 'UTS MyStudentAdmin',
      'id': 'uts_msa',
      'description': 'University of Technology Sydney Student Portal',
      'icon': Icons.school,
      'color': AppColors.personalColor,
    },
    {
      'name': 'Canvas LMS',
      'id': 'canvas',
      'description': 'Learning Management System Integration',
      'icon': Icons.book,
      'color': AppColors.societyColor,
    },
    {
      'name': 'External Calendar',
      'id': 'external_calendar',
      'description': 'Import from Google Calendar, Outlook, etc.',
      'icon': Icons.calendar_today,
      'color': AppColors.homeColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect to External Systems',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import your timetable automatically from university systems or external calendars.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Connection Status
          if (_timetableService.isSystemConnected('uts_msa')) _buildConnectionStatus(),

          // Available Systems
          const Text(
            'Available Systems',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          ...availableSystems.map((system) => _buildSystemCard(system)),

          const SizedBox(height: 32),

          // Import Instructions
          _buildImportInstructions(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Connected to UTS MyStudentAdmin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _timetableService.disconnectFromSystem('uts_msa');
              setState(() {});
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> system) {
    final isSelected = selectedSystem == system['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? system['color'] : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: system['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            system['icon'],
            color: system['color'],
            size: 24,
          ),
        ),
        title: Text(
          system['name'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          system['description'],
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: isConnecting ? null : () => _connectToSystem(system),
          style: ElevatedButton.styleFrom(
            backgroundColor: system['color'],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isConnecting && isSelected
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildImportInstructions() {
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
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text(
                'Import Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Connect to your university system to automatically import your class schedule\n'
            '• Imported events will appear in your calendar with academic category\n'
            '• Changes in the university system will sync automatically\n'
            '• You can still manually add or edit imported events',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _connectToSystem(Map<String, dynamic> system) async {
    setState(() {
      isConnecting = true;
      selectedSystem = system['id'];
    });

    try {
      final success = await _timetableService.connectToSystem(system['id']);
      
      if (mounted) {
        setState(() {
          isConnecting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to ${system['name']}'),
              backgroundColor: system['color'],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${system['name']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ManualEntryTab extends StatefulWidget {
  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _instructorController = TextEditingController();
  final TimetableService _timetableService = TimetableService.instance;
  
  EventSubType selectedType = EventSubType.lecture;
  List<String> selectedDays = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? startDate;
  DateTime? endDate;

  final List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<EventSubType> academicTypes = [
    EventSubType.lecture,
    EventSubType.tutorial,
    EventSubType.lab,
    EventSubType.workshop,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Class Manually',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your class details to add them to your timetable.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Class Name
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                hintText: 'e.g., Introduction to Programming',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a class name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Class Type
            DropdownButtonFormField<EventSubType>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Class Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: academicTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getSubTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Building 2, Room 123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Instructor
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                hintText: 'e.g., Dr. Smith',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),

            // Days of Week
            const Text(
              'Days of Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: weekDays.map((day) {
                final isSelected = selectedDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: AppColors.personalColor.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.personalColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    'Start Time',
                    startTime,
                    (time) => setState(() => startTime = time),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    'End Time',
                    endTime,
                    (time) => setState(() => endTime = time),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    startDate,
                    (date) => setState(() => startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    endDate,
                    (date) => setState(() => endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Add Class Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.personalColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Timetable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (pickedTime != null) {
          onChanged(pickedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          time?.format(context) ?? 'Select time',
          style: TextStyle(
            color: time != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  String _getSubTypeDisplayName(EventSubType type) {
    switch (type) {
      case EventSubType.lecture:
        return 'Lecture';
      case EventSubType.tutorial:
        return 'Tutorial';
      case EventSubType.lab:
        return 'Laboratory';
      case EventSubType.workshop:
        return 'Workshop';
      default:
        return type.toString().split('.').last;
    }
  }

  void _addClass() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Convert day names to numbers (Monday = 1, Sunday = 7)
      final weekdays = selectedDays.map((day) {
        switch (day) {
          case 'Monday': return 1;
          case 'Tuesday': return 2;
          case 'Wednesday': return 3;
          case 'Thursday': return 4;
          case 'Friday': return 5;
          case 'Saturday': return 6;
          case 'Sunday': return 7;
          default: return 1;
        }
      }).toList();

      await _timetableService.addManualClass(
        title: _titleController.text,
        subType: selectedType,
        location: _locationController.text,
        instructor: _instructorController.text.isNotEmpty ? _instructorController.text : null,
        weekdays: weekdays,
        startTime: startTime!,
        endTime: endTime!,
        startDate: startDate!,
        endDate: endDate!,
        description: _instructorController.text.isNotEmpty 
            ? 'Instructor: ${_instructorController.text}' 
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_titleController.text} added to timetable'),
          backgroundColor: AppColors.personalColor,
        ),
      );

      // Clear form
      _titleController.clear();
      _locationController.clear();
      _instructorController.clear();
      setState(() {
        selectedDays.clear();
        startTime = null;
        endTime = null;
        startDate = null;
        endDate = null;
        selectedType = EventSubType.lecture;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CurrentScheduleTab extends StatelessWidget {
  final TimetableService _timetableService = TimetableService.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventV2>>(
      future: _timetableService.getAcademicEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final academicEvents = snapshot.data ?? [];
        
        if (academicEvents.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Academic Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${academicEvents.length} classes in your timetable',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              ...academicEvents.map((event) => _buildEventCard(context, event)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Classes Added Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import from your university system or add classes manually',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventV2 event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.personalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIconForSubType(event.subType),
            color: AppColors.personalColor,
            size: 24,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.location.isNotEmpty)
              Text(
                event.location,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            Text(
              '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editEvent(context, event);
                break;
              case 'delete':
                _deleteEvent(context, event);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSubType(EventSubType subType) {
    switch (subType) {
      case EventSubType.lecture:
        return Icons.school;
      case EventSubType.tutorial:
        return Icons.group;
      case EventSubType.lab:
        return Icons.science;
      case EventSubType.workshop:
        return Icons.build;
      default:
        return Icons.book;
    }
  }


  void _editEvent(BuildContext context, EventV2 event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality would open here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteEvent(BuildContext context, EventV2 event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to remove "${event.title}" from your timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${event.title} removed from timetable'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}