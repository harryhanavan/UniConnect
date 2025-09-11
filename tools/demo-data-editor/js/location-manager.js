/**
 * Location management functionality for the Demo Data Editor
 * Handles location creation, editing, and visualization
 */

class LocationManager {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.initializeLocationForm();
        this.setupUTSDefaults();
    }
    
    /**
     * Initialize location form handlers
     */
    initializeLocationForm() {
        const form = document.getElementById('locationForm');
        
        // Handle form submission
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleLocationSubmission();
            });
        }
        
        // Auto-populate name based on building and room
        const buildingInput = document.getElementById('locationBuilding');
        const roomInput = document.getElementById('locationRoom');
        const nameInput = document.getElementById('locationName');
        
        const updateName = () => {
            const building = buildingInput.value.trim();
            const room = roomInput.value.trim();
            
            if (building && !nameInput.value) {
                nameInput.value = room ? `${building} ${room}` : building;
            }
        };
        
        if (buildingInput && roomInput && nameInput) {
            buildingInput.addEventListener('input', updateName);
            roomInput.addEventListener('input', updateName);
        }
        
        // Set default UTS coordinates
        this.setDefaultCoordinates();
    }
    
    /**
     * Setup UTS campus defaults
     */
    setupUTSDefaults() {
        this.utsBuildings = {
            'Building 1': { lat: -33.8836, lng: 151.2005 },
            'Building 2': { lat: -33.8838, lng: 151.2003 },
            'Building 3': { lat: -33.8841, lng: 151.2007 },
            'Building 4': { lat: -33.8835, lng: 151.2010 },
            'Building 5': { lat: -33.8839, lng: 151.2001 },
            'Building 6': { lat: -33.8834, lng: 151.2008 },
            'Building 7': { lat: -33.8842, lng: 151.2004 },
            'Building 8': { lat: -33.8837, lng: 151.2011 },
            'Building 9': { lat: -33.8840, lng: 151.2002 },
            'Building 10': { lat: -33.8833, lng: 151.2009 },
            'CB02': { lat: -33.8838, lng: 151.2003 }, // Central Building
            'CB06': { lat: -33.8835, lng: 151.2007 },
            'CB07': { lat: -33.8841, lng: 151.2005 },
            'CB11': { lat: -33.8836, lng: 151.2012 },
            'Library': { lat: -33.8837, lng: 151.2006 },
            'Alumni Green': { lat: -33.8839, lng: 151.2008 },
            'Student Centre': { lat: -33.8835, lng: 151.2004 }
        };
        
        // Add building suggestions
        const buildingInput = document.getElementById('locationBuilding');
        if (buildingInput) {
            buildingInput.addEventListener('input', (e) => {
                this.updateCoordinatesForBuilding(e.target.value);
            });
        }
    }
    
    /**
     * Set default coordinates to UTS campus center
     */
    setDefaultCoordinates() {
        const latInput = document.getElementById('locationLat');
        const lngInput = document.getElementById('locationLng');
        
        if (latInput && !latInput.value) latInput.value = -33.8838;
        if (lngInput && !lngInput.value) lngInput.value = 151.2003;
    }
    
    /**
     * Update coordinates based on building name
     */
    updateCoordinatesForBuilding(buildingName) {
        const coords = this.utsBuildings[buildingName];
        if (coords) {
            const latInput = document.getElementById('locationLat');
            const lngInput = document.getElementById('locationLng');
            
            if (latInput) latInput.value = coords.lat;
            if (lngInput) lngInput.value = coords.lng;
        }
    }
    
    /**
     * Handle location form submission
     */
    handleLocationSubmission() {
        try {
            const locationData = this.collectLocationFormData();
            
            // Validate required fields
            const validation = this.validateLocationData(locationData);
            if (!validation.isValid) {
                this.dataManager.updateStatus(`Validation failed: ${validation.errors.join(', ')}`, 'error');
                return;
            }
            
            // Convert to Location format
            const location = this.convertToLocationFormat(locationData);
            
            // Add to data manager
            this.dataManager.addEntity('location', location);
            
            // Update UI
            this.renderLocationsList();
            this.dataManager.updateUI();
            
            // Reset form
            document.getElementById('locationForm').reset();
            this.setDefaultCoordinates();
            
            this.dataManager.updateStatus(`Location "${locationData.name}" created successfully`, 'success');
            
        } catch (error) {
            console.error('Error creating location:', error);
            this.dataManager.updateStatus(`Error creating location: ${error.message}`, 'error');
        }
    }
    
    /**
     * Collect data from location form
     */
    collectLocationFormData() {
        return {
            name: document.getElementById('locationName').value.trim(),
            building: document.getElementById('locationBuilding').value.trim(),
            room: document.getElementById('locationRoom').value.trim(),
            latitude: parseFloat(document.getElementById('locationLat').value),
            longitude: parseFloat(document.getElementById('locationLng').value),
            type: document.getElementById('locationType').value
        };
    }
    
    /**
     * Validate location data
     */
    validateLocationData(data) {
        const errors = [];
        
        if (!data.name) errors.push('Name is required');
        if (!data.building) errors.push('Building is required');
        if (!data.type) errors.push('Type is required');
        if (isNaN(data.latitude) || data.latitude < -90 || data.latitude > 90) {
            errors.push('Valid latitude is required (-90 to 90)');
        }
        if (isNaN(data.longitude) || data.longitude < -180 || data.longitude > 180) {
            errors.push('Valid longitude is required (-180 to 180)');
        }
        
        // Check for duplicate location
        const existingLocations = this.dataManager.getEntities('location');
        const duplicateCheck = `${data.building}.${data.room || 'Main'}`;
        if (existingLocations.some(loc => `${loc.building}.${loc.room || 'Main'}` === duplicateCheck)) {
            errors.push('Location already exists');
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
    
    /**
     * Convert form data to Location format
     */
    convertToLocationFormat(data) {
        return {
            name: data.name,
            building: data.building,
            room: data.room || null,
            latitude: data.latitude,
            longitude: data.longitude,
            type: data.type,
            capacity: this.getDefaultCapacity(data.type),
            amenities: this.getDefaultAmenities(data.type),
            accessibility: {
                wheelchairAccessible: true,
                elevatorAccess: true,
                hearingLoop: data.type === 'lecture_hall'
            },
            operatingHours: {
                weekdays: '06:00-22:00',
                weekends: '08:00-20:00'
            },
            bookingRequired: data.type === 'classroom' || data.type === 'lab',
            tags: this.generateLocationTags(data.type, data.building),
            description: this.generateLocationDescription(data.type, data.building, data.room)
        };
    }
    
    /**
     * Get default capacity based on location type
     */
    getDefaultCapacity(type) {
        const capacities = {
            lecture_hall: 200,
            classroom: 30,
            lab: 25,
            library: 100,
            study_space: 15,
            common_area: 50,
            outdoor: 100
        };
        return capacities[type] || 30;
    }
    
    /**
     * Get default amenities based on location type
     */
    getDefaultAmenities(type) {
        const amenities = {
            lecture_hall: ['projector', 'microphone', 'whiteboard', 'air_conditioning'],
            classroom: ['projector', 'whiteboard', 'air_conditioning', 'power_outlets'],
            lab: ['computers', 'projector', 'specialized_equipment', 'air_conditioning'],
            library: ['wifi', 'quiet_zone', 'computers', 'printing'],
            study_space: ['wifi', 'whiteboard', 'power_outlets', 'quiet_zone'],
            common_area: ['wifi', 'seating', 'food_allowed', 'social_space'],
            outdoor: ['seating', 'weather_dependent', 'natural_light']
        };
        return amenities[type] || ['wifi', 'seating'];
    }
    
    /**
     * Generate location tags
     */
    generateLocationTags(type, building) {
        const typeTags = {
            lecture_hall: ['lecture', 'teaching', 'large_group'],
            classroom: ['teaching', 'small_group', 'interactive'],
            lab: ['practical', 'hands_on', 'technical'],
            library: ['quiet', 'study', 'research'],
            study_space: ['group_work', 'collaborative', 'flexible'],
            common_area: ['social', 'casual', 'break'],
            outdoor: ['fresh_air', 'informal', 'weather_dependent']
        };
        
        const baseTags = typeTags[type] || ['general'];
        const buildingTags = building.includes('CB') ? ['central'] : ['campus'];
        
        return [...baseTags, ...buildingTags].slice(0, 4);
    }
    
    /**
     * Generate location description
     */
    generateLocationDescription(type, building, room) {
        const typeDescriptions = {
            lecture_hall: 'Large teaching space with tiered seating',
            classroom: 'Standard teaching room for interactive learning',
            lab: 'Specialized laboratory with technical equipment',
            library: 'Quiet study space with research resources',
            study_space: 'Flexible space for group or individual study',
            common_area: 'Social space for relaxation and informal meetings',
            outdoor: 'Open air space for informal gatherings'
        };
        
        const baseDescription = typeDescriptions[type] || 'Campus location';
        const roomText = room ? ` in room ${room}` : '';
        
        return `${baseDescription} located in ${building}${roomText}.`;
    }
    
    /**
     * Render locations list
     */
    renderLocationsList() {
        const container = document.getElementById('locationsList');
        if (!container) return;
        
        const locations = this.dataManager.getEntities('location');
        
        if (locations.length === 0) {
            container.innerHTML = '<div class="col-12"><p class="text-muted">No locations created yet. Add your first location above.</p></div>';
            return;
        }
        
        container.innerHTML = locations.map(location => this.createLocationCard(location)).join('');
    }
    
    /**
     * Create location card HTML
     */
    createLocationCard(location) {
        const typeColor = this.getTypeColor(location.type);
        const typeIcon = this.getTypeIcon(location.type);
        
        // Get usage statistics
        const usageStats = this.getLocationUsageStats(location.id);
        
        return `
            <div class="col-md-6 mb-3">
                <div class="card entity-card h-100" style="border-left-color: ${typeColor}">
                    <div class="card-header d-flex justify-content-between align-items-start">
                        <div>
                            <h6 class="card-title mb-0">
                                <i class="bi ${typeIcon} me-2" style="color: ${typeColor}"></i>
                                ${location.name}
                            </h6>
                            <small class="text-muted">${location.id}</small>
                        </div>
                        <div class="text-end">
                            <span class="badge" style="background-color: ${typeColor}">
                                ${location.type.replace('_', ' ')}
                            </span>
                        </div>
                    </div>
                    <div class="card-body">
                        <p class="card-text small">${location.description || 'No description available'}</p>
                        
                        <div class="mb-2">
                            <i class="bi bi-building me-2"></i>
                            <small><strong>${location.building}</strong> ${location.room ? `Room ${location.room}` : ''}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-geo-alt me-2"></i>
                            <small>${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-people me-2"></i>
                            <small>Capacity: ${location.capacity || 'N/A'}</small>
                        </div>
                        
                        ${location.operatingHours ? `
                            <div class="mb-2">
                                <i class="bi bi-clock me-2"></i>
                                <small>Hours: ${location.operatingHours.weekdays}</small>
                            </div>
                        ` : ''}
                        
                        ${location.amenities && location.amenities.length > 0 ? `
                            <div class="mb-2">
                                <i class="bi bi-gear me-2"></i>
                                <small>
                                    ${location.amenities.slice(0, 3).map(amenity => 
                                        `<span class="badge bg-light text-dark me-1">${amenity.replace('_', ' ')}</span>`
                                    ).join('')}
                                    ${location.amenities.length > 3 ? `<small class="text-muted">+${location.amenities.length - 3} more</small>` : ''}
                                </small>
                            </div>
                        ` : ''}
                        
                        ${location.tags && location.tags.length > 0 ? `
                            <div class="mb-2">
                                <i class="bi bi-tags me-2"></i>
                                <small>
                                    ${location.tags.map(tag => `<span class="badge bg-secondary me-1">${tag}</span>`).join('')}
                                </small>
                            </div>
                        ` : ''}
                        
                        <div class="row text-center mt-3">
                            <div class="col-4">
                                <small class="text-muted">Events</small>
                                <div class="small">${usageStats.events}</div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Users</small>
                                <div class="small">${usageStats.users}</div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Accessible</small>
                                <div class="small">
                                    <i class="bi ${location.accessibility?.wheelchairAccessible ? 'bi-check-circle text-success' : 'bi-x-circle text-danger'}"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="card-footer">
                        <button class="btn btn-sm btn-outline-primary me-2" onclick="locationManager.editLocation('${location.id}')">
                            <i class="bi bi-pencil"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-info me-2" onclick="locationManager.viewOnMap('${location.id}')">
                            <i class="bi bi-map"></i> Map
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="locationManager.deleteLocation('${location.id}')">
                            <i class="bi bi-trash"></i> Delete
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    /**
     * Get location usage statistics
     */
    getLocationUsageStats(locationId) {
        const events = this.dataManager.getEntities('event');
        const users = this.dataManager.getEntities('user');
        
        const locationString = this.dataManager.getEntityDisplayName('location', locationId);
        
        // Count events at this location
        const eventCount = events.filter(event => 
            event.location === locationString || 
            event.location === locationId ||
            event.locationId === locationId
        ).length;
        
        // Count users currently at this location
        const userCount = users.filter(user => 
            user.currentLocationId === locationId
        ).length;
        
        return {
            events: eventCount,
            users: userCount
        };
    }
    
    /**
     * Get type color
     */
    getTypeColor(type) {
        const colors = {
            lecture_hall: '#0D99FF',
            classroom: '#4CAF50',
            lab: '#8B5CF6',
            library: '#FF7A00',
            study_space: '#31E615',
            common_area: '#E91E63',
            outdoor: '#795548'
        };
        return colors[type] || '#6c757d';
    }
    
    /**
     * Get type icon
     */
    getTypeIcon(type) {
        const icons = {
            lecture_hall: 'bi-person-video3',
            classroom: 'bi-easel',
            lab: 'bi-cpu',
            library: 'bi-book',
            study_space: 'bi-people',
            common_area: 'bi-cup-hot',
            outdoor: 'bi-tree'
        };
        return icons[type] || 'bi-geo-alt';
    }
    
    /**
     * Edit location (placeholder)
     */
    editLocation(locationId) {
        // TODO: Implement location editing
        this.dataManager.updateStatus(`Edit location ${locationId} - Feature coming soon`, 'info');
    }
    
    /**
     * View location on map
     */
    viewOnMap(locationId) {
        const location = this.dataManager.getEntityById('location', locationId);
        if (!location) return;
        
        const googleMapsUrl = `https://www.google.com/maps?q=${location.latitude},${location.longitude}`;
        window.open(googleMapsUrl, '_blank');
    }
    
    /**
     * Delete location
     */
    deleteLocation(locationId) {
        const location = this.dataManager.getEntityById('location', locationId);
        if (!location) return;
        
        // Check if location is being used
        const usageStats = this.getLocationUsageStats(locationId);
        const isInUse = usageStats.events > 0 || usageStats.users > 0;
        
        const confirmMessage = isInUse ? 
            `Location "${location.name}" is currently being used by ${usageStats.events} events and ${usageStats.users} users. Delete anyway?` :
            `Are you sure you want to delete location "${location.name}"?`;
        
        if (confirm(confirmMessage)) {
            const locations = this.dataManager.getEntities('location');
            const index = locations.findIndex(l => l.id === locationId);
            
            if (index !== -1) {
                // Update events that use this location
                const events = this.dataManager.getEntities('event');
                const locationString = this.dataManager.getEntityDisplayName('location', locationId);
                
                events.forEach(event => {
                    if (event.location === locationString || event.location === locationId || event.locationId === locationId) {
                        event.location = 'TBD';
                        event.locationId = null;
                    }
                });
                
                // Update users at this location
                const users = this.dataManager.getEntities('user');
                users.forEach(user => {
                    if (user.currentLocationId === locationId) {
                        user.currentLocationId = null;
                        user.currentBuilding = null;
                        user.currentRoom = null;
                    }
                });
                
                // Remove location
                locations.splice(index, 1);
                
                this.renderLocationsList();
                this.dataManager.updateUI();
                this.dataManager.updateStatus(
                    `Location "${location.name}" deleted successfully`, 
                    'success'
                );
            }
        }
    }
    
    /**
     * Export locations to JSON
     */
    exportLocations() {
        this.dataManager.exportToFile('location', 'locations.json');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.locationManager = new LocationManager(window.dataManager);
    }
});