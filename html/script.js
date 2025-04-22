// SouthVale RP Gang System - Main JS

let config = {
    serverName: 'SouthVale RP',
    logo: 'https://yourserver.com/logo.png',
    themeColor: '#3498db',
    backgroundOpacity: 0.85
};

// Main event listener
window.addEventListener('message', function(event) {
    const action = event.data.action;
    const data = event.data;

    switch (action) {
        case 'setConfig':
            config = data.config;
            applyThemeColor();
            break;
        case 'updateGangHUD':
            updateGangHUD(data);
            break;
        case 'gangInvite':
            showGangInvite(data);
            break;
        case 'openGangAdmin':
            loadPanel('gangadmin');
            break;
        case 'openGangPanel':
            loadPanel('gangpanel');
            break;
        case 'openLeaderboard':
            loadPanel('leaderboard');
            break;
        case 'setGangs':
            if (window.setGangsData) {
                window.setGangsData(data.gangs);
            }
            break;
        case 'setGangData':
            if (window.setGangPanelData) {
                window.setGangPanelData(data.gangData);
            }
            break;
        case 'setGangTurfs':
            if (window.setGangTurfs) {
                window.setGangTurfs(data.turfs);
            }
            break;
        case 'setLeaderboardData':
            if (window.setLeaderboardData) {
                window.setLeaderboardData(data.leaderboard);
            }
            break;
    }
});

// Apply theme color to UI elements
function applyThemeColor() {
    document.documentElement.style.setProperty('--theme-color', config.themeColor);
    document.documentElement.style.setProperty('--background-opacity', config.backgroundOpacity);
}

// Gang HUD Functions
function updateGangHUD(data) {
    const hudElement = document.getElementById('gang-hud');
    const nameElement = hudElement.querySelector('.gang-name');
    const rankElement = hudElement.querySelector('.gang-rank');

    if (data.show) {
        nameElement.textContent = data.gang.label;
        rankElement.textContent = data.gang.rank;
        
        // Apply gang color
        nameElement.style.color = data.gang.color || config.themeColor;
        
        hudElement.classList.remove('hidden');
    } else {
        hudElement.classList.add('hidden');
    }
}

// Gang Invite Functions
function showGangInvite(data) {
    const inviteElement = document.getElementById('gang-invite');
    const gangNameElement = document.getElementById('gang-invite-name');
    const inviterElement = document.getElementById('gang-invite-from');
    
    gangNameElement.textContent = data.gangName;
    inviterElement.textContent = data.inviterName;
    
    inviteElement.classList.remove('hidden');
    
    // Auto-hide after 30 seconds
    setTimeout(() => {
        inviteElement.classList.add('hidden');
    }, 30000);
}

// Load panel HTML content
function loadPanel(panelName) {
    const mainContainer = document.getElementById('main-container');
    
    fetch(`${panelName}.html`)
        .then(response => response.text())
        .then(html => {
            mainContainer.innerHTML = html;
            mainContainer.classList.remove('hidden');
            
            // Load additional scripts
            const script = document.createElement('script');
            script.src = `${panelName}.js`;
            document.body.appendChild(script);
            
            applyThemeColor();
        });
}

// Close panel
function closePanel() {
    const mainContainer = document.getElementById('main-container');
    mainContainer.classList.add('hidden');
    mainContainer.innerHTML = '';
    
    // Notify FiveM client that panel is closed
    fetch('https://sv-gangs/closePanel', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// Respond to gang invite
document.getElementById('accept-invite').addEventListener('click', function() {
    fetch('https://sv-gangs/respondToGangInvite', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            accept: true
        })
    });
    
    document.getElementById('gang-invite').classList.add('hidden');
});

document.getElementById('decline-invite').addEventListener('click', function() {
    fetch('https://sv-gangs/respondToGangInvite', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            accept: false
        })
    });
    
    document.getElementById('gang-invite').classList.add('hidden');
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    applyThemeColor();
});
