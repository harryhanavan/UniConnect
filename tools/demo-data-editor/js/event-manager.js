/**
 * Event management functionality for the Demo Data Editor
 * Handles event creation, editing, and visualization
 */

class EventManager {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.initializeEventForm();
        this.setupEventSubTypeMapping();
    }
    
    /**
     * Initialize event form handlers
     */
    initializeEventForm() {
        const form = document.getElementById('eventForm');
        const categorySelect = document.getElementById('eventCategory');
        const subTypeSelect = document.getElementById('eventSubType');
        
        // Handle category change to update sub-types
        if (categorySelect) {
            categorySelect.addEventListener('change', (e) => {
                this.updateSubTypeOptions(e.target.value);
            });
        }
        
        // Handle form submission
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleEventSubmission();
            });
        }
        
        // Set default date to today
        const startDateInput = document.getElementById('eventStartDate');
        const endDateInput = document.getElementById('eventEndDate');
        if (startDateInput && endDateInput) {
            const today = new Date().toISOString().split('T')[0];
            startDateInput.value = today;
            endDateInput.value = today;
        }
        
        // Set default times
        const startTimeInput = document.getElementById('eventStartTime');
        const endTimeInput = document.getElementById('eventEndTime');
        if (startTimeInput && endTimeInput) {
            startTimeInput.value = '10:00';
            endTimeInput.value = '12:00';
        }
    }
    
    /**
     * Setup event sub-type mapping
     */
    setupEventSubTypeMapping() {
        this.eventSubTypes = {
            academic: [
                { value: 'lecture', label: 'Lecture' },
                { value: 'tutorial', label: 'Tutorial' },
                { value: 'workshop', label: 'Workshop' },
                { value: 'seminar', label: 'Seminar' },
                { value: 'exam', label: 'Exam' },
                { value: 'assignment', label: 'Assignment Due' },
                { value: 'project', label: 'Project' }
            ],
            social: [
                { value: 'party', label: 'Party' },
                { value: 'meetup', label: 'Meetup' },
                { value: 'dinner', label: 'Dinner' },
                { value: 'game', label: 'Game/Sport' },
                { value: 'outing', label: 'Outing' },
                { value: 'celebration', label: 'Celebration' }
            ],
            society: [
                { value: 'meeting', label: 'Meeting' },
                { value: 'event', label: 'Society Event' },
                { value: 'competition', label: 'Competition' },
                { value: 'social', label: 'Social Event' },
                { value: 'workshop', label: 'Workshop' }
            ],
            personal: [
                { value: 'study', label: 'Study Session' },
                { value: 'appointment', label: 'Appointment' },
                { value: 'reminder', label: 'Reminder' },
                { value: 'deadline', label: 'Deadline' }
            ],
            university: [
                { value: 'orientation', label: 'Orientation' },
                { value: 'graduation', label: 'Graduation' },
                { value: 'ceremony', label: 'Ceremony' },
                { value: 'announcement', label: 'Announcement' }
            ]
        };
    }
    
    /**
     * Update sub-type options based on selected category
     */
    updateSubTypeOptions(category) {
        const subTypeSelect = document.getElementById('eventSubType');
        if (!subTypeSelect) return;
        
        // Clear existing options
        subTypeSelect.innerHTML = '<option value="">Select Sub Type</option>';
        
        if (category && this.eventSubTypes[category]) {
            this.eventSubTypes[category].forEach(subType => {
                const option = document.createElement('option');
                option.value = subType.value;
                option.textContent = subType.label;
                subTypeSelect.appendChild(option);
            });
        }
    }
    
    /**
     * Handle event form submission
     */
    handleEventSubmission() {
        try {
            const eventData = this.collectEventFormData();
            
            // Validate required fields
            const validation = this.validateEventData(eventData);
            if (!validation.isValid) {
                this.dataManager.updateStatus(`Validation failed: ${validation.errors.join(', ')}`, 'error');
                return;
            }
            
            // Convert to EventV2 format
            const eventV2 = this.convertToEventV2(eventData);
            
            // Add to data manager
            this.dataManager.addEntity('event', eventV2);
            
            // Update UI
            this.renderEventsList();
            this.dataManager.updateUI();
            
            // Reset form
            document.getElementById('eventForm').reset();
            this.updateSubTypeOptions('');
            
            this.dataManager.updateStatus(`Event "${eventData.title}" created successfully`, 'success');
            
        } catch (error) {
            console.error('Error creating event:', error);
            this.dataManager.updateStatus(`Error creating event: ${error.message}`, 'error');
        }
    }
    
    /**
     * Collect data from event form
     */
    collectEventFormData() {
        return {
            title: document.getElementById('eventTitle').value.trim(),
            description: document.getElementById('eventDescription').value.trim(),
            category: document.getElementById('eventCategory').value,
            subType: document.getElementById('eventSubType').value,
            location: document.getElementById('eventLocation').value,
            startDate: document.getElementById('eventStartDate').value,
            startTime: document.getElementById('eventStartTime').value,
            endDate: document.getElementById('eventEndDate').value,
            endTime: document.getElementById('eventEndTime').value,
            creator: document.getElementById('eventCreator').value,
            organizers: Array.from(document.getElementById('eventOrganizers').selectedOptions).map(opt => opt.value),
            attendees: Array.from(document.getElementById('eventAttendees').selectedOptions).map(opt => opt.value),
            privacy: document.getElementById('eventPrivacy').value
        };
    }
    
    /**
     * Validate event data
     */
    validateEventData(data) {
        const errors = [];
        
        if (!data.title) errors.push('Title is required');
        if (!data.category) errors.push('Category is required');
        if (!data.subType) errors.push('Sub Type is required');
        if (!data.location) errors.push('Location is required');
        if (!data.startDate) errors.push('Start Date is required');
        if (!data.startTime) errors.push('Start Time is required');
        if (!data.endDate) errors.push('End Date is required');
        if (!data.endTime) errors.push('End Time is required');
        if (!data.creator) errors.push('Creator is required');
        if (!data.privacy) errors.push('Privacy level is required');
        
        // Validate dates
        if (data.startDate && data.endDate) {
            const startDateTime = new Date(`${data.startDate}T${data.startTime}`);
            const endDateTime = new Date(`${data.endDate}T${data.endTime}`);
            
            if (endDateTime <= startDateTime) {
                errors.push('End time must be after start time');
            }
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
    
    /**
     * Convert form data to EventV2 format
     */
    convertToEventV2(data) {
        const startDateTime = new Date(`${data.startDate}T${data.startTime}`);
        const endDateTime = new Date(`${data.endDate}T${data.endTime}`);
        
        // Calculate days from now for relative dating
        const now = new Date();
        const daysFromNow = Math.floor((startDateTime.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        
        return {
            title: data.title,
            description: data.description || '',
            daysFromNow: daysFromNow,
            hoursFromStart: startDateTime.getHours() + (startDateTime.getMinutes() / 60),
            duration: (endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60), // hours
            location: this.getLocationName(data.location),
            type: data.subType, // Legacy field
            subType: data.subType,
            category: data.category,
            source: 'personal', // Default source
            origin: 'user', // User-created
            creatorId: data.creator,
            organizerIds: data.organizers,
            attendeeIds: data.attendees,
            invitedIds: [],
            interestedIds: [],
            privacyLevel: data.privacy,
            sharingPermission: 'canSuggest',
            discoverability: data.privacy === 'public' ? 'searchable' : 'feedVisible',
            isRecurring: false,
            recurringPattern: null
        };
    }
    
    /**
     * Get location name from location ID
     */
    getLocationName(locationId) {
        const location = this.dataManager.getEntityById('location', locationId);
        if (!location) return locationId;
        return `${location.building}.${location.room || 'Main'}`;
    }
    
    /**
     * Render events list
     */
    renderEventsList() {
        const container = document.getElementById('eventsList');
        if (!container) return;
        
        const events = this.dataManager.getEntities('event');
        
        if (events.length === 0) {
            container.innerHTML = '<div class="col-12"><p class="text-muted">No events created yet. Add your first event above.</p></div>';
            return;
        }
        
        container.innerHTML = events.map(event => this.createEventCard(event)).join('');
    }
    
    /**
     * Create event card HTML
     */
    createEventCard(event) {
        const creatorName = this.dataManager.getEntityDisplayName('user', event.creatorId);
        const locationName = this.getLocationDisplayName(event.location);
        const categoryColor = this.getCategoryColor(event.category);
        
        // Calculate display date
        const startDate = this.calculateEventDate(event);
        const duration = event.duration || 2;
        
        // Get organizers and attendees
        const organizers = (event.organizerIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
        const attendees = (event.attendeeIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
        
        return `
            <div class="col-md-6 mb-3">
                <div class="card entity-card h-100" style="border-left-color: ${categoryColor}">
                    <div class="card-header d-flex justify-content-between align-items-start">
                        <div>
                            <h6 class="card-title mb-1">${event.title}</h6>
                            <small class="text-muted">${event.id}</small>
                        </div>
                        <div class="text-end">
                            <span class="badge" style="background-color: ${categoryColor}">
                                ${event.category}
                            </span>
                            <div>
                                <small class="text-muted">${event.subType}</small>
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <p class="card-text small">${event.description}</p>
                        
                        <div class="mb-2">
                            <i class="bi bi-calendar me-2"></i>
                            <small>${startDate.toLocaleDateString()} ${startDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-clock me-2"></i>
                            <small>${duration} hours</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-geo-alt me-2"></i>
                            <small>${locationName}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-person me-2"></i>
                            <small>Creator: <span class="foreign-key-indicator">${creatorName}</span></small>
                        </div>
                        
                        ${organizers.length > 0 ? `
                            <div class="mb-2">
                                <i class="bi bi-people me-2"></i>
                                <small>Organizers: ${organizers.map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}</small>
                            </div>
                        ` : ''}
                        
                        ${attendees.length > 0 ? `
                            <div class="mb-2">
                                <i class="bi bi-check-circle me-2"></i>
                                <small>Attendees: ${attendees.map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}</small>
                            </div>
                        ` : ''}
                        
                        <div class="mt-2">
                            <span class="badge bg-secondary">${event.privacyLevel}</span>
                        </div>
                    </div>
                    <div class="card-footer">
                        <button class="btn btn-sm btn-outline-primary me-2" onclick="eventManager.editEvent('${event.id}')">
                            <i class="bi bi-pencil"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="eventManager.deleteEvent('${event.id}')">
                            <i class="bi bi-trash"></i> Delete
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    /**
     * Get location display name
     */
    getLocationDisplayName(locationRef) {
        // If it's already a formatted string (like "CB02.04.56"), return as is
        if (typeof locationRef === 'string' && (locationRef.includes('.') || locationRef.includes(' '))) {
            return locationRef;
        }
        
        // Otherwise try to find the location by ID
        const location = this.dataManager.getEntityById('location', locationRef);
        return location ? `${location.building} ${location.room || ''}`.trim() : locationRef;
    }
    
    /**
     * Calculate event date from daysFromNow
     */
    calculateEventDate(event) {
        const now = new Date();
        const eventDate = new Date(now);
        
        if (event.daysFromNow !== undefined) {
            eventDate.setDate(now.getDate() + event.daysFromNow);
        }
        
        if (event.hoursFromStart !== undefined) {
            const hours = Math.floor(event.hoursFromStart);
            const minutes = Math.round((event.hoursFromStart - hours) * 60);
            eventDate.setHours(hours, minutes, 0, 0);
        }
        
        return eventDate;
    }
    
    /**
     * Get category color
     */
    getCategoryColor(category) {
        const colors = {
            academic: '#0D99FF',    // Blue
            social: '#31E615',      // Bright Green
            society: '#4CAF50',     // Green
            personal: '#8B5CF6',    // Purple
            university: '#FF7A00'   // Orange
        };
        return colors[category] || '#6c757d';
    }
    
    /**
     * Edit event (placeholder)
     */
    editEvent(eventId) {
        // TODO: Implement event editing
        this.dataManager.updateStatus(`Edit event ${eventId} - Feature coming soon`, 'info');
    }
    
    /**
     * Delete event
     */
    deleteEvent(eventId) {
        if (confirm('Are you sure you want to delete this event?')) {
            const events = this.dataManager.getEntities('event');
            const index = events.findIndex(event => event.id === eventId);
            
            if (index !== -1) {
                const event = events[index];
                events.splice(index, 1);
                this.renderEventsList();
                this.dataManager.updateUI();
                this.dataManager.updateStatus(`Event "${event.title}" deleted successfully`, 'success');
            }
        }
    }
    
    /**
     * Export events to JSON
     */
    exportEvents() {
        this.dataManager.exportToFile('event', 'events.json');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.eventManager = new EventManager(window.dataManager);
    }
});