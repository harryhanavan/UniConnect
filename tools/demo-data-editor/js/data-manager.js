/**
 * Central data management system for the UniConnect Demo Data Editor
 * Handles loading, parsing, and managing all demo data entities
 */

class DataManager {
    constructor() {
        this.data = {
            users: [],
            events: [],
            societies: [],
            locations: [],
            privacySettings: [],
            friendRequests: []
        };
        
        this.nextIds = {
            user: 1,
            event: 1,
            society: 1,
            location: 1,
            privacy: 1,
            friendRequest: 1
        };
        
        // Event sub-types mapping
        this.eventSubTypes = {
            academic: ['lecture', 'tutorial', 'workshop', 'seminar', 'exam', 'assignment', 'project'],
            social: ['party', 'meetup', 'dinner', 'game', 'outing', 'celebration'],
            society: ['meeting', 'event', 'competition', 'social', 'workshop'],
            personal: ['study', 'appointment', 'reminder', 'deadline'],
            university: ['orientation', 'graduation', 'ceremony', 'announcement']
        };
        
        this.privacyLevels = [
            'public', 'university', 'faculty', 'friends', 
            'friendsOfFriends', 'inviteOnly', 'organizersOnly', 'private'
        ];
        
        this.statusTypes = ['online', 'away', 'busy', 'offline'];
        this.yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate'];
        this.locationTypes = ['lecture_hall', 'classroom', 'lab', 'library', 'study_space', 'common_area', 'outdoor'];
        this.societyCategories = ['academic', 'cultural', 'sports', 'technology', 'arts', 'social'];
    }
    
    /**
     * Load demo data from JSON files
     */
    async loadDataFromFiles(files) {
        const fileContents = {};
        
        for (const file of files) {
            try {
                const content = await this.readFileAsText(file);
                const fileName = file.name.replace('.json', '');
                fileContents[fileName] = JSON.parse(content);
            } catch (error) {
                console.error(`Error loading ${file.name}:`, error);
                throw new Error(`Failed to parse ${file.name}: ${error.message}`);
            }
        }
        
        this.parseLoadedData(fileContents);
        this.updateNextIds();
        this.updateUI();
        
        return {
            success: true,
            message: `Loaded ${Object.keys(fileContents).length} data files successfully`,
            files: Object.keys(fileContents)
        };
    }
    
    /**
     * Parse loaded data and organize it
     */
    parseLoadedData(fileContents) {
        // Load users
        if (fileContents.users) {
            this.data.users = fileContents.users;
        }
        
        // Load events (support both events.json and events_v2.json)
        if (fileContents.events) {
            if (Array.isArray(fileContents.events)) {
                this.data.events = fileContents.events;
            } else if (fileContents.events.events) {
                this.data.events = fileContents.events.events;
            }
        }
        
        if (fileContents.events_v2) {
            if (Array.isArray(fileContents.events_v2)) {
                this.data.events = fileContents.events_v2;
            } else if (fileContents.events_v2.events) {
                this.data.events = fileContents.events_v2.events;
            }
        }
        
        // Load other entities
        if (fileContents.societies) {
            this.data.societies = fileContents.societies;
        }
        
        if (fileContents.locations) {
            this.data.locations = fileContents.locations;
        }
        
        if (fileContents.privacy_settings) {
            this.data.privacySettings = fileContents.privacy_settings;
        }
        
        if (fileContents.friend_requests) {
            this.data.friendRequests = fileContents.friend_requests;
        }
    }
    
    /**
     * Update next ID counters based on existing data
     */
    updateNextIds() {
        this.nextIds.user = this.getNextId(this.data.users, 'user_');
        this.nextIds.event = this.getNextId(this.data.events, 'event_');
        this.nextIds.society = this.getNextId(this.data.societies, 'soc_');
        this.nextIds.location = this.getNextId(this.data.locations, 'loc_');
        this.nextIds.privacy = this.getNextId(this.data.privacySettings, 'privacy_');
        this.nextIds.friendRequest = this.getNextId(this.data.friendRequests, 'req_');
    }
    
    /**
     * Calculate next available ID for a given prefix
     */
    getNextId(array, prefix) {
        if (!array || array.length === 0) return 1;
        
        const ids = array
            .map(item => item.id)
            .filter(id => id.startsWith(prefix))
            .map(id => parseInt(id.replace(prefix, '').padStart(3, '0')))
            .filter(num => !isNaN(num));
            
        return ids.length > 0 ? Math.max(...ids) + 1 : 1;
    }
    
    /**
     * Generate new ID for a given type
     */
    generateId(type) {
        const prefixes = {
            user: 'user_',
            event: 'event_',
            society: 'soc_',
            location: 'loc_',
            privacy: 'privacy_',
            friendRequest: 'req_'
        };
        
        const prefix = prefixes[type];
        const nextNum = this.nextIds[type];
        this.nextIds[type]++;
        
        return `${prefix}${nextNum.toString().padStart(3, '0')}`;
    }
    
    /**
     * Add new entity to data
     */
    addEntity(type, entity) {
        entity.id = this.generateId(type);
        this.data[`${type}s`].push(entity);
        return entity;
    }
    
    /**
     * Get entity by ID
     */
    getEntityById(type, id) {
        const collection = this.data[`${type}s`];
        return collection ? collection.find(item => item.id === id) : null;
    }
    
    /**
     * Get all entities of a type
     */
    getEntities(type) {
        return this.data[`${type}s`] || [];
    }
    
    /**
     * Get user-friendly name for entity
     */
    getEntityDisplayName(type, id) {
        const entity = this.getEntityById(type, id);
        if (!entity) return `${id} (not found)`;
        
        switch (type) {
            case 'user':
                return entity.name;
            case 'event':
                return entity.title;
            case 'society':
                return entity.name;
            case 'location':
                return `${entity.building} ${entity.room || ''}`.trim();
            default:
                return entity.name || entity.title || id;
        }
    }
    
    /**
     * Get sub-types for a given category
     */
    getSubTypesForCategory(category) {
        return this.eventSubTypes[category] || [];
    }
    
    /**
     * Export data as JSON
     */
    exportData(type = 'all') {
        if (type === 'all') {
            return {
                users: this.data.users,
                events: this.data.events,
                societies: this.data.societies,
                locations: this.data.locations,
                privacy_settings: this.data.privacySettings,
                friend_requests: this.data.friendRequests
            };
        } else {
            return this.data[`${type}s`] || [];
        }
    }
    
    /**
     * Export specific entity type to file
     */
    exportToFile(type, filename) {
        let data;
        let finalFilename;
        
        if (type === 'all') {
            data = this.exportData('all');
            finalFilename = filename || 'uniconnect-demo-data.json';
        } else {
            data = this.exportData(type);
            finalFilename = filename || `${type}s.json`;
            
            // Special case for events - wrap in object with events array
            if (type === 'event') {
                data = {
                    _comment: "Enhanced events with Phase 2/3 properties. Uses relative dates and comprehensive categorization.",
                    events: data
                };
                finalFilename = 'events.json';
            }
        }
        
        this.downloadJSON(data, finalFilename);
    }
    
    /**
     * Download JSON data as file
     */
    downloadJSON(data, filename) {
        const jsonString = JSON.stringify(data, null, 2);
        const blob = new Blob([jsonString], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
    
    /**
     * Read file as text
     */
    readFileAsText(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = e => resolve(e.target.result);
            reader.onerror = e => reject(new Error('Failed to read file'));
            reader.readAsText(file);
        });
    }
    
    /**
     * Update UI counters and dropdowns
     */
    updateUI() {
        // Update counters
        document.getElementById('usersCount').textContent = this.data.users.length;
        document.getElementById('eventsCount').textContent = this.data.events.length;
        document.getElementById('societiesCount').textContent = this.data.societies.length;
        document.getElementById('locationsCount').textContent = this.data.locations.length;
        
        // Update dropdowns
        this.updateUserDropdowns();
        this.updateLocationDropdowns();
        this.updateSocietyDropdowns();
        
        // Update status
        this.updateStatus(
            `Data loaded: ${this.data.users.length} users, ${this.data.events.length} events, ` +
            `${this.data.societies.length} societies, ${this.data.locations.length} locations`,
            'success'
        );
    }
    
    /**
     * Update all user dropdowns
     */
    updateUserDropdowns() {
        const userSelects = [
            'eventCreator', 'eventOrganizers', 'eventAttendees', 'userLocation'
        ];
        
        userSelects.forEach(selectId => {
            const select = document.getElementById(selectId);
            if (!select) return;
            
            const isMultiple = select.hasAttribute('multiple');
            const currentValues = isMultiple ? 
                Array.from(select.selectedOptions).map(opt => opt.value) : 
                select.value;
            
            // Clear and repopulate
            if (!isMultiple) {
                select.innerHTML = '<option value="">Select User</option>';
            } else {
                select.innerHTML = '';
            }
            
            this.data.users.forEach(user => {
                const option = document.createElement('option');
                option.value = user.id;
                option.textContent = user.name;
                select.appendChild(option);
            });
            
            // Restore selections
            if (isMultiple && Array.isArray(currentValues)) {
                currentValues.forEach(value => {
                    const option = select.querySelector(`option[value="${value}"]`);
                    if (option) option.selected = true;
                });
            } else if (!isMultiple && currentValues) {
                select.value = currentValues;
            }
        });
    }
    
    /**
     * Update location dropdowns
     */
    updateLocationDropdowns() {
        const locationSelects = ['eventLocation', 'userLocation'];
        
        locationSelects.forEach(selectId => {
            const select = document.getElementById(selectId);
            if (!select) return;
            
            const currentValue = select.value;
            select.innerHTML = '<option value="">Select Location</option>';
            
            this.data.locations.forEach(location => {
                const option = document.createElement('option');
                option.value = location.id;
                option.textContent = `${location.building} ${location.room || ''}`.trim();
                select.appendChild(option);
            });
            
            select.value = currentValue;
        });
    }
    
    /**
     * Update society dropdowns
     */
    updateSocietyDropdowns() {
        // This will be implemented when society relationships are added
    }
    
    /**
     * Update status message
     */
    updateStatus(message, type = 'info') {
        const statusBar = document.getElementById('statusBar');
        const statusText = document.getElementById('statusText');
        
        statusText.textContent = message;
        
        statusBar.className = 'alert mb-4';
        switch (type) {
            case 'success':
                statusBar.classList.add('alert-success');
                break;
            case 'error':
                statusBar.classList.add('alert-danger');
                break;
            case 'warning':
                statusBar.classList.add('alert-warning');
                break;
            default:
                statusBar.classList.add('alert-info');
        }
    }
    
    /**
     * Validate data integrity
     */
    validateIntegrity() {
        const issues = [];
        
        // Check for orphaned references
        this.data.events.forEach(event => {
            // Check creator exists
            if (!this.getEntityById('user', event.creatorId)) {
                issues.push(`Event "${event.title}" has invalid creator: ${event.creatorId}`);
            }
            
            // Check organizers exist
            if (event.organizerIds) {
                event.organizerIds.forEach(id => {
                    if (!this.getEntityById('user', id)) {
                        issues.push(`Event "${event.title}" has invalid organizer: ${id}`);
                    }
                });
            }
            
            // Check attendees exist
            if (event.attendeeIds) {
                event.attendeeIds.forEach(id => {
                    if (!this.getEntityById('user', id)) {
                        issues.push(`Event "${event.title}" has invalid attendee: ${id}`);
                    }
                });
            }
        });
        
        // Check user friend relationships
        this.data.users.forEach(user => {
            if (user.friendIds) {
                user.friendIds.forEach(friendId => {
                    const friend = this.getEntityById('user', friendId);
                    if (!friend) {
                        issues.push(`User "${user.name}" has invalid friend: ${friendId}`);
                    } else if (!friend.friendIds || !friend.friendIds.includes(user.id)) {
                        issues.push(`Asymmetric friendship: "${user.name}" lists "${friend.name}" as friend but not vice versa`);
                    }
                });
            }
        });
        
        return issues;
    }
}

// Global instance
window.dataManager = new DataManager();