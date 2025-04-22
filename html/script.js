// Main script for SouthVale RP Gang System

// Global variables
let activePanel = null;
let gangs = [];
let gangData = null;
let turfs = [];
let leaderboard = [];
let theme = null;

// Apply theme color from Config
function applyThemeColor() {
    const themeColor = theme || '#3498db';
    document.documentElement.style.setProperty('--primary-color', themeColor);
}

// Show/Hide Gang HUD
function updateGangHUD(data) {
    const gangHUD = document.getElementById('gang-hud');
    
    if (data.show) {
        gangHUD.classList.remove('hidden');
        
        const gangName = gangHUD.querySelector('.gang-name');
        const gangRank = gangHUD.querySelector('.gang-rank');
        
        gangName.textContent = data.gang.label;
        gangRank.textContent = data.gang.rank;
        
        // Apply gang color if provided
        if (data.gang.color) {
            gangName.style.color = data.gang.color;
        }
    } else {
        gangHUD.classList.add('hidden');
    }
}

// Show gang invite notification
function showGangInvite(data) {
    const gangInvite = document.getElementById('gang-invite');
    gangInvite.classList.remove('hidden');
    
    document.getElementById('gang-invite-name').textContent = data.gangName;
    document.getElementById('gang-invite-from').textContent = data.inviterName;
    
    // Handle accept button
    document.getElementById('accept-invite').onclick = function() {
        gangInvite.classList.add('hidden');
        fetch('https://sv-gangs/acceptInvite', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    };
    
    // Handle decline button
    document.getElementById('decline-invite').onclick = function() {
        gangInvite.classList.add('hidden');
        fetch('https://sv-gangs/declineInvite', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    };
}

// Load panel (admin, gang panel, leaderboard)
function loadPanel(panelName) {
    const mainContainer = document.getElementById('main-container');
    mainContainer.classList.remove('hidden');
    
    // First check if we need to load HTML content
    fetch(`html/${panelName}.html`)
        .then(response => response.text())
        .then(html => {
            mainContainer.innerHTML = html;
            
            // Set active panel
            activePanel = panelName;
            
            // Initialize panel scripts
            if (panelName === 'gangadmin') {
                // Load gangadmin.js if not already loaded
                if (!window.initializeCreateGangForm) {
                    loadScript('html/gangadmin.js')
                        .then(() => {
                            // Initialize admin panel
                            if (window.gangAdminInit) {
                                window.gangAdminInit();
                            }
                        });
                } else if (window.gangAdminInit) {
                    window.gangAdminInit();
                }
            } 
            else if (panelName === 'gangpanel') {
                // Load gangpanel.js if not already loaded
                if (!window.updateGangPanel) {
                    loadScript('html/gangpanel.js')
                        .then(() => {
                            // Load gang panel data
                            loadGangPanelData();
                        });
                } else {
                    loadGangPanelData();
                }
            }
            else if (panelName === 'leaderboard') {
                // Load leaderboard.js if not already loaded
                if (!window.updateLeaderboard) {
                    loadScript('html/leaderboard.js')
                        .then(() => {
                            // Load leaderboard data
                            loadLeaderboardData();
                        });
                } else {
                    loadLeaderboardData();
                }
            }
            
            // Setup tab navigation
            setupTabNavigation();
            
            // Setup close button
            setupCloseButton();
        })
        .catch(error => {
            console.error(`Error loading panel ${panelName}:`, error);
        });
}

// Helper function to load scripts
function loadScript(src) {
    return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = src;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

// Load gang panel data
function loadGangPanelData() {
    fetch('https://sv-gangs/getGangData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (window.setGangPanelData) {
            window.setGangPanelData(data);
        }
    })
    .catch(error => {
        console.error('Error loading gang panel data:', error);
    });
    
    // Load gang turf data
    fetch('https://sv-gangs/getGangTurfs', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (window.setGangTurfs) {
            window.setGangTurfs(data.turfs);
        }
    })
    .catch(error => {
        console.error('Error loading gang turf data:', error);
    });
}

// Load leaderboard data
function loadLeaderboardData() {
    fetch('https://sv-gangs/getLeaderboardData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (window.setLeaderboardData) {
            window.setLeaderboardData(data.leaderboard);
        }
    })
    .catch(error => {
        console.error('Error loading leaderboard data:', error);
    });
}

// Setup tab navigation
function setupTabNavigation() {
    const tabs = document.querySelectorAll('.tab');
    if (tabs.length > 0) {
        tabs.forEach(tab => {
            tab.addEventListener('click', function() {
                // Remove active class from all tabs
                document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                
                // Add active class to clicked tab
                this.classList.add('active');
                
                // Hide all tab content
                document.querySelectorAll('.tab-content').forEach(content => {
                    content.classList.remove('active');
                });
                
                // Show selected tab content
                const tabId = this.getAttribute('data-tab');
                const tabContent = document.getElementById(tabId + '-tab');
                if (tabContent) {
                    tabContent.classList.add('active');
                }
            });
        });
    }
}

// Setup close button
function setupCloseButton() {
    const closeButton = document.querySelector('.panel-close');
    if (closeButton) {
        closeButton.addEventListener('click', closePanel);
    }
}

// Close panel
function closePanel() {
    const mainContainer = document.getElementById('main-container');
    mainContainer.classList.add('hidden');
    mainContainer.innerHTML = '';
    activePanel = null;
    
    // Notify resource that panel was closed
    fetch('https://sv-gangs/closePanel', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Handle keypress events (ESC to close panel)
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && activePanel) {
        closePanel();
    }
});

// Listen for NUI messages from the game
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openPanel') {
        loadPanel(data.panel);
    } 
    else if (data.action === 'closePanel') {
        closePanel();
    }
    else if (data.action === 'updateGangHUD') {
        updateGangHUD(data);
    }
    else if (data.action === 'setThemeColor') {
        theme = data.color;
        applyThemeColor();
    }
    else if (data.action === 'gangInvite') {
        showGangInvite(data);
    }
});

// On document load
document.addEventListener('DOMContentLoaded', function() {
    // Apply theme color
    applyThemeColor();
    
    // Check if panel should be automatically loaded (for development/testing)
    const urlParams = new URLSearchParams(window.location.search);
    const panel = urlParams.get('panel');
    
    if (panel) {
        loadPanel(panel);
    }
});