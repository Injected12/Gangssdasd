// SouthVale RP Gang System - Gang Panel JS

// Global variables
let gangData = null;
let gangTurfs = [];

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Tab switching
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', function() {
            // Remove active class from all tabs and content
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            
            // Add active class to clicked tab and corresponding content
            this.classList.add('active');
            document.getElementById(`${this.dataset.tab}-tab`).classList.add('active');
            
            // Special actions for tabs
            if (this.dataset.tab === 'turfs') {
                refreshTurfs();
            } else if (this.dataset.tab === 'members') {
                refreshMembers();
            }
        });
    });
    
    // Gang settings form
    document.getElementById('gang-settings-form').addEventListener('submit', function(e) {
        e.preventDefault();
        saveGangSettings();
    });
    
    // Leave gang button
    document.getElementById('leave-gang-btn').addEventListener('click', function() {
        showConfirmModal('Leave Gang', 
            'Are you sure you want to leave this gang? This action cannot be undone.',
            function() {
                leaveGang();
            }
        );
    });
    
    // Initial load of online players
    loadOnlinePlayers();
});

// Set gang panel data from main script
window.setGangPanelData = function(data) {
    gangData = data;
    updateGangPanel();
};

// Set gang turfs from main script
window.setGangTurfs = function(data) {
    gangTurfs = data;
    updateTurfsList();
};

// Update gang panel with data
function updateGangPanel() {
    if (!gangData) return;
    
    // Update gang name in header
    document.getElementById('gang-name').textContent = gangData.label;
    
    // Update settings form
    document.getElementById('gang-label').value = gangData.label;
    document.getElementById('gang-color').value = gangData.color;
    
    // Update members list
    updateMembersList();
}

// Update members list
function updateMembersList() {
    const tableBody = document.getElementById('members-list');
    const loadingElement = document.getElementById('members-loading');
    
    // Hide loading spinner
    loadingElement.classList.add('hidden');
    
    // Clear table
    tableBody.innerHTML = '';
    
    if (!gangData.members || gangData.members.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="4" class="empty-data">No members found</td></tr>';
        return;
    }
    
    // Add members to table
    gangData.members.forEach(member => {
        const row = document.createElement('tr');
        
        // Get player initials for avatar
        const nameParts = member.name.split(' ');
        let initials = '';
        if (nameParts.length >= 2) {
            initials = nameParts[0].charAt(0) + nameParts[1].charAt(0);
        } else {
            initials = member.name.substring(0, 2);
        }
        
        const memberAvatar = `<div class="member-avatar">${initials}</div>`;
        const statusClass = member.isOnline ? 'status-online' : 'status-offline';
        const statusLabel = member.isOnline ? 'Online' : 'Offline';
        
        const canManage = gangData.grades && gangData.grades.length > 0 && 
                         gangData.grades[0].level <= member.gradeLevel;
        
        let actionsHtml = '';
        
        // Only show actions if player has permission (is high rank)
        if (canManage) {
            actionsHtml = `
                <div class="actions">
                    <button class="action-btn promote" data-citizenid="${member.citizenid}">
                        <i class="fas fa-arrow-up"></i> Promote
                    </button>
                    <button class="action-btn demote" data-citizenid="${member.citizenid}">
                        <i class="fas fa-arrow-down"></i> Demote
                    </button>
                    <button class="action-btn delete" data-citizenid="${member.citizenid}">
                        <i class="fas fa-user-minus"></i> Kick
                    </button>
                </div>
            `;
        }
        
        row.innerHTML = `
            <td>
                <div class="member-info">
                    ${memberAvatar}
                    <span>${member.name}</span>
                </div>
            </td>
            <td>${member.gradeName}</td>
            <td><span class="status ${statusClass}">${statusLabel}</span></td>
            <td>${actionsHtml}</td>
        `;
        
        tableBody.appendChild(row);
    });
    
    // Add event listeners to action buttons
    document.querySelectorAll('#members-list .action-btn.promote').forEach(btn => {
        btn.addEventListener('click', function() {
            promoteGangMember(this.dataset.citizenid);
        });
    });
    
    document.querySelectorAll('#members-list .action-btn.demote').forEach(btn => {
        btn.addEventListener('click', function() {
            demoteGangMember(this.dataset.citizenid);
        });
    });
    
    document.querySelectorAll('#members-list .action-btn.delete').forEach(btn => {
        btn.addEventListener('click', function() {
            const citizenid = this.dataset.citizenid;
            const memberData = gangData.members.find(m => m.citizenid === citizenid);
            
            if (memberData) {
                showConfirmModal('Kick Member', 
                    `Are you sure you want to kick ${memberData.name} from the gang?`,
                    function() {
                        kickGangMember(citizenid);
                    }
                );
            }
        });
    });
}

// Update turfs list
function updateTurfsList() {
    const tableBody = document.getElementById('turfs-list');
    const loadingElement = document.getElementById('turfs-loading');
    
    // Hide loading spinner
    loadingElement.classList.add('hidden');
    
    // Clear table
    tableBody.innerHTML = '';
    
    if (!gangTurfs || gangTurfs.length === 0) {
        // Show empty state
        tableBody.innerHTML = `
            <tr>
                <td colspan="2">
                    <div class="empty-state">
                        <i class="fas fa-map-marked-alt"></i>
                        <p>Your gang doesn't control any turfs yet.</p>
                        <p>Go to a turf location and press E to start capturing it.</p>
                    </div>
                </td>
            </tr>
        `;
        return;
    }
    
    // Add turfs to table
    gangTurfs.forEach(turf => {
        const row = document.createElement('tr');
        
        // Format date
        const capturedDate = new Date(turf.last_captured);
        const formattedDate = capturedDate.toLocaleDateString() + ' ' + 
                              capturedDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        
        row.innerHTML = `
            <td>${turf.name}</td>
            <td>${formattedDate}</td>
        `;
        
        tableBody.appendChild(row);
    });
}

// Load online players
function loadOnlinePlayers() {
    const tableBody = document.getElementById('online-players-list');
    const loadingElement = document.getElementById('online-players-loading');
    
    // Show loading spinner
    loadingElement.classList.remove('hidden');
    
    // Clear table
    tableBody.innerHTML = '';
    
    // Fetch online players from server
    fetch('https://sv-gangs/getOnlinePlayers', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(players => {
        // Hide loading spinner
        loadingElement.classList.add('hidden');
        
        if (!players || players.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="2" class="empty-data">No players available to invite</td></tr>';
            return;
        }
        
        // Add players to table
        players.forEach(player => {
            const row = document.createElement('tr');
            
            row.innerHTML = `
                <td>${player.name}</td>
                <td>
                    <button class="invite-btn" data-id="${player.id}">
                        <i class="fas fa-user-plus"></i> Invite
                    </button>
                </td>
            `;
            
            tableBody.appendChild(row);
        });
        
        // Add event listeners to invite buttons
        document.querySelectorAll('.invite-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                invitePlayer(this.dataset.id);
            });
        });
    });
}

// Promote gang member
function promoteGangMember(citizenid) {
    // Send to server
    fetch('https://sv-gangs/promoteGangMember', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ citizenid: citizenid })
    }).then(() => {
        refreshMembers();
    });
}

// Demote gang member
function demoteGangMember(citizenid) {
    // Send to server
    fetch('https://sv-gangs/demoteGangMember', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ citizenid: citizenid })
    }).then(() => {
        refreshMembers();
    });
}

// Kick gang member
function kickGangMember(citizenid) {
    // Send to server
    fetch('https://sv-gangs/kickFromGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ citizenid: citizenid })
    }).then(() => {
        refreshMembers();
    });
}

// Invite player to gang
function invitePlayer(playerId) {
    // Send to server
    fetch('https://sv-gangs/inviteToGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ playerId: playerId })
    }).then(() => {
        // Refresh online players list
        loadOnlinePlayers();
    });
}

// Save gang settings
function saveGangSettings() {
    const label = document.getElementById('gang-label').value.trim();
    const color = document.getElementById('gang-color').value;
    
    // Validate input
    if (!label) {
        showNotification('Please fill in the gang name.', 'error');
        return;
    }
    
    // Send to server
    fetch('https://sv-gangs/updateGangInfo', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ 
            label: label,
            color: color
        })
    }).then(() => {
        showNotification('Gang settings updated successfully!', 'success');
        
        // Update local data
        gangData.label = label;
        gangData.color = color;
        
        // Update UI
        document.getElementById('gang-name').textContent = label;
    });
}

// Leave gang
function leaveGang() {
    // Send to server
    fetch('https://sv-gangs/leaveGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(() => {
        // Close panel (will be handled by the client script)
        closePanel();
    });
}

// Refresh members
function refreshMembers() {
    // Show loading spinner
    document.getElementById('members-loading').classList.remove('hidden');
    
    // Fetch gang data from server
    fetch('https://sv-gangs/refreshGangData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// Refresh turfs
function refreshTurfs() {
    // Show loading spinner
    document.getElementById('turfs-loading').classList.remove('hidden');
    
    // Fetch turfs from server
    fetch('https://sv-gangs/getGangTurfs', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// Show confirm modal
function showConfirmModal(title, message, confirmCallback) {
    // Create modal
    const modal = document.createElement('div');
    modal.className = 'modal';
    
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">${title}</div>
            <div class="modal-body">${message}</div>
            <div class="modal-actions">
                <button class="btn btn-decline" id="modal-cancel">Cancel</button>
                <button class="btn btn-accept" id="modal-confirm">Confirm</button>
            </div>
        </div>
    `;
    
    // Add to body
    document.body.appendChild(modal);
    
    // Add event listeners
    document.getElementById('modal-cancel').addEventListener('click', function() {
        modal.remove();
    });
    
    document.getElementById('modal-confirm').addEventListener('click', function() {
        confirmCallback();
        modal.remove();
    });
}

// Show notification
function showNotification(message, type) {
    // This is a placeholder function
    // In a real FiveM UI, notifications would be handled by the game
    console.log(`${type.toUpperCase()}: ${message}`);
}
