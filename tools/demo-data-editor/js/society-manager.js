/**
 * Society management functionality for the Demo Data Editor
 * Handles society creation, editing, and visualization
 */

class SocietyManager {
    constructor(dataManager) {
        this.dataManager = dataManager;
        this.initializeSocietyForm();
    }
    
    /**
     * Initialize society form handlers
     */
    initializeSocietyForm() {
        const form = document.getElementById('societyForm');
        
        // Handle form submission
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleSocietySubmission();
            });
        }
    }
    
    /**
     * Handle society form submission
     */
    handleSocietySubmission() {
        try {
            const societyData = this.collectSocietyFormData();
            
            // Validate required fields
            const validation = this.validateSocietyData(societyData);
            if (!validation.isValid) {
                this.dataManager.updateStatus(`Validation failed: ${validation.errors.join(', ')}`, 'error');
                return;
            }
            
            // Convert to Society format
            const society = this.convertToSocietyFormat(societyData);
            
            // Add to data manager
            this.dataManager.addEntity('society', society);
            
            // Update UI
            this.renderSocietiesList();
            this.dataManager.updateUI();
            
            // Reset form
            document.getElementById('societyForm').reset();
            
            this.dataManager.updateStatus(`Society "${societyData.name}" created successfully`, 'success');
            
        } catch (error) {
            console.error('Error creating society:', error);
            this.dataManager.updateStatus(`Error creating society: ${error.message}`, 'error');
        }
    }
    
    /**
     * Collect data from society form
     */
    collectSocietyFormData() {
        return {
            name: document.getElementById('societyName').value.trim(),
            description: document.getElementById('societyDescription').value.trim(),
            category: document.getElementById('societyCategory').value,
            memberCount: parseInt(document.getElementById('societyMemberCount').value) || 0
        };
    }
    
    /**
     * Validate society data
     */
    validateSocietyData(data) {
        const errors = [];
        
        if (!data.name) errors.push('Name is required');
        if (!data.category) errors.push('Category is required');
        if (data.memberCount < 0) errors.push('Member count cannot be negative');
        
        // Check for duplicate name
        const existingSocieties = this.dataManager.getEntities('society');
        if (existingSocieties.some(society => society.name === data.name)) {
            errors.push('Society name already exists');
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
    
    /**
     * Convert form data to Society format
     */
    convertToSocietyFormat(data) {
        return {
            name: data.name,
            description: data.description || '',
            category: data.category,
            memberCount: data.memberCount,
            imageUrl: this.generateSocietyImageUrl(data.name, data.category),
            isJoined: false, // Default to not joined
            joinDate: null,
            events: [], // Events will be populated by relationship
            contactEmail: this.generateContactEmail(data.name),
            meetingLocation: null, // Can be set later
            establishedYear: new Date().getFullYear(),
            isActive: true,
            tags: this.generateTags(data.category, data.name),
            socialLinks: {
                website: null,
                facebook: null,
                instagram: null,
                discord: null
            }
        };
    }
    
    /**
     * Generate society image URL
     */
    generateSocietyImageUrl(name, category) {
        const seed = name.replace(/\s+/g, '');
        const style = this.getCategoryImageStyle(category);
        return `https://api.dicebear.com/7.x/${style}/png?seed=${seed}`;
    }
    
    /**
     * Get image style based on category
     */
    getCategoryImageStyle(category) {
        const styles = {
            academic: 'shapes',
            cultural: 'identicon',
            sports: 'avataaars',
            technology: 'bottts',
            arts: 'fun-emoji',
            social: 'personas'
        };
        return styles[category] || 'initials';
    }
    
    /**
     * Generate contact email
     */
    generateContactEmail(name) {
        const emailName = name.toLowerCase()
            .replace(/[^a-z\s]/g, '')
            .replace(/\s+/g, '.')
            .replace(/society|club|group/g, '');
        return `${emailName}@societies.uts.edu.au`;
    }
    
    /**
     * Generate tags based on category and name
     */
    generateTags(category, name) {
        const categoryTags = {
            academic: ['study', 'learning', 'academic'],
            cultural: ['culture', 'diversity', 'heritage'],
            sports: ['sports', 'fitness', 'competition'],
            technology: ['tech', 'innovation', 'programming'],
            arts: ['creative', 'arts', 'expression'],
            social: ['social', 'networking', 'community']
        };
        
        const baseTags = categoryTags[category] || ['community'];
        
        // Add tags based on name
        const nameTags = [];
        if (name.toLowerCase().includes('international')) nameTags.push('international');
        if (name.toLowerCase().includes('student')) nameTags.push('student');
        if (name.toLowerCase().includes('women')) nameTags.push('women');
        if (name.toLowerCase().includes('engineering')) nameTags.push('engineering');
        if (name.toLowerCase().includes('business')) nameTags.push('business');
        
        return [...baseTags, ...nameTags].slice(0, 5); // Limit to 5 tags
    }
    
    /**
     * Render societies list
     */
    renderSocietiesList() {
        const container = document.getElementById('societiesList');
        if (!container) return;
        
        const societies = this.dataManager.getEntities('society');
        
        if (societies.length === 0) {
            container.innerHTML = '<div class="col-12"><p class="text-muted">No societies created yet. Add your first society above.</p></div>';
            return;
        }
        
        container.innerHTML = societies.map(society => this.createSocietyCard(society)).join('');
    }
    
    /**
     * Create society card HTML
     */
    createSocietyCard(society) {
        const categoryColor = this.getCategoryColor(society.category);
        const memberText = society.memberCount === 1 ? 'member' : 'members';
        
        // Get related events
        const relatedEvents = this.getRelatedEvents(society.id);
        
        return `
            <div class="col-md-6 mb-3">
                <div class="card entity-card h-100" style="border-left-color: ${categoryColor}">
                    <div class="card-header d-flex justify-content-between align-items-start">
                        <div class="d-flex align-items-center">
                            <img src="${society.imageUrl}" alt="${society.name}" 
                                 class="rounded me-2" width="40" height="40">
                            <div>
                                <h6 class="card-title mb-0">${society.name}</h6>
                                <small class="text-muted">${society.id}</small>
                            </div>
                        </div>
                        <div class="text-end">
                            <span class="badge" style="background-color: ${categoryColor}">
                                ${society.category}
                            </span>
                            <div class="mt-1">
                                <span class="badge ${society.isJoined ? 'bg-success' : 'bg-secondary'}">
                                    ${society.isJoined ? 'Joined' : 'Not Joined'}
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <p class="card-text small">${society.description}</p>
                        
                        <div class="mb-2">
                            <i class="bi bi-people me-2"></i>
                            <small>${society.memberCount} ${memberText}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-envelope me-2"></i>
                            <small>${society.contactEmail}</small>
                        </div>
                        
                        <div class="mb-2">
                            <i class="bi bi-calendar-event me-2"></i>
                            <small>Est. ${society.establishedYear}</small>
                        </div>
                        
                        ${society.meetingLocation ? `
                            <div class="mb-2">
                                <i class="bi bi-geo-alt me-2"></i>
                                <small><span class="foreign-key-indicator">${this.dataManager.getEntityDisplayName('location', society.meetingLocation)}</span></small>
                            </div>
                        ` : ''}
                        
                        ${relatedEvents.length > 0 ? `
                            <div class="mb-2">
                                <i class="bi bi-calendar-check me-2"></i>
                                <small>Events: ${relatedEvents.length}</small>
                                <div class="ms-3 mt-1">
                                    ${relatedEvents.slice(0, 2).map(event => 
                                        `<span class="foreign-key-indicator me-1">${event.title}</span>`
                                    ).join('')}
                                    ${relatedEvents.length > 2 ? `<small class="text-muted">+${relatedEvents.length - 2} more</small>` : ''}
                                </div>
                            </div>
                        ` : ''}
                        
                        <div class="mb-2">
                            <i class="bi bi-tags me-2"></i>
                            <small>
                                ${society.tags.map(tag => `<span class="badge bg-light text-dark me-1">${tag}</span>`).join('')}
                            </small>
                        </div>
                        
                        <div class="row text-center mt-3">
                            <div class="col-4">
                                <small class="text-muted">Active</small>
                                <div class="small">
                                    <i class="bi ${society.isActive ? 'bi-check-circle text-success' : 'bi-x-circle text-danger'}"></i>
                                </div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Events</small>
                                <div class="small">${relatedEvents.length}</div>
                            </div>
                            <div class="col-4">
                                <small class="text-muted">Category</small>
                                <div class="small">${society.category}</div>
                            </div>
                        </div>
                    </div>
                    <div class="card-footer">
                        <button class="btn btn-sm btn-outline-primary me-2" onclick="societyManager.editSociety('${society.id}')">
                            <i class="bi bi-pencil"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-secondary me-2" onclick="societyManager.toggleMembership('${society.id}')">
                            <i class="bi ${society.isJoined ? 'bi-box-arrow-right' : 'bi-box-arrow-in-right'}"></i>
                            ${society.isJoined ? 'Leave' : 'Join'}
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="societyManager.deleteSociety('${society.id}')">
                            <i class="bi bi-trash"></i> Delete
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    /**
     * Get related events for a society
     */
    getRelatedEvents(societyId) {
        const events = this.dataManager.getEntities('event');
        return events.filter(event => event.societyId === societyId);
    }
    
    /**
     * Get category color
     */
    getCategoryColor(category) {
        const colors = {
            academic: '#0D99FF',    // Blue
            cultural: '#FF6B35',    // Orange-red
            sports: '#4CAF50',      // Green
            technology: '#8B5CF6',  // Purple
            arts: '#E91E63',        // Pink
            social: '#31E615'       // Bright Green
        };
        return colors[category] || '#6c757d';
    }
    
    /**
     * Edit society (placeholder)
     */
    editSociety(societyId) {
        // TODO: Implement society editing
        this.dataManager.updateStatus(`Edit society ${societyId} - Feature coming soon`, 'info');
    }
    
    /**
     * Toggle society membership
     */
    toggleMembership(societyId) {
        const societies = this.dataManager.getEntities('society');
        const society = societies.find(s => s.id === societyId);
        
        if (society) {
            society.isJoined = !society.isJoined;
            
            if (society.isJoined) {
                society.memberCount++;
                society.joinDate = new Date().toISOString();
            } else {
                society.memberCount = Math.max(0, society.memberCount - 1);
                society.joinDate = null;
            }
            
            this.renderSocietiesList();
            this.dataManager.updateStatus(
                `${society.isJoined ? 'Joined' : 'Left'} society "${society.name}"`, 
                'success'
            );
        }
    }
    
    /**
     * Delete society
     */
    deleteSociety(societyId) {
        const society = this.dataManager.getEntityById('society', societyId);
        if (!society) return;
        
        if (confirm(`Are you sure you want to delete society "${society.name}"? This will also remove all related events.`)) {
            const societies = this.dataManager.getEntities('society');
            const index = societies.findIndex(s => s.id === societyId);
            
            if (index !== -1) {
                // Remove related events
                const events = this.dataManager.getEntities('event');
                const relatedEvents = events.filter(event => event.societyId === societyId);
                relatedEvents.forEach(event => {
                    const eventIndex = events.findIndex(e => e.id === event.id);
                    if (eventIndex !== -1) events.splice(eventIndex, 1);
                });
                
                // Remove society
                societies.splice(index, 1);
                
                this.renderSocietiesList();
                this.dataManager.updateUI();
                this.dataManager.updateStatus(
                    `Society "${society.name}" and ${relatedEvents.length} related events deleted successfully`, 
                    'success'
                );
            }
        }
    }
    
    /**
     * Export societies to JSON
     */
    exportSocieties() {
        this.dataManager.exportToFile('society', 'societies.json');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.dataManager) {
        window.societyManager = new SocietyManager(window.dataManager);
    }
});