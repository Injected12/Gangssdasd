// Admin Panel Functionality

// Initialize admin panel
document.addEventListener('DOMContentLoaded', function() {
    // Create gang form submission
    const createGangForm = document.getElementById('create-gang-form');
    if (createGangForm) {
        // Add default rank inputs
        populateDefaultRanks();
        
        createGangForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const gangName = document.getElementById('gang-name-input').value;
            const gangColor = document.getElementById('gang-color-input').value;
            
            if (!gangName || gangName.length < 2) {
                alert('Gang name must be at least 2 characters long');
                return;
            }
            
            // Create gang data
            const gangData = {
                name: gangName,
                color: gangColor
            };
            
            // Send to client
            fetch('https://sv-gangsystem/createGang', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(gangData)
            });
            
            // Reset form
            createGangForm.reset();
            
            // Refresh data after a brief delay
            setTimeout(() => {
                refreshAdminData();
            }, 500);
        });
    }
});

// Update Admin UI with data
function updateAdminUI() {
    if (!adminData) return;
    
    // Update gangs list
    const gangListElement = document.getElementById('admin-gang-list');
    if (gangListElement) {
        gangListElement.innerHTML = '';
        
        if (adminData.gangs && adminData.gangs.length > 0) {
            adminData.gangs.forEach(gang => {
                const gangItem = document.createElement('div');
                gangItem.className = 'gang-item';
                
                gangItem.innerHTML = `
                    <div class="gang-info">
                        <div class="gang-name">
                            <span class="color-badge" style="background-color: ${gang.color}"></span>
                            ${gang.name}
                        </div>
                        <div class="gang-details">
                            Members: ${gang.member_count || 0} | Points: ${gang.points || 0}
                        </div>
                    </div>
                    <div class="gang-actions">
                        <button class="btn btn-danger delete-gang" data-id="${gang.id}">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                `;
                
                gangListElement.appendChild(gangItem);
            });
            
            // Add event listeners for delete buttons
            const deleteButtons = document.querySelectorAll('.delete-gang');
            deleteButtons.forEach(btn => {
                btn.addEventListener('click', function() {
                    const gangId = this.getAttribute('data-id');
                    if (confirm('Are you sure you want to delete this gang?')) {
                        deleteGang(gangId);
                    }
                });
            });
        } else {
            gangListElement.innerHTML = '<div class="empty-message">No gangs found</div>';
        }
    }
    
    // Update admin leaderboard
    updateLeaderboardTable('leaderboard-body');
    
    // Update turfs table
    updateTurfsTable('turf-body');
}

// Delete gang
function deleteGang(gangId) {
    fetch('https://sv-gangsystem/deleteGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ gangId: gangId })
    });
    
    // Refresh data after a brief delay
    setTimeout(() => {
        refreshAdminData();
    }, 500);
}

// Populate default ranks
function populateDefaultRanks() {
    const ranksContainer = document.getElementById('ranks-container');
    if (!ranksContainer) return;
    
    // Default ranks from config
    const defaultRanks = [
        {name: "Recruit", level: 1},
        {name: "Member", level: 2},
        {name: "Veteran", level: 3},
        {name: "Lieutenant", level: 4},
        {name: "Leader", level: 5}
    ];
    
    ranksContainer.innerHTML = '';
    defaultRanks.forEach(rank => {
        const rankDiv = document.createElement('div');
        rankDiv.className = 'rank-item';
        rankDiv.innerHTML = `
            <div class="form-group">
                <label>Rank ${rank.level} (${rank.name})</label>
                <input type="text" value="${rank.name}" disabled>
            </div>
        `;
        ranksContainer.appendChild(rankDiv);
    });
}

// Refresh admin data
function refreshAdminData() {
    fetch('https://sv-gangsystem/refreshAdminData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Update turfs table
function updateTurfsTable(tableId) {
    const tableBody = document.getElementById(tableId);
    if (!tableBody || !adminData || !adminData.turfs) return;
    
    tableBody.innerHTML = '';
    
    adminData.turfs.forEach(turf => {
        const row = document.createElement('tr');
        
        // Check if turf is on cooldown
        const now = new Date();
        const cooldownUntil = turf.cooldown_until ? new Date(turf.cooldown_until) : null;
        const isOnCooldown = cooldownUntil && cooldownUntil > now;
        
        row.innerHTML = `
            <td>${turf.turf_name}</td>
            <td>
                ${turf.gang_name ? 
                    `<span class="color-badge" style="background-color: ${turf.gang_color}"></span>${turf.gang_name}` : 
                    'Unclaimed'}
            </td>
            <td>${turf.captured_at ? formatDate(turf.captured_at) : 'Never'}</td>
            <td>${isOnCooldown ? 
                `<span style="color: #F44336;">On Cooldown (${Math.ceil((cooldownUntil - now) / 1000 / 60)} min)</span>` : 
                '<span style="color: #66BB6A;">Available</span>'}
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}
