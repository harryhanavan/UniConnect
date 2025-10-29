#!/usr/bin/env python3
"""
Event Date Transformation Script
=================================
Shifts all event dates forward by 28 days to position events in the future.
This maintains day-of-week consistency while ensuring all events are upcoming.

Transformation Rules:
- September 2025 dates → +28 days (October 13-27)
- October 2025 dates → +28 days (October 29-November 25)
- Updates: scheduledDate, endDate, nextOccurrence
- Preserves: All other event properties
"""

import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any

# File paths
EVENTS_FILE = r'assets\demo_data\events.json'
BACKUP_FILE = r'assets\demo_data\events_backup_pre_transform.json'

def add_days_to_datetime_string(date_string: str, days: int) -> str:
    """
    Add specified days to an ISO datetime string.

    Args:
        date_string: ISO format datetime string (e.g., "2025-09-15T10:00:00")
        days: Number of days to add

    Returns:
        New ISO format datetime string
    """
    if not date_string:
        return date_string

    try:
        dt = datetime.fromisoformat(date_string)
        new_dt = dt + timedelta(days=days)
        return new_dt.isoformat()
    except (ValueError, TypeError) as e:
        print(f"  [WARN] Could not parse date '{date_string}': {e}")
        return date_string

def transform_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform a single event's dates by adding 28 days.

    Args:
        event: Event dictionary

    Returns:
        Transformed event dictionary
    """
    # Apply +28 day shift
    shift_days = 28

    # Track what we're changing
    changes = []

    # Update scheduledDate
    if 'scheduledDate' in event and event['scheduledDate']:
        old_date = event['scheduledDate']
        event['scheduledDate'] = add_days_to_datetime_string(old_date, shift_days)
        if event['scheduledDate'] != old_date:
            changes.append(f"scheduledDate: {old_date[:10]} -> {event['scheduledDate'][:10]}")

    # Update endDate
    if 'endDate' in event and event['endDate']:
        old_date = event['endDate']
        event['endDate'] = add_days_to_datetime_string(old_date, shift_days)
        if event['endDate'] != old_date:
            changes.append(f"endDate: {old_date[:10]} -> {event['endDate'][:10]}")

    # Update nextOccurrence for recurring events
    if 'nextOccurrence' in event and event['nextOccurrence']:
        old_date = event['nextOccurrence']
        event['nextOccurrence'] = add_days_to_datetime_string(old_date, shift_days)
        if event['nextOccurrence'] != old_date:
            changes.append(f"nextOccurrence: {old_date[:10]} -> {event['nextOccurrence'][:10]}")

    # Log changes if verbose mode
    if changes:
        event_id = event.get('id', 'unknown')
        title = event.get('title', 'No title')[:40]
        print(f"  [OK] {event_id}: {title}")
        for change in changes:
            print(f"    - {change}")

    return event

def validate_transformation(old_events: list, new_events: list) -> bool:
    """
    Validate that transformation was successful.

    Args:
        old_events: Original events list
        new_events: Transformed events list

    Returns:
        True if validation passes
    """
    print("\n" + "=" * 80)
    print("VALIDATION CHECKS")
    print("=" * 80)

    # Check event count
    if len(old_events) != len(new_events):
        print(f"[ERROR] Event count mismatch: {len(old_events)} -> {len(new_events)}")
        return False
    print(f"[OK] Event count preserved: {len(new_events)} events")

    # Check that all dates moved forward
    future_count = 0
    past_count = 0
    now = datetime.now()

    for event in new_events:
        if 'scheduledDate' in event and event['scheduledDate']:
            event_date = datetime.fromisoformat(event['scheduledDate'])
            if event_date > now:
                future_count += 1
            else:
                past_count += 1

    print(f"[OK] Events in future: {future_count}")
    if past_count > 0:
        print(f"[WARN] Events still in past: {past_count}")

    # Check day-of-week preservation
    days_match = 0
    days_mismatch = 0

    for old_event, new_event in zip(old_events, new_events):
        if 'scheduledDate' in old_event and old_event['scheduledDate']:
            old_dt = datetime.fromisoformat(old_event['scheduledDate'])
            new_dt = datetime.fromisoformat(new_event['scheduledDate'])

            if old_dt.weekday() == new_dt.weekday():
                days_match += 1
            else:
                days_mismatch += 1
                print(f"  [WARN] Day mismatch for {new_event.get('id')}: {old_dt.strftime('%A')} -> {new_dt.strftime('%A')}")

    print(f"[OK] Day-of-week preserved: {days_match} events")
    if days_mismatch > 0:
        print(f"[ERROR] Day-of-week mismatches: {days_mismatch}")
        return False

    print("\n[OK] All validation checks passed!")
    return True

def main():
    """Main execution function."""
    print("=" * 80)
    print("EVENT DATE TRANSFORMATION SCRIPT")
    print("=" * 80)
    print(f"Source file: {EVENTS_FILE}")
    print(f"Backup file: {BACKUP_FILE}")
    print(f"Transformation: All dates +28 days")
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

    # Transform events
    print(f"\nTransforming event dates (+28 days)...")
    print("-" * 80)

    original_events = [dict(e) for e in events]  # Deep copy for validation
    transformed_events = [transform_event(event) for event in events]

    # Update data structure
    data['events'] = transformed_events

    # Update comment
    data['_comment'] = (
        "Enhanced events with direct date scheduling system. "
        "All dates shifted +28 days (October 11, 2025). "
        "Timetable events: Oct 13-27. One-time events: Oct 29-Nov 25. "
        "Academic events follow proper semester calendar. "
        "Recurring events include recurringRule for weekly patterns."
    )

    # Validate transformation
    if not validate_transformation(original_events, transformed_events):
        print("\n[ERROR] Validation failed! Not saving transformed data.")
        print(f"   Backup remains at {BACKUP_FILE}")
        return False

    # Save transformed data
    print(f"\nSaving transformed events to {EVENTS_FILE}...")
    with open(EVENTS_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("[OK] Transformed events saved successfully")

    # Summary
    print("\n" + "=" * 80)
    print("TRANSFORMATION COMPLETE")
    print("=" * 80)
    print(f"[OK] {len(transformed_events)} events transformed")
    print(f"[OK] All dates shifted forward by 28 days")
    print(f"[OK] Day-of-week consistency maintained")
    print(f"[OK] Backup saved at: {BACKUP_FILE}")
    print("=" * 80)

    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
