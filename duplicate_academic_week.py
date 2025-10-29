#!/usr/bin/env python3
"""
Duplicate Academic Events Script
=================================
Duplicates all academic events from week Oct 13-19 to Oct 5-11.
This fills the previous week with timetable classes since recurring isn't working.

Strategy:
- Find all academic events from Oct 13-19
- Subtract 8 days from their dates
- Create new events with new IDs (event_111+)
- Preserve all other properties
"""

import json
import os
from datetime import datetime, timedelta

# File paths
EVENTS_FILE = r'assets\demo_data\events.json'
BACKUP_FILE = r'assets\demo_data\events_backup_before_week_duplication.json'

def subtract_days_from_datetime(date_string: str, days: int) -> str:
    """Subtract days from ISO datetime string."""
    if not date_string:
        return date_string

    try:
        dt = datetime.fromisoformat(date_string)
        new_dt = dt - timedelta(days=days)
        return new_dt.isoformat()
    except (ValueError, TypeError) as e:
        print(f"  [WARN] Could not parse date '{date_string}': {e}")
        return date_string

def duplicate_event(event: dict, new_id: str, days_to_subtract: int) -> dict:
    """
    Create a duplicate of an event with new ID and adjusted dates.

    Args:
        event: Original event dictionary
        new_id: New event ID
        days_to_subtract: Number of days to subtract from dates

    Returns:
        New event dictionary
    """
    # Create a copy
    new_event = dict(event)

    # Update ID
    new_event['id'] = new_id

    # Update dates
    if 'scheduledDate' in new_event:
        new_event['scheduledDate'] = subtract_days_from_datetime(
            new_event['scheduledDate'], days_to_subtract
        )

    if 'endDate' in new_event:
        new_event['endDate'] = subtract_days_from_datetime(
            new_event['endDate'], days_to_subtract
        )

    # Remove recurring information for duplicated events
    # These are one-time instances, not the recurring pattern
    if 'nextOccurrence' in new_event:
        del new_event['nextOccurrence']

    # Mark as recurring instance if it was recurring
    if new_event.get('isRecurring', False):
        new_event['isRecurringInstance'] = True
        new_event['isRecurring'] = False
        # Keep the parent event ID if it exists, otherwise use original ID
        if 'parentEventId' not in new_event:
            new_event['parentEventId'] = event['id']

    return new_event

def main():
    """Main execution function."""
    print("=" * 80)
    print("DUPLICATE ACADEMIC EVENTS SCRIPT")
    print("=" * 80)
    print(f"Source file: {EVENTS_FILE}")
    print(f"Backup file: {BACKUP_FILE}")
    print(f"Strategy: Duplicate Oct 13-19 academic events to Oct 5-11 (-8 days)")
    print("=" * 80)

    # Check if file exists
    if not os.path.exists(EVENTS_FILE):
        print(f"[ERROR] Events file not found at {EVENTS_FILE}")
        return False

    # Load events
    print(f"\nLoading events from {EVENTS_FILE}...")
    with open(EVENTS_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    events = data.get('events', [])
    print(f"[OK] Loaded {len(events)} events")

    # Create backup
    print(f"\nCreating backup at {BACKUP_FILE}...")
    with open(BACKUP_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("[OK] Backup created successfully")

    # Find academic events from Oct 13-19
    print(f"\nFinding academic events from Oct 13-19...")
    academic_events_to_duplicate = []

    for event in events:
        scheduled_date = event.get('scheduledDate', '')
        category = event.get('category', '')

        # Filter for academic events in the Oct 13-19 range
        if '2025-10-13' <= scheduled_date <= '2025-10-19' and category == 'academic':
            academic_events_to_duplicate.append(event)

    print(f"[OK] Found {len(academic_events_to_duplicate)} academic events to duplicate")

    # Sort by date for organized output
    academic_events_to_duplicate.sort(key=lambda e: e['scheduledDate'])

    # Find highest current event ID
    event_ids = [e.get('id', '') for e in events]
    event_numbers = [int(eid.replace('event_', '')) for eid in event_ids if eid.startswith('event_')]
    next_id = max(event_numbers) + 1

    print(f"[OK] Next available event ID: event_{next_id}")

    # Create duplicates
    print(f"\nCreating duplicate events...")
    print("-" * 80)

    duplicated_events = []
    days_to_subtract = 8  # Oct 13 -> Oct 5 is 8 days

    for event in academic_events_to_duplicate:
        new_id = f"event_{next_id}"
        new_event = duplicate_event(event, new_id, days_to_subtract)
        duplicated_events.append(new_event)

        # Log the duplication
        old_date = event['scheduledDate'][:10]
        new_date = new_event['scheduledDate'][:10]
        title = event.get('title', 'No title')[:50]
        print(f"  {new_id}: {title}")
        print(f"    {old_date} -> {new_date}")

        next_id += 1

    print(f"\n[OK] Created {len(duplicated_events)} duplicate events")

    # Add duplicated events to the events array
    data['events'].extend(duplicated_events)

    # Update comment
    data['_comment'] = (
        "Enhanced events with direct date scheduling system. "
        f"All dates shifted +28 days (October 11, 2025). "
        f"Academic timetable duplicated to Oct 5-11 week. "
        "Timetable events: Oct 5-27. One-time events: Oct 29-Nov 25. "
        "Academic events follow proper semester calendar. "
        "Recurring events include recurringRule for weekly patterns."
    )

    # Save updated data
    print(f"\nSaving updated events to {EVENTS_FILE}...")
    with open(EVENTS_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("[OK] Updated events saved successfully")

    # Summary
    print("\n" + "=" * 80)
    print("DUPLICATION COMPLETE")
    print("=" * 80)
    print(f"[OK] Original events: {len(events)}")
    print(f"[OK] Duplicated events: {len(duplicated_events)}")
    print(f"[OK] Total events now: {len(data['events'])}")
    print(f"[OK] New event IDs: event_{next_id - len(duplicated_events)} through event_{next_id - 1}")
    print(f"[OK] Date range: Oct 5-11, 2025")
    print(f"[OK] Backup saved at: {BACKUP_FILE}")
    print("=" * 80)

    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
