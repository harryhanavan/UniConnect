# UniConnect Demo Data Editor

A comprehensive web-based interface for managing and editing UniConnect's demo data with user-friendly forms, relationship visualization, and JSON export capabilities.

## Features

### 📝 **Entity Management**
- **Events**: Create and manage events with EventV2 format support
- **Users**: Add users with privacy settings and location tracking
- **Societies**: Manage university societies and memberships
- **Locations**: UTS campus locations with coordinates and amenities

### 🔗 **Relationship Visualization**
- Friend connections with bidirectional validation
- Society memberships and event participation
- Real-time relationship integrity checking
- Visual foreign key indicators

### 📊 **Data Validation**
- Comprehensive validation rules for all entity types
- Real-time integrity checking
- Detailed error and warning reports
- Export validation reports

### 💾 **Import/Export**
- Load existing JSON files from UniConnect assets
- Export individual entity types or complete datasets
- Backward compatibility with legacy formats
- Proper EventV2 JSON structure generation

## Getting Started

### 1. Open the Editor
Navigate to the demo data editor:
```
tools/demo-data-editor/index.html
```

Open this file in any modern web browser (Chrome, Firefox, Safari, Edge).

### 2. Load Existing Data
1. Click **"Load Data"** in the navigation bar
2. Select JSON files from `UniConnect/assets/demo_data/`:
   - `users.json`
   - `events.json` (or `events_v2.json`)
   - `societies.json`
   - `locations.json`
   - `privacy_settings.json`
   - `friend_requests.json`

### 3. Create New Entries

#### Adding Events
1. Go to the **Events** tab
2. Fill out the event form:
   - **Title & Description**: Basic event information
   - **Category & Sub Type**: Use the dropdown cascading system
   - **Location**: Select from existing locations
   - **Date & Time**: Set start and end times
   - **Creator**: Choose from user dropdown (shows names, stores IDs)
   - **Organizers/Attendees**: Multi-select from users
   - **Privacy Level**: Set event visibility

#### Adding Users
1. Go to the **Users** tab
2. Fill out the user form:
   - **Name**: Full name (auto-generates email)
   - **Course & Year**: Academic information
   - **Status**: Online status
   - **Location**: Current campus location

#### Adding Societies
1. Go to the **Societies** tab
2. Create society entries:
   - **Name & Description**: Society information
   - **Category**: Type of society
   - **Member Count**: Current membership

#### Adding Locations
1. Go to the **Locations** tab
2. Add campus locations:
   - **Building & Room**: UTS building references
   - **Coordinates**: Auto-populated for known UTS buildings
   - **Type**: Location category (lecture hall, lab, etc.)

### 4. View Relationships
Navigate to the **Relationships** tab to see:
- Friend connections between users
- Society memberships
- Event participation breakdown
- Data integrity status

### 5. Export Data
- **Individual exports**: Use export buttons on each tab
- **Complete export**: Click "Export All" for full dataset
- **Validation report**: Export validation results

## Key Features Explained

### User-Friendly Dropdowns
Instead of seeing raw IDs like `user_001`, you'll see:
- **Users**: "Andrea Fernandez"
- **Locations**: "Building 2 Room 04.56"
- **Societies**: "UTS Programming Society"

The interface automatically handles the ID mapping in the background.

### Foreign Key Visualization
Related data is highlighted with blue indicators showing the human-readable names while maintaining proper ID references in the exported JSON.

### EventV2 Format Support
The editor creates events in the enhanced EventV2 format with:
- Two-tier categorization (Category + SubType)
- Comprehensive privacy levels
- User relationships (owner, organizer, attendee, etc.)
- Relative date formatting (`daysFromNow`, `hoursFromStart`)

### Data Validation
Real-time validation includes:
- Required field checking
- Format validation (emails, coordinates)
- Relationship integrity (bidirectional friendships)
- Foreign key validation
- UTS campus coordinate validation

## File Structure

```
tools/demo-data-editor/
├── index.html              # Main interface
├── js/
│   ├── data-manager.js      # Core data management
│   ├── event-manager.js     # Event creation/editing
│   ├── user-manager.js      # User management
│   ├── society-manager.js   # Society management
│   ├── location-manager.js  # Location management
│   ├── relationship-manager.js # Relationship visualization
│   ├── validation.js        # Data validation system
│   └── main.js             # Application controller
└── README.md               # This file
```

## Best Practices

### Creating Events
1. **Select appropriate categories**: Use the cascading dropdown system
2. **Set realistic times**: Events should have positive duration
3. **Add participants**: Include organizers and attendees for realistic data
4. **Choose appropriate privacy**: Match the event type with privacy level

### Managing Relationships
1. **Bidirectional friendships**: The system automatically validates friend relationships
2. **Event participation**: Users can have multiple roles (organizer + attendee)
3. **Society memberships**: Toggle membership affects member counts

### Data Export
1. **Individual files**: Export specific entity types for targeted updates
2. **Complete dataset**: Use for full demo data replacement
3. **Validation first**: Always validate before exporting to catch issues

## Troubleshooting

### Common Issues

**"Validation failed" errors**:
- Check that all required fields are filled
- Ensure email formats are valid
- Verify that selected users/locations exist

**"Foreign key not found" warnings**:
- Load all related data files before creating new entries
- Check that referenced entities exist in the system

**Export issues**:
- Ensure browser allows file downloads
- Check that data validation passes
- Try exporting individual entity types first

### Browser Compatibility
- **Chrome/Edge**: Full support
- **Firefox**: Full support
- **Safari**: Full support
- **Requires**: ES6+ support, File API, JSON support

## Integration with UniConnect

### Using Exported Data
1. Export JSON files from the editor
2. Replace corresponding files in `UniConnect/assets/demo_data/`
3. Run `flutter clean && flutter pub get`
4. The app will use your new demo data

### EventV2 Format
Exported events use the enhanced EventV2 format with backward compatibility. The app's `DemoDataManagerV2` automatically handles both legacy and enhanced formats.

### Validation Integration
The validation rules match those used in the UniConnect app, ensuring data compatibility and integrity.

## Advanced Usage

### Custom Fields
Events support custom fields through the `customFields` property for extensibility.

### Import Sources
Events can be marked with different origins (user, system, society, AI-suggested) for realistic data diversity.

### Privacy Levels
Eight privacy levels supported from public to private with appropriate access control simulation.

### Recurring Events
Support for recurring event patterns with parent-child relationships.

---

This editor provides a complete solution for managing UniConnect's demo data with a focus on usability, data integrity, and proper JSON structure generation. The interface abstracts away the complexity of ID management while maintaining full compatibility with the Flutter application's data models.