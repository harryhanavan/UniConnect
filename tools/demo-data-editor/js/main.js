/**
 * Main application controller for the Demo Data Editor
 * Coordinates all managers and handles global functionality
 */

class DemoDataEditor {
    constructor() {
        this.initializeApplication();
        this.setupEventListeners();
    }
    
    /**
     * Initialize the application
     */
    initializeApplication() {
        this.updateStatus('Demo Data Editor initialized. Load existing data or start creating new entries.', 'info');
        
        // Initialize managers (they're already created by their individual files)
        this.dataManager = window.dataManager;
        this.eventManager = window.eventManager;
        this.userManager = window.userManager;
        this.societyManager = window.societyManager;
        this.locationManager = window.locationManager;
        this.relationshipManager = window.relationshipManager;
        this.validationSystem = window.validationSystem;
        
        // Setup tab change handlers
        this.setupTabHandlers();
        
        // Initialize first render
        this.renderAllLists();
    }
    
    /**
     * Setup global event listeners
     */
    setupEventListeners() {
        // Create sample data button
        const createSampleBtn = document.getElementById('createSampleBtn');
        if (createSampleBtn) {
            createSampleBtn.addEventListener('click', () => this.importSampleData());
        }
        
        // Load data button
        const loadDataBtn = document.getElementById('loadDataBtn');
        if (loadDataBtn) {
            loadDataBtn.addEventListener('click', () => this.loadDataFiles());
        }
        
        // Export all button
        const exportAllBtn = document.getElementById('exportAllBtn');
        if (exportAllBtn) {
            exportAllBtn.addEventListener('click', () => this.exportAllData());
        }
        
        // Validate all button
        const validateAllBtn = document.getElementById('validateAllBtn');
        if (validateAllBtn) {
            validateAllBtn.addEventListener('click', () => this.validateAllData());
        }
        
        // Individual export buttons
        const exportButtons = [
            { id: 'exportEventsBtn', handler: () => this.eventManager.exportEvents() },
            { id: 'exportUsersBtn', handler: () => this.userManager.exportUsers() },
            { id: 'exportSocietiesBtn', handler: () => this.societyManager.exportSocieties() },
            { id: 'exportLocationsBtn', handler: () => this.locationManager.exportLocations() }
        ];
        
        exportButtons.forEach(({ id, handler }) => {
            const btn = document.getElementById(id);
            if (btn) {
                btn.addEventListener('click', handler);
            }
        });
        
        // Handle file input for loading data
        const fileInput = document.getElementById('fileInput');
        if (fileInput) {
            fileInput.addEventListener('change', (e) => this.handleFileSelection(e));
        }
    }
    
    /**
     * Setup tab change handlers
     */
    setupTabHandlers() {
        const tabs = document.querySelectorAll('#mainTabs button[data-bs-toggle="pill"]');
        
        tabs.forEach(tab => {
            tab.addEventListener('shown.bs.tab', (e) => {
                const targetId = e.target.getAttribute('data-bs-target').replace('#', '');
                this.handleTabChange(targetId);
            });
        });
    }
    
    /**
     * Handle tab changes
     */
    handleTabChange(tabId) {
        switch (tabId) {
            case 'events':
                this.eventManager.renderEventsList();
                break;
            case 'users':
                this.userManager.renderUsersList();
                break;
            case 'societies':
                this.societyManager.renderSocietiesList();
                break;
            case 'locations':
                this.locationManager.renderLocationsList();
                break;
            case 'relationships':
                this.relationshipManager.renderRelationships();
                break;
        }
    }
    
    /**
     * Load data files
     */
    loadDataFiles() {
        // Show the file input container
        const fileInputContainer = document.getElementById('fileInputContainer');
        const mainContent = document.getElementById('mainTabContent');
        
        if (fileInputContainer && mainContent) {
            fileInputContainer.style.display = 'block';
            mainContent.style.display = 'none';
            
            // Scroll to the file input
            fileInputContainer.scrollIntoView({ behavior: 'smooth' });
        }
    }
    
    /**
     * Cancel file selection
     */
    cancelFileSelection() {
        const fileInputContainer = document.getElementById('fileInputContainer');
        const mainContent = document.getElementById('mainTabContent');
        const fileInput = document.getElementById('fileInput');
        
        if (fileInputContainer && mainContent) {
            fileInputContainer.style.display = 'none';
            mainContent.style.display = 'block';
        }
        
        if (fileInput) {
            fileInput.value = '';
        }
    }
    
    /**
     * Handle file selection
     */
    async handleFileSelection(event) {
        const files = Array.from(event.target.files);
        
        if (files.length === 0) {
            this.updateStatus('No files selected', 'warning');
            return;
        }
        
        // Validate file types
        const invalidFiles = files.filter(file => !file.name.endsWith('.json'));
        if (invalidFiles.length > 0) {
            this.updateStatus(`Invalid file types: ${invalidFiles.map(f => f.name).join(', ')}. Only JSON files are supported.`, 'error');
            return;
        }
        
        try {
            this.updateStatus('Loading data files...', 'info');
            
            const result = await this.dataManager.loadDataFromFiles(files);
            
            if (result.success) {
                this.renderAllLists();
                this.updateStatus(result.message, 'success');
                
                // Hide file input and show main content
                this.cancelFileSelection();
            } else {
                this.updateStatus(`Failed to load data: ${result.message}`, 'error');
            }
            
        } catch (error) {
            console.error('Error loading files:', error);
            this.updateStatus(`Error loading files: ${error.message}`, 'error');
        }
        
        // Clear the file input
        event.target.value = '';
    }
    
    /**
     * Export all data
     */
    exportAllData() {
        try {
            this.dataManager.exportToFile('all', 'uniconnect-demo-data-complete.json');
            this.updateStatus('All data exported successfully', 'success');
        } catch (error) {
            console.error('Error exporting data:', error);
            this.updateStatus(`Error exporting data: ${error.message}`, 'error');
        }
    }
    
    /**
     * Validate all data
     */
    validateAllData() {
        try {
            this.updateStatus('Running comprehensive data validation...', 'info');
            
            const results = this.validationSystem.validateAllData();
            
            // Display results in a modal or dedicated area
            this.displayValidationResults(results);
            
            if (results.isValid) {
                this.updateStatus('Data validation completed - All data is valid', 'success');
            } else {
                this.updateStatus(`Data validation completed - ${results.errors.length} errors found`, 'error');
            }
            
        } catch (error) {
            console.error('Error validating data:', error);
            this.updateStatus(`Error during validation: ${error.message}`, 'error');
        }
    }
    
    /**
     * Display validation results
     */
    displayValidationResults(results) {
        // Create modal for validation results
        const modalId = 'validationModal';
        let modal = document.getElementById(modalId);
        
        if (!modal) {
            modal = this.createValidationModal(modalId);
            document.body.appendChild(modal);
        }
        
        // Update modal content
        const modalBody = modal.querySelector('.modal-body');
        if (modalBody) {
            modalBody.innerHTML = this.validationSystem.formatValidationResults(results);
            
            // Add statistics
            const statisticsHtml = this.formatValidationStatistics(results.statistics);
            modalBody.innerHTML += statisticsHtml;
        }
        
        // Show modal
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();
    }
    
    /**
     * Create validation modal
     */
    createValidationModal(modalId) {
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.id = modalId;
        modal.tabIndex = -1;
        
        modal.innerHTML = `
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="bi bi-check2-circle me-2"></i>
                            Data Validation Results
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <!-- Validation results will be inserted here -->
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                        <button type="button" class="btn btn-primary" onclick="demoDataEditor.exportValidationReport()">
                            <i class="bi bi-download"></i> Export Report
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        return modal;
    }
    
    /**
     * Format validation statistics
     */
    formatValidationStatistics(statistics) {
        let html = '<div class="mt-4"><h6>Validation Statistics:</h6>';
        html += '<div class="row">';
        
        Object.entries(statistics).forEach(([type, stats]) => {
            if (stats.total > 0) {
                html += `
                    <div class="col-md-6 mb-3">
                        <div class="card">
                            <div class="card-body text-center">
                                <h6 class="card-title text-capitalize">${type}</h6>
                                <div class="row text-center">
                                    <div class="col-4">
                                        <div class="text-success">${stats.valid}</div>
                                        <small class="text-muted">Valid</small>
                                    </div>
                                    <div class="col-4">
                                        <div class="text-warning">${stats.withWarnings}</div>
                                        <small class="text-muted">Warnings</small>
                                    </div>
                                    <div class="col-4">
                                        <div class="text-danger">${stats.withErrors}</div>
                                        <small class="text-muted">Errors</small>
                                    </div>
                                </div>
                                <div class="mt-2">
                                    <small class="text-muted">Total: ${stats.total}</small>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            }
        });
        
        html += '</div></div>';
        return html;
    }
    
    /**
     * Export validation report
     */
    exportValidationReport() {
        try {
            const results = this.validationSystem.validateAllData();
            
            const report = {
                timestamp: new Date().toISOString(),
                summary: {
                    isValid: results.isValid,
                    totalErrors: results.errors.length,
                    totalWarnings: results.warnings.length
                },
                statistics: results.statistics,
                errors: results.errors,
                warnings: results.warnings,
                dataSnapshot: {
                    users: this.dataManager.getEntities('user').length,
                    events: this.dataManager.getEntities('event').length,
                    societies: this.dataManager.getEntities('society').length,
                    locations: this.dataManager.getEntities('location').length,
                    privacySettings: this.dataManager.getEntities('privacy').length
                }
            };
            
            this.dataManager.downloadJSON(report, 'uniconnect-validation-report.json');
            this.updateStatus('Validation report exported successfully', 'success');
            
        } catch (error) {
            console.error('Error exporting validation report:', error);
            this.updateStatus(`Error exporting validation report: ${error.message}`, 'error');
        }
    }
    
    /**
     * Render all entity lists
     */
    renderAllLists() {
        if (this.eventManager) this.eventManager.renderEventsList();
        if (this.userManager) this.userManager.renderUsersList();
        if (this.societyManager) this.societyManager.renderSocietiesList();
        if (this.locationManager) this.locationManager.renderLocationsList();
    }
    
    /**
     * Update status message
     */
    updateStatus(message, type = 'info') {
        this.dataManager.updateStatus(message, type);
    }
    
    /**
     * Get application statistics
     */
    getApplicationStatistics() {
        return {
            users: this.dataManager.getEntities('user').length,
            events: this.dataManager.getEntities('event').length,
            societies: this.dataManager.getEntities('society').length,
            locations: this.dataManager.getEntities('location').length,
            privacySettings: this.dataManager.getEntities('privacy').length,
            friendRequests: this.dataManager.getEntities('friendRequest').length
        };
    }
    
    /**
     * Clear all data (with confirmation)
     */
    clearAllData() {
        if (confirm('Are you sure you want to clear all data? This action cannot be undone.')) {
            this.dataManager.data = {
                users: [],
                events: [],
                societies: [],
                locations: [],
                privacySettings: [],
                friendRequests: []
            };
            
            this.dataManager.updateNextIds();
            this.renderAllLists();
            this.dataManager.updateUI();
            
            this.updateStatus('All data cleared successfully', 'success');
        }
    }
    
    /**
     * Import sample data
     */
    async importSampleData() {
        try {
            this.updateStatus('Creating sample data...', 'info');
            
            // Create sample users
            const sampleUsers = [
                { name: 'Andrea Fernandez', email: 'andrea.fernandez@student.uts.edu.au', course: 'Bachelor of Information Technology', year: '2nd Year', status: 'online' },
                { name: 'James Chen', email: 'james.chen@student.uts.edu.au', course: 'Bachelor of Computer Science', year: '3rd Year', status: 'away' },
                { name: 'Sophia Williams', email: 'sophia.williams@student.uts.edu.au', course: 'Bachelor of Engineering', year: '1st Year', status: 'online' }
            ];
            
            sampleUsers.forEach(userData => {
                const user = this.userManager.convertToUserFormat(userData);
                this.dataManager.addEntity('user', user);
                this.userManager.createPrivacySettings(user.id);
            });
            
            // Create sample locations
            const sampleLocations = [
                { name: 'CB02 Lecture Hall', building: 'CB02', room: '04.56', latitude: -33.8838, longitude: 151.2003, type: 'lecture_hall' },
                { name: 'Building 2 Lab', building: 'Building 2', room: 'Lab 1', latitude: -33.8838, longitude: 151.2003, type: 'lab' },
                { name: 'Library Study Space', building: 'Library', room: 'Level 3', latitude: -33.8837, longitude: 151.2006, type: 'study_space' }
            ];
            
            sampleLocations.forEach(locationData => {
                const location = this.locationManager.convertToLocationFormat(locationData);
                this.dataManager.addEntity('location', location);
            });
            
            // Create sample societies
            const sampleSocieties = [
                { name: 'UTS Programming Society', description: 'For students passionate about coding', category: 'technology', memberCount: 150 },
                { name: 'UTS Cultural Club', description: 'Celebrating diversity and culture', category: 'cultural', memberCount: 80 }
            ];
            
            sampleSocieties.forEach(societyData => {
                const society = this.societyManager.convertToSocietyFormat(societyData);
                this.dataManager.addEntity('society', society);
            });
            
            // Create sample events
            const users = this.dataManager.getEntities('user');
            const locations = this.dataManager.getEntities('location');
            
            if (users.length > 0 && locations.length > 0) {
                const sampleEvents = [
                    {
                        title: 'Interactive Design Workshop',
                        description: 'Hands-on workshop covering UX principles',
                        category: 'academic',
                        subType: 'workshop',
                        location: locations[0].id,
                        startDate: new Date().toISOString().split('T')[0],
                        startTime: '14:00',
                        endDate: new Date().toISOString().split('T')[0],
                        endTime: '16:00',
                        creator: users[0].id,
                        organizers: [],
                        attendees: users.slice(1).map(u => u.id),
                        privacy: 'university'
                    }
                ];
                
                sampleEvents.forEach(eventData => {
                    const event = this.eventManager.convertToEventV2(eventData);
                    this.dataManager.addEntity('event', event);
                });
            }
            
            this.renderAllLists();
            this.dataManager.updateUI();
            
            this.updateStatus('Sample data created successfully', 'success');
            
        } catch (error) {
            console.error('Error creating sample data:', error);
            this.updateStatus(`Error creating sample data: ${error.message}`, 'error');
        }
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    window.demoDataEditor = new DemoDataEditor();
});