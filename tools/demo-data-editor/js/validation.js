/**
 * Data validation system for the Demo Data Editor
 * Handles comprehensive validation and integrity checking
 */

class ValidationSystem {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.validationRules = this.initializeValidationRules();
    }
    
    /**
     * Initialize validation rules
     */
    initializeValidationRules() {
        return {
            user: {
                required: ['name', 'email', 'course', 'year'],
                email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
                yearValues: ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate'],
                statusValues: ['online', 'away', 'busy', 'offline'],
                coordinateRange: { lat: [-90, 90], lng: [-180, 180] }
            },
            event: {
                required: ['title', 'category', 'subType', 'location', 'creatorId'],
                categoryValues: ['academic', 'social', 'society', 'personal', 'university'],
                privacyValues: [
                    'public', 'university', 'faculty', 'friends', 
                    'friendsOfFriends', 'inviteOnly', 'organizersOnly', 'private'
                ],
                subTypeMapping: {
                    academic: ['lecture', 'tutorial', 'workshop', 'seminar', 'exam', 'assignment', 'project'],
                    social: ['party', 'meetup', 'dinner', 'game', 'outing', 'celebration'],
                    society: ['meeting', 'event', 'competition', 'social', 'workshop'],
                    personal: ['study', 'appointment', 'reminder', 'deadline'],
                    university: ['orientation', 'graduation', 'ceremony', 'announcement']
                }
            },
            society: {
                required: ['name', 'category'],
                categoryValues: ['academic', 'cultural', 'sports', 'technology', 'arts', 'social'],
                memberCountMin: 0
            },
            location: {
                required: ['name', 'building', 'latitude', 'longitude', 'type'],
                typeValues: ['lecture_hall', 'classroom', 'lab', 'library', 'study_space', 'common_area', 'outdoor'],
                coordinateRange: { lat: [-90, 90], lng: [-180, 180] },
                utsCoordinateRange: { 
                    lat: [-33.89, -33.88], 
                    lng: [151.19, 151.21] 
                }
            },
            privacy: {
                required: ['userId'],
                shareEventValues: ['public', 'friends', 'private'],
                shareCalendarValues: ['public', 'friends', 'private'],
                allowEventInviteValues: ['everyone', 'friends', 'nobody']
            }
        };
    }
    
    /**
     * Validate all data
     */
    validateAllData() {
        const results = {
            isValid: true,
            warnings: [],
            errors: [],
            statistics: {}
        };
        
        // Validate each entity type
        const entityTypes = ['user', 'event', 'society', 'location', 'privacy'];
        
        entityTypes.forEach(type => {
            const entities = this.dataManager.getEntities(type);
            const typeResults = this.validateEntityType(type, entities);
            
            results.warnings.push(...typeResults.warnings);
            results.errors.push(...typeResults.errors);
            results.statistics[type] = typeResults.statistics;
            
            if (typeResults.errors.length > 0) {
                results.isValid = false;
            }
        });
        
        // Validate relationships
        const relationshipResults = this.validateRelationships();
        results.warnings.push(...relationshipResults.warnings);
        results.errors.push(...relationshipResults.errors);
        
        if (relationshipResults.errors.length > 0) {
            results.isValid = false;
        }
        
        return results;
    }
    
    /**
     * Validate entities of a specific type
     */
    validateEntityType(type, entities) {
        const results = {
            warnings: [],
            errors: [],
            statistics: {
                total: entities.length,
                valid: 0,
                withWarnings: 0,
                withErrors: 0
            }
        };
        
        const rules = this.validationRules[type];
        if (!rules) {
            results.warnings.push(`No validation rules defined for ${type}`);
            return results;
        }
        
        entities.forEach(entity => {
            const entityValidation = this.validateEntity(type, entity, rules);
            
            if (entityValidation.errors.length > 0) {
                results.errors.push(...entityValidation.errors);
                results.statistics.withErrors++;
            } else if (entityValidation.warnings.length > 0) {
                results.warnings.push(...entityValidation.warnings);
                results.statistics.withWarnings++;
            } else {
                results.statistics.valid++;
            }
        });
        
        return results;
    }
    
    /**
     * Validate individual entity
     */
    validateEntity(type, entity, rules) {
        const results = {
            warnings: [],
            errors: []
        };
        
        const entityName = this.getEntityDisplayName(type, entity);
        
        // Check required fields
        if (rules.required) {
            rules.required.forEach(field => {
                if (!entity[field] || (typeof entity[field] === 'string' && entity[field].trim() === '')) {
                    results.errors.push(`${type} "${entityName}": Missing required field "${field}"`);
                }
            });
        }
        
        // Type-specific validations
        switch (type) {
            case 'user':
                this.validateUser(entity, rules, results, entityName);
                break;
            case 'event':
                this.validateEvent(entity, rules, results, entityName);
                break;
            case 'society':
                this.validateSociety(entity, rules, results, entityName);
                break;
            case 'location':
                this.validateLocation(entity, rules, results, entityName);
                break;
            case 'privacy':
                this.validatePrivacySettings(entity, rules, results, entityName);
                break;
        }
        
        return results;
    }
    
    /**
     * Validate user entity
     */
    validateUser(user, rules, results, entityName) {
        // Email validation
        if (user.email && !rules.email.test(user.email)) {
            results.errors.push(`User "${entityName}": Invalid email format`);
        }
        
        // Year validation
        if (user.year && !rules.yearValues.includes(user.year)) {
            results.errors.push(`User "${entityName}": Invalid year value "${user.year}"`);
        }
        
        // Status validation
        if (user.status && !rules.statusValues.includes(user.status)) {
            results.errors.push(`User "${entityName}": Invalid status value "${user.status}"`);
        }
        
        // Coordinate validation
        if (user.latitude !== undefined) {
            if (user.latitude < rules.coordinateRange.lat[0] || user.latitude > rules.coordinateRange.lat[1]) {
                results.errors.push(`User "${entityName}": Latitude out of valid range`);
            }
        }
        
        if (user.longitude !== undefined) {
            if (user.longitude < rules.coordinateRange.lng[0] || user.longitude > rules.coordinateRange.lng[1]) {
                results.errors.push(`User "${entityName}": Longitude out of valid range`);
            }
        }
        
        // Check if isOnline matches status
        if (user.status && user.isOnline !== undefined) {
            const shouldBeOnline = user.status === 'online';
            if (user.isOnline !== shouldBeOnline) {
                results.warnings.push(`User "${entityName}": isOnline (${user.isOnline}) doesn't match status (${user.status})`);
            }
        }
        
        // Check for duplicate emails
        const users = this.dataManager.getEntities('user');
        const duplicateEmails = users.filter(u => u.email === user.email && u.id !== user.id);
        if (duplicateEmails.length > 0) {
            results.errors.push(`User "${entityName}": Duplicate email "${user.email}"`);
        }
    }
    
    /**
     * Validate event entity
     */
    validateEvent(event, rules, results, entityName) {
        // Category validation
        if (event.category && !rules.categoryValues.includes(event.category)) {
            results.errors.push(`Event "${entityName}": Invalid category "${event.category}"`);
        }
        
        // SubType validation
        if (event.category && event.subType) {
            const validSubTypes = rules.subTypeMapping[event.category];
            if (validSubTypes && !validSubTypes.includes(event.subType)) {
                results.errors.push(`Event "${entityName}": Invalid subType "${event.subType}" for category "${event.category}"`);
            }
        }
        
        // Privacy level validation
        if (event.privacyLevel && !rules.privacyValues.includes(event.privacyLevel)) {
            results.errors.push(`Event "${entityName}": Invalid privacy level "${event.privacyLevel}"`);
        }
        
        // Date validation
        if (event.daysFromNow !== undefined && event.hoursFromStart !== undefined && event.duration !== undefined) {
            if (event.duration <= 0) {
                results.errors.push(`Event "${entityName}": Duration must be positive`);
            }
            
            if (event.hoursFromStart < 0 || event.hoursFromStart >= 24) {
                results.warnings.push(`Event "${entityName}": Unusual start time (${event.hoursFromStart} hours)`);
            }
        }
        
        // Check creator exists
        if (event.creatorId && !this.dataManager.getEntityById('user', event.creatorId)) {
            results.errors.push(`Event "${entityName}": Creator "${event.creatorId}" not found`);
        }
        
        // Check organizers exist
        if (event.organizerIds) {
            event.organizerIds.forEach(organizerId => {
                if (!this.dataManager.getEntityById('user', organizerId)) {
                    results.errors.push(`Event "${entityName}": Organizer "${organizerId}" not found`);
                }
            });
        }
        
        // Check attendees exist
        if (event.attendeeIds) {
            event.attendeeIds.forEach(attendeeId => {
                if (!this.dataManager.getEntityById('user', attendeeId)) {
                    results.errors.push(`Event "${entityName}": Attendee "${attendeeId}" not found`);
                }
            });
        }
        
        // Check for overlapping roles
        if (event.creatorId && event.organizerIds && event.organizerIds.includes(event.creatorId)) {
            results.warnings.push(`Event "${entityName}": Creator is also listed as organizer`);
        }
    }
    
    /**
     * Validate society entity
     */
    validateSociety(society, rules, results, entityName) {
        // Category validation
        if (society.category && !rules.categoryValues.includes(society.category)) {
            results.errors.push(`Society "${entityName}": Invalid category "${society.category}"`);
        }
        
        // Member count validation
        if (society.memberCount !== undefined && society.memberCount < rules.memberCountMin) {
            results.errors.push(`Society "${entityName}": Member count cannot be negative`);
        }
        
        // Check for duplicate names
        const societies = this.dataManager.getEntities('society');
        const duplicateNames = societies.filter(s => s.name === society.name && s.id !== society.id);
        if (duplicateNames.length > 0) {
            results.errors.push(`Society "${entityName}": Duplicate name "${society.name}"`);
        }
        
        // Check join status consistency
        if (society.isJoined && society.memberCount === 0) {
            results.warnings.push(`Society "${entityName}": Marked as joined but has 0 members`);
        }
    }
    
    /**
     * Validate location entity
     */
    validateLocation(location, rules, results, entityName) {
        // Type validation
        if (location.type && !rules.typeValues.includes(location.type)) {
            results.errors.push(`Location "${entityName}": Invalid type "${location.type}"`);
        }
        
        // Coordinate validation
        if (location.latitude !== undefined) {
            if (location.latitude < rules.coordinateRange.lat[0] || location.latitude > rules.coordinateRange.lat[1]) {
                results.errors.push(`Location "${entityName}": Latitude out of valid range`);
            }
            
            // UTS campus check
            if (location.latitude < rules.utsCoordinateRange.lat[0] || location.latitude > rules.utsCoordinateRange.lat[1]) {
                results.warnings.push(`Location "${entityName}": Coordinates appear to be outside UTS campus area`);
            }
        }
        
        if (location.longitude !== undefined) {
            if (location.longitude < rules.coordinateRange.lng[0] || location.longitude > rules.coordinateRange.lng[1]) {
                results.errors.push(`Location "${entityName}": Longitude out of valid range`);
            }
            
            // UTS campus check
            if (location.longitude < rules.utsCoordinateRange.lng[0] || location.longitude > rules.utsCoordinateRange.lng[1]) {
                results.warnings.push(`Location "${entityName}": Coordinates appear to be outside UTS campus area`);
            }
        }
        
        // Check for duplicate locations
        const locations = this.dataManager.getEntities('location');
        const duplicateKey = `${location.building}.${location.room || 'Main'}`;
        const duplicates = locations.filter(l => 
            `${l.building}.${l.room || 'Main'}` === duplicateKey && l.id !== location.id
        );
        if (duplicates.length > 0) {
            results.errors.push(`Location "${entityName}": Duplicate location "${duplicateKey}"`);
        }
    }
    
    /**
     * Validate privacy settings
     */
    validatePrivacySettings(privacy, rules, results, entityName) {
        // Check user exists
        if (privacy.userId && !this.dataManager.getEntityById('user', privacy.userId)) {
            results.errors.push(`Privacy settings "${entityName}": User "${privacy.userId}" not found`);
        }
        
        // Validate enum values
        if (privacy.shareEvents && !rules.shareEventValues.includes(privacy.shareEvents)) {
            results.errors.push(`Privacy settings "${entityName}": Invalid shareEvents value "${privacy.shareEvents}"`);
        }
        
        if (privacy.shareCalendar && !rules.shareCalendarValues.includes(privacy.shareCalendar)) {
            results.errors.push(`Privacy settings "${entityName}": Invalid shareCalendar value "${privacy.shareCalendar}"`);
        }
        
        if (privacy.allowEventInvites && !rules.allowEventInviteValues.includes(privacy.allowEventInvites)) {
            results.errors.push(`Privacy settings "${entityName}": Invalid allowEventInvites value "${privacy.allowEventInvites}"`);
        }
    }
    
    /**
     * Validate relationships between entities
     */
    validateRelationships() {
        const results = {
            warnings: [],
            errors: []
        };
        
        // Validate friend relationships
        this.validateFriendships(results);
        
        // Validate event relationships
        this.validateEventRelationships(results);
        
        // Validate privacy settings relationships
        this.validatePrivacyRelationships(results);
        
        return results;
    }
    
    /**
     * Validate friendship relationships
     */
    validateFriendships(results) {
        const users = this.dataManager.getEntities('user');
        
        users.forEach(user => {
            if (user.friendIds) {
                user.friendIds.forEach(friendId => {
                    const friend = this.dataManager.getEntityById('user', friendId);
                    
                    if (!friend) {
                        results.errors.push(`User "${user.name}": Friend "${friendId}" not found`);
                    } else {
                        // Check bidirectional friendship
                        if (!friend.friendIds || !friend.friendIds.includes(user.id)) {
                            results.errors.push(`Asymmetric friendship: "${user.name}" lists "${friend.name}" as friend but not vice versa`);
                        }
                    }
                });
            }
            
            // Check pending friend requests
            if (user.pendingFriendRequests) {
                user.pendingFriendRequests.forEach(requesterId => {
                    const requester = this.dataManager.getEntityById('user', requesterId);
                    if (!requester) {
                        results.errors.push(`User "${user.name}": Pending friend request from non-existent user "${requesterId}"`);
                    }
                });
            }
        });
    }
    
    /**
     * Validate event relationships
     */
    validateEventRelationships(results) {
        const events = this.dataManager.getEntities('event');
        
        events.forEach(event => {
            // Check all user references in events
            const userFields = ['creatorId', 'organizerIds', 'attendeeIds', 'invitedIds', 'interestedIds'];
            
            userFields.forEach(field => {
                if (event[field]) {
                    const userIds = Array.isArray(event[field]) ? event[field] : [event[field]];
                    
                    userIds.forEach(userId => {
                        if (!this.dataManager.getEntityById('user', userId)) {
                            results.errors.push(`Event "${event.title}": User "${userId}" in ${field} not found`);
                        }
                    });
                }
            });
            
            // Check society reference
            if (event.societyId && !this.dataManager.getEntityById('society', event.societyId)) {
                results.errors.push(`Event "${event.title}": Society "${event.societyId}" not found`);
            }
        });
    }
    
    /**
     * Validate privacy settings relationships
     */
    validatePrivacyRelationships(results) {
        const users = this.dataManager.getEntities('user');
        const privacySettings = this.dataManager.getEntities('privacy');
        
        // Check that every user has privacy settings
        users.forEach(user => {
            const userPrivacy = privacySettings.find(p => p.userId === user.id);
            if (!userPrivacy) {
                results.warnings.push(`User "${user.name}": No privacy settings found`);
            }
        });
        
        // Check for orphaned privacy settings
        privacySettings.forEach(privacy => {
            const user = this.dataManager.getEntityById('user', privacy.userId);
            if (!user) {
                results.errors.push(`Privacy settings for "${privacy.userId}": User not found`);
            }
        });
    }
    
    /**
     * Get entity display name for validation messages
     */
    getEntityDisplayName(type, entity) {
        switch (type) {
            case 'user':
                return entity.name || entity.id;
            case 'event':
                return entity.title || entity.id;
            case 'society':
                return entity.name || entity.id;
            case 'location':
                return `${entity.building} ${entity.room || ''}`.trim() || entity.id;
            case 'privacy':
                return entity.userId || entity.id;
            default:
                return entity.id;
        }
    }
    
    /**
     * Format validation results for display
     */
    formatValidationResults(results) {
        let html = '';
        
        if (results.isValid) {
            html += `
                <div class="alert alert-success">
                    <i class="bi bi-check-circle me-2"></i>
                    <strong>Validation Passed!</strong> All data is valid.
                </div>
            `;
        } else {
            html += `
                <div class="alert alert-danger">
                    <i class="bi bi-exclamation-triangle me-2"></i>
                    <strong>Validation Failed!</strong> ${results.errors.length} errors found.
                </div>
            `;
        }
        
        if (results.warnings.length > 0) {
            html += `
                <div class="alert alert-warning">
                    <i class="bi bi-exclamation-circle me-2"></i>
                    <strong>${results.warnings.length} warnings found.</strong>
                </div>
            `;
        }
        
        // Show errors
        if (results.errors.length > 0) {
            html += '<h6 class="text-danger">Errors:</h6><ul class="list-unstyled">';
            results.errors.forEach(error => {
                html += `<li class="validation-error mb-1"><i class="bi bi-x-circle me-2"></i>${error}</li>`;
            });
            html += '</ul>';
        }
        
        // Show warnings
        if (results.warnings.length > 0) {
            html += '<h6 class="text-warning">Warnings:</h6><ul class="list-unstyled">';
            results.warnings.forEach(warning => {
                html += `<li class="text-warning mb-1"><i class="bi bi-exclamation-triangle me-2"></i>${warning}</li>`;
            });
            html += '</ul>';
        }
        
        return html;
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.validationSystem = new ValidationSystem(window.dataManager);
    }
});