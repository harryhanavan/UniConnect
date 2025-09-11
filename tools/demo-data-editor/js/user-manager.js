/**
 * User management functionality for the Demo Data Editor
 * Handles user creation, editing, and visualization
 */

class UserManager {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.initializeUserForm();
    }
    
    /**
     * Initialize user form handlers
     */
    initializeUserForm() {
        const form = document.getElementById('userForm');
        
        // Handle form submission
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleUserSubmission();
            });
        }
        
        // Auto-generate email based on name
        const nameInput = document.getElementById('userName');
        const emailInput = document.getElementById('userEmail');
        
        if (nameInput && emailInput) {
            nameInput.addEventListener('input', (e) => {
                const name = e.target.value.trim();
                if (name && !emailInput.value) {
                    const emailName = name.toLowerCase()
                        .replace(/[^a-z\s]/g, '')
                        .replace(/\s+/g, '.');
                    emailInput.value = `${emailName}@student.uts.edu.au`;
                }
            });
        }
    }
    
    /**
     * Handle user form submission
     */
    handleUserSubmission() {
        try {
            const userData = this.collectUserFormData();
            
            // Validate required fields
            const validation = this.validateUserData(userData);
            if (!validation.isValid) {
                this.dataManager.updateStatus(`Validation failed: ${validation.errors.join(', ')}`, 'error');
                return;
            }
            
            // Convert to User format
            const user = this.convertToUserFormat(userData);
            
            // Add to data manager
            this.dataManager.addEntity('user', user);
            
            // Create corresponding privacy settings
            this.createPrivacySettings(user.id);
            
            // Update UI
            this.renderUsersList();
            this.dataManager.updateUI();
            
            // Reset form
            document.getElementById('userForm').reset();
            
            this.dataManager.updateStatus(`User "${userData.name}" created successfully`, 'success');
            
        } catch (error) {
            console.error('Error creating user:', error);
            this.dataManager.updateStatus(`Error creating user: ${error.message}`, 'error');
        }
    }
    
    /**
     * Collect data from user form
     */
    collectUserFormData() {
        return {
            name: document.getElementById('userName').value.trim(),
            email: document.getElementById('userEmail').value.trim(),
            course: document.getElementById('userCourse').value.trim(),
            year: document.getElementById('userYear').value,
            status: document.getElementById('userStatus').value,
            location: document.getElementById('userLocation').value
        };
    }
    
    /**
     * Validate user data
     */
    validateUserData(data) {
        const errors = [];
        
        if (!data.name) errors.push('Name is required');
        if (!data.email) errors.push('Email is required');
        if (!data.course) errors.push('Course is required');
        if (!data.year) errors.push('Year is required');
        if (!data.status) errors.push('Status is required');
        
        // Validate email format
        if (data.email && !this.isValidEmail(data.email)) {
            errors.push('Invalid email format');
        }
        
        // Check for duplicate email
        const existingUsers = this.dataManager.getEntities('user');
        if (existingUsers.some(user => user.email === data.email)) {
            errors.push('Email already exists');
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
    
    /**
     * Validate email format
     */
    isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
    
    /**
     * Convert form data to User format
     */
    convertToUserFormat(data) {
        const location = this.dataManager.getEntityById('location', data.location);
        
        return {
            name: data.name,
            email: data.email,
            course: data.course,
            year: data.year,
            profileImageUrl: this.generateAvatarUrl(data.name),
            isOnline: data.status === 'online',
            status: data.status,
            currentLocationId: data.location || null,
            currentBuilding: location ? location.building : null,
            currentRoom: location ? location.room : null,
            latitude: location ? location.latitude : -33.8838,
            longitude: location ? location.longitude : 151.2003,
            statusMessage: this.generateStatusMessage(data.status, data.course),
            friendIds: [],
            pendingFriendRequests: [],
            sentFriendRequests: []
        };
    }
    
    /**
     * Generate avatar URL using DiceBear API
     */
    generateAvatarUrl(name) {
        const seed = name.replace(/\s+/g, '');
        return `https://api.dicebear.com/7.x/avataaars/png?seed=${seed}`;
    }
    
    /**
     * Generate appropriate status message
     */
    generateStatusMessage(status, course) {
        const messages = {
            online: [
                `Studying ${course}`,
                'Available for study sessions',
                'Looking for study partners',
                'Active on campus'
            ],
            away: [
                'In class',
                'At the library',
                'Taking a break',
                'Away from desk'
            ],
            busy: [
                'In exam preparation',
                'Working on assignment',
                'In group project',
                'Focus time'
            ],
            offline: [
                'Not available',
                'See you later',
                'Gone for the day',
                'Offline'
            ]
        };
        
        const statusMessages = messages[status] || messages.online;
        return statusMessages[Math.floor(Math.random() * statusMessages.length)];
    }
    
    /**
     * Create privacy settings for new user
     */
    createPrivacySettings(userId) {
        const privacySettings = {
            userId: userId,
            shareLocation: true,
            shareEvents: 'friends',
            shareStatus: true,
            allowFriendRequests: true,
            showInSearch: true,
            shareStudyGroups: 'friends',
            shareAchievements: true,
            allowEventInvites: 'friends',
            shareCalendar: 'friends'
        };
        
        this.dataManager.addEntity('privacy', privacySettings);
    }
    
    /**
     * Render users list
     */
    renderUsersList() {
        const container = document.getElementById('usersList');
        if (!container) return;
        
        const users = this.dataManager.getEntities('user');
        
        if (users.length === 0) {
            container.innerHTML = '<div class="col-12"><p class="text-muted">No users created yet. Add your first user above.</p></div>';
            return;
        }
        
        container.innerHTML = users.map(user => this.createUserCard(user)).join('');
    }
    
    /**
     * Create user card HTML
     */
    createUserCard(user) {
        const locationName = this.getLocationDisplayName(user.currentLocationId);
        const statusColor = this.getStatusColor(user.status);
        const statusIcon = this.getStatusIcon(user.status);
        
        // Get friend count
        const friendCount = user.friendIds ? user.friendIds.length : 0;
        const friendNames = user.friendIds ? 
            user.friendIds.map(id => this.dataManager.getEntityDisplayName('user', id)).slice(0, 3) : [];
        
        return `
            <div class="col-md-6 mb-3">
                <div class="card entity-card h-100">
                    <div class="card-header d-flex justify-content-between align-items-start">
                        <div class="d-flex align-items-center">
                            <img src="${user.profileImageUrl}" alt="${user.name}" 
                                 class="rounded-circle me-2" width="40" height="40">
                            <div>
                                <h6 class="card-title mb-0">${user.name}</h6>
                                <small class="text-muted">${user.id}</small>
                            </div>
                        </div>
                        <div class="text-end">
                            <span class="badge" style="background-color: ${statusColor}">
                                <i class="bi ${statusIcon} me-1"></i>${user.status}
                            </span>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="mb-2">
                            <i class="bi bi-envelope me-2"></i>
                            <small>${user.email}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-book me-2"></i>
                            <small>${user.course}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-calendar me-2"></i>
                            <small>${user.year}</small>
                        </div>
                        
                        ${locationName ? `
                            <div class="mb-2">
                                <i class="bi bi-geo-alt me-2"></i>
                                <small><span class="foreign-key-indicator">${locationName}</span></small>
                            </div>
                        ` : ''}
                        
                        ${user.statusMessage ? `
                            <div class="mb-2">
                                <i class="bi bi-chat-quote me-2"></i>
                                <small class="fst-italic">"${user.statusMessage}"</small>
                            </div>
                        ` : ''}
                        
                        <div class="mb-2">
                            <i class="bi bi-people me-2"></i>
                            <small>
                                Friends: ${friendCount}
                                ${friendNames.length > 0 ? `
                                    <br><span class="ms-3">${friendNames.map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                    ${friendCount > 3 ? ` +${friendCount - 3} more` : ''}</span>
                                ` : ''}
                            </small>
                        </div>
                        
                        <div class="row text-center mt-3">
                            <div class="col-4">
                                <small class="text-muted">Latitude</small>
                                <div class="small">${user.latitude?.toFixed(4) || 'N/A'}</div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Longitude</small>
                                <div class="small">${user.longitude?.toFixed(4) || 'N/A'}</div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Online</small>
                                <div class="small">
                                    <i class="bi ${user.isOnline ? 'bi-check-circle text-success' : 'bi-x-circle text-danger'}"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="card-footer">
                        <button class="btn btn-sm btn-outline-primary me-2" onclick="userManager.editUser('${user.id}')">
                            <i class="bi bi-pencil"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-secondary me-2" onclick="userManager.manageFriends('${user.id}')">
                            <i class="bi bi-people"></i> Friends
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="userManager.deleteUser('${user.id}')">
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
    getLocationDisplayName(locationId) {
        if (!locationId) return null;
        return this.dataManager.getEntityDisplayName('location', locationId);
    }
    
    /**
     * Get status color
     */
    getStatusColor(status) {
        const colors = {
            online: '#198754',
            away: '#fd7e14',
            busy: '#dc3545',
            offline: '#6c757d'
        };
        return colors[status] || colors.offline;
    }
    
    /**
     * Get status icon
     */
    getStatusIcon(status) {
        const icons = {
            online: 'bi-circle-fill',
            away: 'bi-clock',
            busy: 'bi-dash-circle',
            offline: 'bi-circle'
        };
        return icons[status] || icons.offline;
    }
    
    /**
     * Edit user (placeholder)
     */
    editUser(userId) {
        // TODO: Implement user editing
        this.dataManager.updateStatus(`Edit user ${userId} - Feature coming soon`, 'info');
    }
    
    /**
     * Manage friends (placeholder)
     */
    manageFriends(userId) {
        const user = this.dataManager.getEntityById('user', userId);
        if (!user) return;
        
        // TODO: Implement friend management interface
        this.dataManager.updateStatus(`Manage friends for ${user.name} - Feature coming soon`, 'info');
    }
    
    /**
     * Delete user
     */
    deleteUser(userId) {
        const user = this.dataManager.getEntityById('user', userId);
        if (!user) return;
        
        if (confirm(`Are you sure you want to delete user "${user.name}"? This will also remove all their relationships.`)) {
            const users = this.dataManager.getEntities('user');
            const index = users.findIndex(u => u.id === userId);
            
            if (index !== -1) {
                // Remove user from all friend lists
                users.forEach(otherUser => {
                    if (otherUser.friendIds) {
                        otherUser.friendIds = otherUser.friendIds.filter(id => id !== userId);
                    }
                    if (otherUser.pendingFriendRequests) {
                        otherUser.pendingFriendRequests = otherUser.pendingFriendRequests.filter(id => id !== userId);
                    }
                    if (otherUser.sentFriendRequests) {
                        otherUser.sentFriendRequests = otherUser.sentFriendRequests.filter(id => id !== userId);
                    }
                });
                
                // Remove friend requests
                const friendRequests = this.dataManager.getEntities('friendRequest');
                const requestsToRemove = friendRequests.filter(req => 
                    req.senderId === userId || req.receiverId === userId
                );
                requestsToRemove.forEach(req => {
                    const reqIndex = friendRequests.findIndex(r => r.id === req.id);
                    if (reqIndex !== -1) friendRequests.splice(reqIndex, 1);
                });
                
                // Remove privacy settings
                const privacySettings = this.dataManager.getEntities('privacy');
                const privacyIndex = privacySettings.findIndex(p => p.userId === userId);
                if (privacyIndex !== -1) privacySettings.splice(privacyIndex, 1);
                
                // Remove events where user is creator
                const events = this.dataManager.getEntities('event');
                const eventsToRemove = events.filter(event => event.creatorId === userId);
                eventsToRemove.forEach(event => {
                    const eventIndex = events.findIndex(e => e.id === event.id);
                    if (eventIndex !== -1) events.splice(eventIndex, 1);
                });
                
                // Remove user from other events
                events.forEach(event => {
                    if (event.organizerIds) {
                        event.organizerIds = event.organizerIds.filter(id => id !== userId);
                    }
                    if (event.attendeeIds) {
                        event.attendeeIds = event.attendeeIds.filter(id => id !== userId);
                    }
                    if (event.invitedIds) {
                        event.invitedIds = event.invitedIds.filter(id => id !== userId);
                    }
                    if (event.interestedIds) {
                        event.interestedIds = event.interestedIds.filter(id => id !== userId);
                    }
                });
                
                // Finally remove the user
                users.splice(index, 1);
                
                this.renderUsersList();
                this.dataManager.updateUI();
                this.dataManager.updateStatus(`User "${user.name}" and all related data deleted successfully`, 'success');
            }
        }
    }
    
    /**
     * Export users to JSON
     */
    exportUsers() {
        this.dataManager.exportToFile('user', 'users.json');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.userManager = new UserManager(window.dataManager);
    }
});