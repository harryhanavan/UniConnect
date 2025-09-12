/**
 * Relationship management and visualization for the Demo Data Editor
 * Handles displaying and managing relationships between entities
 */

class RelationshipManager {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.initializeRelationshipView();
    }
    
    /**
     * Initialize relationship visualization
     */
    initializeRelationshipView() {
        // The relationships tab will be populated when it's first clicked
        const relationshipsTab = document.getElementById('relationships-tab');
        if (relationshipsTab) {
            relationshipsTab.addEventListener('shown.bs.tab', () => {
                this.renderRelationships();
            });
        }
    }
    
    /**
     * Render all relationship visualizations
     */
    renderRelationships() {
        this.renderFriendConnections();
        this.renderSocietyMemberships();
        this.renderEventRelationships();
        this.renderIntegrityStatus();
    }
    
    /**
     * Render friend connections
     */
    renderFriendConnections() {
        const container = document.getElementById('friendConnections');
        if (!container) return;
        
        const users = this.dataManager.getEntities('user');
        
        if (users.length === 0) {
            container.innerHTML = '<p class="text-muted">No users to show connections for.</p>';
            return;
        }
        
        let html = '<div class="list-group list-group-flush">';
        
        users.forEach(user => {
            const friendCount = user.friendIds ? user.friendIds.length : 0;
            const friends = user.friendIds ? 
                user.friendIds.map(id => this.dataManager.getEntityDisplayName('user', id)) : [];
            
            const pendingRequests = user.pendingFriendRequests ? user.pendingFriendRequests.length : 0;
            const sentRequests = user.sentFriendRequests ? user.sentFriendRequests.length : 0;
            
            html += `
                <div class="list-group-item">
                    <div class="d-flex justify-content-between align-items-start">
                        <div class="flex-grow-1">
                            <strong>${user.name}</strong>
                            <span class="foreign-key-indicator ms-2">${user.id}</span>
                            <div class="mt-1">
                                <span class="badge bg-primary">${friendCount} friends</span>
                                ${pendingRequests > 0 ? `<span class="badge bg-warning">${pendingRequests} pending</span>` : ''}
                                ${sentRequests > 0 ? `<span class="badge bg-info">${sentRequests} sent</span>` : ''}
                            </div>
                            ${friends.length > 0 ? `
                                <div class="mt-2 small">
                                    <strong>Friends:</strong> ${friends.map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                </div>
                            ` : ''}
                        </div>
                        <button class="btn btn-sm btn-outline-primary" onclick="relationshipManager.manageFriendship('${user.id}')">
                            <i class="bi bi-people"></i> Manage
                        </button>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        container.innerHTML = html;
    }
    
    /**
     * Render society memberships
     */
    renderSocietyMemberships() {
        const container = document.getElementById('societyMemberships');
        if (!container) return;
        
        const societies = this.dataManager.getEntities('society');
        const users = this.dataManager.getEntities('user');
        const currentUser = users.find(u => u.id === 'user_001');
        
        if (societies.length === 0) {
            container.innerHTML = '<p class="text-muted">No societies to show memberships for.</p>';
            return;
        }
        
        let html = '<div class="list-group list-group-flush">';
        
        societies.forEach(society => {
            const categoryColor = this.getSocietyCategoryColor(society.category);
            const memberCount = society.memberIds ? society.memberIds.length : society.memberCount;
            const isJoined = society.memberIds?.includes('user_001') || 
                           currentUser?.societyIds?.includes(society.id) || 
                           society.isJoined;
            
            // Get member details
            const members = society.memberIds ? 
                society.memberIds.slice(0, 8).map(id => users.find(u => u.id === id)).filter(u => u) : [];
            
            // Check for friends in society
            const friendsInSociety = society.memberIds ? 
                society.memberIds.filter(id => currentUser?.friendIds?.includes(id)) : [];
            
            html += `
                <div class="list-group-item">
                    <div class="d-flex justify-content-between align-items-start">
                        <div class="flex-grow-1">
                            <div class="d-flex align-items-center">
                                <span class="color-indicator" style="background-color: ${categoryColor}"></span>
                                <strong>${society.name}</strong>
                                <span class="foreign-key-indicator ms-2">${society.id}</span>
                            </div>
                            <div class="mt-1">
                                <span class="badge" style="background-color: ${categoryColor}">${society.category}</span>
                                <span class="badge bg-secondary">${memberCount} members</span>
                                ${isJoined ? '<span class="badge bg-success">Joined</span>' : '<span class="badge bg-light text-dark">Not Joined</span>'}
                                ${friendsInSociety.length > 0 ? `<span class="badge bg-info">${friendsInSociety.length} friends</span>` : ''}
                            </div>
                            
                            ${members.length > 0 ? `
                                <div class="mt-2">
                                    <small><strong>Members:</strong></small>
                                    <div class="d-flex flex-wrap mt-1">
                                        ${members.map(member => `
                                            <img src="${member.profileImageUrl || 'https://api.dicebear.com/7.x/avataaars/png?seed=' + member.name}" 
                                                 alt="${member.name}" 
                                                 title="${member.name}${currentUser?.friendIds?.includes(member.id) ? ' (Friend)' : ''}"
                                                 class="rounded-circle me-1 ${currentUser?.friendIds?.includes(member.id) ? 'border border-success border-2' : ''}" 
                                                 width="25" height="25">
                                        `).join('')}
                                        ${society.memberIds.length > 8 ? `
                                            <div class="rounded-circle bg-secondary text-white d-flex align-items-center justify-content-center" 
                                                 style="width: 25px; height: 25px; font-size: 0.6rem;">
                                                +${society.memberIds.length - 8}
                                            </div>
                                        ` : ''}
                                    </div>
                                </div>
                            ` : ''}
                            
                            <div class="mt-2 small text-muted">
                                ${society.description || 'No description'}
                            </div>
                        </div>
                        <button class="btn btn-sm btn-outline-secondary" onclick="relationshipManager.toggleSocietyMembership('${society.id}')">
                            <i class="bi ${isJoined ? 'bi-box-arrow-right' : 'bi-box-arrow-in-right'}"></i>
                            ${isJoined ? 'Leave' : 'Join'}
                        </button>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        container.innerHTML = html;
    }
    
    /**
     * Render event relationships
     */
    renderEventRelationships() {
        const container = document.getElementById('eventRelationships');
        if (!container) return;
        
        const events = this.dataManager.getEntities('event');
        
        if (events.length === 0) {
            container.innerHTML = '<p class="text-muted">No events to show relationships for.</p>';
            return;
        }
        
        let html = '<div class="list-group list-group-flush">';
        
        events.forEach(event => {
            const categoryColor = this.getEventCategoryColor(event.category);
            const creatorName = this.dataManager.getEntityDisplayName('user', event.creatorId);
            
            const organizers = (event.organizerIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
            const attendees = (event.attendeeIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
            const invited = (event.invitedIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
            const interested = (event.interestedIds || []).map(id => this.dataManager.getEntityDisplayName('user', id));
            
            const totalParticipants = organizers.length + attendees.length + invited.length + interested.length;
            
            html += `
                <div class="list-group-item">
                    <div class="d-flex justify-content-between align-items-start">
                        <div class="flex-grow-1">
                            <div class="d-flex align-items-center">
                                <span class="color-indicator" style="background-color: ${categoryColor}"></span>
                                <strong>${event.title}</strong>
                                <span class="foreign-key-indicator ms-2">${event.id}</span>
                            </div>
                            <div class="mt-1">
                                <span class="badge" style="background-color: ${categoryColor}">${event.category}</span>
                                <span class="badge bg-secondary">${event.subType}</span>
                                <span class="badge bg-info">${totalParticipants} participants</span>
                            </div>
                            
                            <div class="mt-2 small">
                                <div class="mb-1">
                                    <i class="bi bi-person-badge me-1"></i>
                                    <strong>Creator:</strong> <span class="foreign-key-indicator">${creatorName}</span>
                                </div>
                                
                                ${organizers.length > 0 ? `
                                    <div class="mb-1">
                                        <i class="bi bi-people me-1"></i>
                                        <strong>Organizers (${organizers.length}):</strong> 
                                        ${organizers.map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                    </div>
                                ` : ''}
                                
                                ${attendees.length > 0 ? `
                                    <div class="mb-1">
                                        <i class="bi bi-check-circle me-1"></i>
                                        <strong>Attendees (${attendees.length}):</strong> 
                                        ${attendees.slice(0, 3).map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                        ${attendees.length > 3 ? ` <small class="text-muted">+${attendees.length - 3} more</small>` : ''}
                                    </div>
                                ` : ''}
                                
                                ${invited.length > 0 ? `
                                    <div class="mb-1">
                                        <i class="bi bi-envelope me-1"></i>
                                        <strong>Invited (${invited.length}):</strong> 
                                        ${invited.slice(0, 3).map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                        ${invited.length > 3 ? ` <small class="text-muted">+${invited.length - 3} more</small>` : ''}
                                    </div>
                                ` : ''}
                                
                                ${interested.length > 0 ? `
                                    <div class="mb-1">
                                        <i class="bi bi-star me-1"></i>
                                        <strong>Interested (${interested.length}):</strong> 
                                        ${interested.slice(0, 3).map(name => `<span class="foreign-key-indicator">${name}</span>`).join(', ')}
                                        ${interested.length > 3 ? ` <small class="text-muted">+${interested.length - 3} more</small>` : ''}
                                    </div>
                                ` : ''}
                            </div>
                        </div>
                        <button class="btn btn-sm btn-outline-primary" onclick="relationshipManager.manageEventParticipants('${event.id}')">
                            <i class="bi bi-people"></i> Manage
                        </button>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        container.innerHTML = html;
    }
    
    /**
     * Render data integrity status
     */
    renderIntegrityStatus() {
        const container = document.getElementById('integrityStatus');
        if (!container) return;
        
        const issues = this.dataManager.validateIntegrity();
        
        let html = '<div class="mb-3">';
        
        if (issues.length === 0) {
            html += `
                <div class="alert alert-success">
                    <i class="bi bi-check-circle me-2"></i>
                    <strong>All Clear!</strong> No data integrity issues detected.
                </div>
            `;
        } else {
            html += `
                <div class="alert alert-warning">
                    <i class="bi bi-exclamation-triangle me-2"></i>
                    <strong>${issues.length} integrity issue${issues.length > 1 ? 's' : ''} detected:</strong>
                </div>
                <div class="list-group">
            `;
            
            issues.forEach((issue, index) => {
                html += `
                    <div class="list-group-item">
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="validation-error">
                                <i class="bi bi-exclamation-circle me-2"></i>
                                ${issue}
                            </span>
                            <button class="btn btn-sm btn-outline-warning" onclick="relationshipManager.fixIntegrityIssue(${index})">
                                <i class="bi bi-tools"></i> Fix
                            </button>
                        </div>
                    </div>
                `;
            });
            
            html += '</div>';
        }
        
        // Data statistics
        const stats = this.getDataStatistics();
        html += `
            <div class="row mt-4">
                <div class="col-md-3">
                    <div class="card text-center">
                        <div class="card-body">
                            <h5 class="card-title text-primary">${stats.users}</h5>
                            <p class="card-text small">Users</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-center">
                        <div class="card-body">
                            <h5 class="card-title text-success">${stats.events}</h5>
                            <p class="card-text small">Events</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-center">
                        <div class="card-body">
                            <h5 class="card-title text-warning">${stats.societies}</h5>
                            <p class="card-text small">Societies</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-center">
                        <div class="card-body">
                            <h5 class="card-title text-info">${stats.locations}</h5>
                            <p class="card-text small">Locations</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="row mt-3">
                <div class="col-md-4">
                    <div class="card text-center">
                        <div class="card-body">
                            <h6 class="card-title">${stats.friendships}</h6>
                            <p class="card-text small">Friendships</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card text-center">
                        <div class="card-body">
                            <h6 class="card-title">${stats.eventParticipations}</h6>
                            <p class="card-text small">Event Participations</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card text-center">
                        <div class="card-body">
                            <h6 class="card-title">${stats.societyMemberships}</h6>
                            <p class="card-text small">Society Memberships</p>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        html += '</div>';
        container.innerHTML = html;
    }
    
    /**
     * Get data statistics
     */
    getDataStatistics() {
        const users = this.dataManager.getEntities('user');
        const events = this.dataManager.getEntities('event');
        const societies = this.dataManager.getEntities('society');
        const locations = this.dataManager.getEntities('location');
        
        // Count friendships (bidirectional)
        let friendshipCount = 0;
        users.forEach(user => {
            if (user.friendIds) {
                friendshipCount += user.friendIds.length;
            }
        });
        friendshipCount = Math.floor(friendshipCount / 2); // Divide by 2 since relationships are bidirectional
        
        // Count event participations
        let participationCount = 0;
        events.forEach(event => {
            participationCount += (event.organizerIds || []).length;
            participationCount += (event.attendeeIds || []).length;
            participationCount += (event.invitedIds || []).length;
            participationCount += (event.interestedIds || []).length;
        });
        
        // Count society memberships
        const membershipCount = societies.filter(society => society.isJoined).length;
        
        return {
            users: users.length,
            events: events.length,
            societies: societies.length,
            locations: locations.length,
            friendships: friendshipCount,
            eventParticipations: participationCount,
            societyMemberships: membershipCount
        };
    }
    
    /**
     * Get society category color
     */
    getSocietyCategoryColor(category) {
        const colors = {
            academic: '#0D99FF',
            cultural: '#FF6B35',
            sports: '#4CAF50',
            technology: '#8B5CF6',
            arts: '#E91E63',
            social: '#31E615'
        };
        return colors[category] || '#6c757d';
    }
    
    /**
     * Get event category color
     */
    getEventCategoryColor(category) {
        const colors = {
            academic: '#0D99FF',
            social: '#31E615',
            society: '#4CAF50',
            personal: '#8B5CF6',
            university: '#FF7A00'
        };
        return colors[category] || '#6c757d';
    }
    
    /**
     * Manage friendship for a user
     */
    manageFriendship(userId) {
        // TODO: Implement friendship management interface
        const user = this.dataManager.getEntityById('user', userId);
        if (!user) return;
        
        this.dataManager.updateStatus(`Manage friendships for ${user.name} - Feature coming soon`, 'info');
    }
    
    /**
     * Toggle society membership
     */
    toggleSocietyMembership(societyId) {
        const society = this.dataManager.getEntityById('society', societyId);
        if (!society) return;
        
        society.isJoined = !society.isJoined;
        
        if (society.isJoined) {
            society.memberCount++;
            society.joinDate = new Date().toISOString();
        } else {
            society.memberCount = Math.max(0, society.memberCount - 1);
            society.joinDate = null;
        }
        
        this.renderSocietyMemberships();
        this.dataManager.updateStatus(
            `${society.isJoined ? 'Joined' : 'Left'} society "${society.name}"`, 
            'success'
        );
    }
    
    /**
     * Manage event participants
     */
    manageEventParticipants(eventId) {
        // TODO: Implement event participant management interface
        const event = this.dataManager.getEntityById('event', eventId);
        if (!event) return;
        
        this.dataManager.updateStatus(`Manage participants for "${event.title}" - Feature coming soon`, 'info');
    }
    
    /**
     * Fix integrity issue
     */
    fixIntegrityIssue(issueIndex) {
        // TODO: Implement automated fixing of common integrity issues
        this.dataManager.updateStatus(`Auto-fix for integrity issues - Feature coming soon`, 'info');
    }
    
    /**
     * Create relationship network diagram (placeholder)
     */
    createNetworkDiagram() {
        // TODO: Implement interactive network diagram using D3.js or similar
        // This would show users as nodes with friendship connections
        this.dataManager.updateStatus('Network diagram visualization - Feature coming soon', 'info');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.relationshipManager = new RelationshipManager(window.dataManager);
    }
});