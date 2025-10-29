import 'package:flutter/material.dart';
import '../models/event_enums.dart';
import '../models/event_v2.dart';
import '../../core/constants/app_colors.dart';

class ReminderSelectionWidget extends StatefulWidget {
  final bool enableReminders;
  final List<int>? reminderMinutesBefore;
  final String? reminderNote;
  final EventSubType eventSubType;
  final Function(bool enableReminders, List<int>? reminderMinutes, String? note) onChanged;

  const ReminderSelectionWidget({
    super.key,
    required this.enableReminders,
    this.reminderMinutesBefore,
    this.reminderNote,
    required this.eventSubType,
    required this.onChanged,
  });

  @override
  State<ReminderSelectionWidget> createState() => _ReminderSelectionWidgetState();
}

class _ReminderSelectionWidgetState extends State<ReminderSelectionWidget> {
  late bool _enableReminders;
  late List<int> _selectedReminders;
  late TextEditingController _noteController;

  // Available reminder options (in minutes) - streamlined
  final Map<int, String> _reminderOptions = {
    5: '5m',
    15: '15m',
    60: '1h',
    1440: '1d',
    10080: '1w',
  };

  @override
  void initState() {
    super.initState();
    _enableReminders = widget.enableReminders;
    _selectedReminders = widget.reminderMinutesBefore?.toList() ??
        EventV2.getDefaultRemindersForType(widget.eventSubType) ?? [15];
    _noteController = TextEditingController(text: widget.reminderNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(
      _enableReminders,
      _enableReminders ? _selectedReminders : null,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Reminder Toggle
        Row(
          children: [
            Switch(
              value: _enableReminders,
              onChanged: (value) {
                setState(() {
                  _enableReminders = value;
                  if (!_enableReminders) {
                    _selectedReminders.clear();
                  } else if (_selectedReminders.isEmpty) {
                    _selectedReminders = EventV2.getDefaultRemindersForType(widget.eventSubType) ?? [15];
                  }
                });
                _notifyChanges();
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 12),
            const Text(
              'Enable Reminders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        if (_enableReminders) ...[
          const SizedBox(height: 16),

          // Quick Presets Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetButton('Classes', [15]),
              _buildPresetButton('Exams', [60, 1440]),
              _buildPresetButton('Assignments', [1440]),
              _buildPresetButton('Social', [60]),
              _buildPresetButton('Custom', []),
            ],
          ),

          const SizedBox(height: 16),

          // Compact Time Selection Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reminderOptions.entries.map((entry) {
              final minutes = entry.key;
              final label = entry.value;
              final isSelected = _selectedReminders.contains(minutes);

              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (!_selectedReminders.contains(minutes)) {
                        _selectedReminders.add(minutes);
                        _selectedReminders.sort();
                      }
                    } else {
                      _selectedReminders.remove(minutes);
                    }
                  });
                  _notifyChanges();
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Compact Reminder Note
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Custom reminder note',
              hintText: 'e.g., "Bring calculator" or "Meet at library"',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.note_outlined, size: 20),
            ),
            maxLines: 1,
            onChanged: (_) => _notifyChanges(),
          ),
        ],
      ],
    );
  }


  Widget _buildPresetButton(String label, List<int> presetReminders) {
    final isSelected = presetReminders.isEmpty
        ? !_isCommonPreset(_selectedReminders)
        : _listsEqual(_selectedReminders, presetReminders);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && presetReminders.isNotEmpty) {
          setState(() {
            _selectedReminders = presetReminders.toList();
          });
          _notifyChanges();
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  bool _isCommonPreset(List<int> reminders) {
    // Check if current selection matches any of the preset patterns
    return _listsEqual(reminders, [15]) ||           // Classes
           _listsEqual(reminders, [60, 1440]) ||     // Exams
           _listsEqual(reminders, [1440]) ||         // Assignments
           _listsEqual(reminders, [60]);             // Social
  }

  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    final sorted1 = list1.toList()..sort();
    final sorted2 = list2.toList()..sort();
    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }
    return true;
  }
}