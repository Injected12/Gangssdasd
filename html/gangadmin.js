// SouthVale RP Gang System - Gang Admin Panel JS

// Global variables
let gangs = [];
let currentGang = null;
let searchTimer = null;
let searchResults = [];
let defaultRanks = [
    { name: "Boss", level: 100 },
    { name: "Underboss", level: 90 },
    { name: "Capo", level: 80 },
    { name: "Lieutenant", level: 70 },
    { name: "Soldier", level: 50 },
    { name: "Associate", level: 10 },
    { name: "Recruit", level: 0 }
];

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
            if (this.dataset.tab === 'gang-list' || this.dataset.tab === 'leaderboard') {
                refreshGangList();
            }
        });
    });
    
    // Create gang form
    document.getElementById('create-gang-form').addEventListener('submit', function(e) {
        e.preventDefault();
        createGang();
    });
    
    // Add rank button
    document.getElementById('add-rank-btn').addEventListener('click', function() {
        addRankField();
    });
    
    // Edit rank button
    document.getElementById('edit-add-rank-btn').addEventListener('click', function() {
        addEditRankField();
    });
    
    // Gang selector
    document.getElementById('select-gang').addEventListener('change', function() {
        const gangName = this.value;
        if (gangName) {
            selectGangToEdit(gangName);
        } else {
            document.getElementById('manage-gang-content').classList.add('hidden');
        }
    });
    
    // Update gang button
    document.getElementById('update-gang-btn').addEventListener('click', function() {
        updateGang();
    });
    
    // Delete gang button
    document.getElementById('delete-gang-btn').addEventListener('click', function() {
        showConfirmModal('Delete Gang', 
            `Are you sure you want to delete the gang "${currentGang.label}"? This action cannot be undone.`,
            function() {
                deleteGang();
            }
        );
    });
    
    // Search player input
    document.getElementById('search-player').addEventListener('input', function() {
        const searchTerm = this.value.trim();
        
        clearTimeout(searchTimer);
        
        if (searchTerm.length < 2) {
            document.getElementById('search-results').classList.add('hidden');
            return;
        }
        
        searchTimer = setTimeout(function() {
            searchPlayers(searchTerm);
        }, 500);
    });
    
    // Initialize create gang form with default ranks
    initializeCreateGangForm();
});

// Set gangs data from main script
window.setGangsData = function(data) {
    gangs = data;
    renderGangsList();
    populateGangSelector();
    renderLeaderboard();
};

// Initialize create gang form
function initializeCreateGangForm() {
    const container = document.getElementById('gang-ranks-container');
    container.innerHTML = '';
    
    defaultRanks.forEach((rank, index) => {
        container.appendChild(createRankElement(index, rank.name, rank.level));
    });
}

// Create rank input field
function createRankElement(index, name, level) {
    const div = document.createElement('div');
    div.className = 'rank-item';
    
    const numberSpan = document.createElement('span');
    numberSpan.className = 'rank-item-number';
    numberSpan.textContent = index + 1;
    
    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.className = 'form-control rank-name';
    nameInput.placeholder = 'Rank Name';
    nameInput.value = name || '';
    nameInput.required = true;
    
    const levelInput = document.createElement('input');
    levelInput.type = 'number';
    levelInput.className = 'form-control rank-level';
    levelInput.placeholder = 'Level';
    levelInput.min = '0';
    levelInput.max = '100';
    levelInput.value = level || '0';
    levelInput.required = true;
    
    const removeBtn = document.createElement('button');
    removeBtn.type = 'button';
    removeBtn.className = 'remove-rank-btn';
    removeBtn.innerHTML = '<i class="fas fa-trash"></i>';
    removeBtn.addEventListener('click', function() {
        div.remove();
        updateRankNumbers();
    });
    
    div.appendChild(numberSpan);
    div.appendChild(nameInput);
    div.appendChild(levelInput);
    div.appendChild(removeBtn);
    
    return div;
}

// Add new rank field
function addRankField() {
    const container = document.getElementById('gang-ranks-container');
    const rankCount = container.querySelectorAll('.rank-item').length;
    
    container.appendChild(createRankElement(rankCount));
}

// Add new rank field for editing
function addEditRankField() {
    const container = document.getElementById('edit-gang-ranks-container');
    const rankCount = container.querySelectorAll('.rank-item').length;
    
    container.appendChild(createRankElement(rankCount));
}

// Update rank numbers after removal
function updateRankNumbers() {
    document.querySelectorAll('#gang-ranks-container .rank-item-number').forEach((el, idx) => {
        el.textContent = idx + 1;
    });
    
    document.querySelectorAll('#edit-gang-ranks-container .rank-item-number').forEach((el, idx) => {
        el.textContent = idx + 1;
    });
}

// Create gang
function createGang() {
    const name = document.getElementById('gang-name').value.trim();
    const label = document.getElementById('gang-label').value.trim();
    const color = document.getElementById('gang-color').value;
    
    // Validate input
    if (!name || !label) {
        showNotification('Please fill in all required fields.', 'error');
        return;
    }
    
    // Get ranks
    const ranks = [];
    document.querySelectorAll('#gang-ranks-container .rank-item').forEach(item => {
        const nameInput = item.querySelector('.rank-name');
        const levelInput = item.querySelector('.rank-level');
        
        if (nameInput && levelInput) {
            ranks.push({
                name: nameInput.value,
                level: parseInt(levelInput.value)
            });
        }
    });
    
    // Sort ranks by level (descending)
    ranks.sort((a, b) => b.level - a.level);
    
    // Create gang data
    const gangData = {
        name: name,
        label: label,
        color: color,
        ranks: ranks
    };
    
    // Send to server
    fetch('https://sv-gangs/createGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(gangData)
    }).then(() => {
        showNotification('Gang created successfully!', 'success');
        resetCreateGangForm();
        
        // Switch to gang list tab
        document.querySelector('.tab[data-tab="gang-list"]').click();
    });
}

// Reset create gang form
function resetCreateGangForm() {
    document.getElementById('gang-name').value = '';
    document.getElementById('gang-label').value = '';
    document.getElementById('gang-color').value = '#3498db';
    
    // Reset ranks
    initializeCreateGangForm();
}

// Render gangs list
function renderGangsList() {
    const tableBody = document.getElementById('gangs-list');
    const loadingElement = document.getElementById('gangs-loading');
    
    // Hide loading spinner
    loadingElement.classList.add('hidden');
    
    // Clear table
    tableBody.innerHTML = '';
    
    if (gangs.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td colspan="4" style="text-align: center;">No gangs found</td>';
        tableBody.appendChild(row);
        return;
    }
    
    // Add gangs to table
    gangs.forEach(gang => {
        const row = document.createElement('tr');
        
        const colorPreview = `<span class="color-preview" style="background-color: ${gang.color}"></span>`;
        
        row.innerHTML = `
            <td>${colorPreview}${gang.label} <small>(${gang.name})</small></td>
            <td>${gang.memberCount}</td>
            <td>${gang.turfs}</td>
            <td>
                <div class="actions">
                    <button class="action-btn edit" data-gang="${gang.name}">
                        <i class="fas fa-edit"></i> Edit
                    </button>
                    <button class="action-btn delete" data-gang="${gang.name}">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </div>
            </td>
        `;
        
        tableBody.appendChild(row);
    });
    
    // Add event listeners to action buttons
    document.querySelectorAll('#gangs-list .action-btn.edit').forEach(btn => {
        btn.addEventListener('click', function() {
            const gangName = this.dataset.gang;
            
            // Switch to manage gang tab
            document.querySelector('.tab[data-tab="manage-gang"]').click();
            
            // Set gang selector value
            document.getElementById('select-gang').value = gangName;
            
            // Load gang data
            selectGangToEdit(gangName);
        });
    });
    
    document.querySelectorAll('#gangs-list .action-btn.delete').forEach(btn => {
        btn.addEventListener('click', function() {
            const gangName = this.dataset.gang;
            const gangData = gangs.find(g => g.name === gangName);
            
            if (gangData) {
                showConfirmModal('Delete Gang', 
                    `Are you sure you want to delete the gang "${gangData.label}"? This action cannot be undone.`,
                    function() {
                        deleteGangByName(gangName);
                    }
                );
            }
        });
    });
}

// Populate gang selector
function populateGangSelector() {
    const select = document.getElementById('select-gang');
    
    // Keep the first option
    select.innerHTML = '<option value="">-- Select Gang --</option>';
    
    // Add gangs to selector
    gangs.forEach(gang => {
        const option = document.createElement('option');
        option.value = gang.name;
        option.textContent = gang.label;
        select.appendChild(option);
    });
}

// Select gang to edit
function selectGangToEdit(gangName) {
    // Find gang data
    const gangData = gangs.find(g => g.name === gangName);
    
    if (!gangData) {
        showNotification('Gang not found.', 'error');
        return;
    }
    
    currentGang = gangData;
    
    // Populate form
    document.getElementById('edit-gang-label').value = gangData.label;
    document.getElementById('edit-gang-color').value = gangData.color;
    
    // Populate ranks
    const ranksContainer = document.getElementById('edit-gang-ranks-container');
    ranksContainer.innerHTML = '';
    
    gangData.grades.forEach((rank, index) => {
        ranksContainer.appendChild(createRankElement(index, rank.name, rank.level));
    });
    
    // Populate members table
    renderGangMembers();
    
    // Populate rank selector for new members
    populateRankSelector();
    
    // Show edit section
    document.getElementById('manage-gang-content').classList.remove('hidden');
}

// Render gang members
function renderGangMembers() {
    const tableBody = document.getElementById('gang-members-list');
    
    // Clear table
    tableBody.innerHTML = '';
    
    if (!currentGang || !currentGang.members || currentGang.members.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td colspan="4" style="text-align: center;">No members found</td>';
        tableBody.appendChild(row);
        return;
    }
    
    // Add members to table
    currentGang.members.forEach(member => {
        const row = document.createElement('tr');
        
        const statusClass = member.isOnline ? 'status-online' : 'status-offline';
        const statusLabel = member.isOnline ? 'Online' : 'Offline';
        
        row.innerHTML = `
            <td>${member.name} <small>(${member.citizenid})</small></td>
            <td>${member.gradeName}</td>
            <td><span class="status ${statusClass}">${statusLabel}</span></td>
            <td>
                <div class="actions">
                    <button class="action-btn promote" data-citizenid="${member.citizenid}">
                        <i class="fas fa-arrow-up"></i> Promote
                    </button>
                    <button class="action-btn demote" data-citizenid="${member.citizenid}">
                        <i class="fas fa-arrow-down"></i> Demote
                    </button>
                    <button class="action-btn delete" data-citizenid="${member.citizenid}">
                        <i class="fas fa-user-minus"></i> Remove
                    </button>
                </div>
            </td>
        `;
        
        tableBody.appendChild(row);
    });
    
    // Add event listeners to action buttons
    document.querySelectorAll('#gang-members-list .action-btn.promote').forEach(btn => {
        btn.addEventListener('click', function() {
            promoteGangMember(this.dataset.citizenid);
        });
    });
    
    document.querySelectorAll('#gang-members-list .action-btn.demote').forEach(btn => {
        btn.addEventListener('click', function() {
            demoteGangMember(this.dataset.citizenid);
        });
    });
    
    document.querySelectorAll('#gang-members-list .action-btn.delete').forEach(btn => {
        btn.addEventListener('click', function() {
            const citizenid = this.dataset.citizenid;
            const memberData = currentGang.members.find(m => m.citizenid === citizenid);
            
            if (memberData) {
                showConfirmModal('Remove Member', 
                    `Are you sure you want to remove ${memberData.name} from the gang?`,
                    function() {
                        removeGangMember(citizenid);
                    }
                );
            }
        });
    });
}

// Populate rank selector
function populateRankSelector() {
    const select = document.getElementById('player-rank');
    
    // Clear selector
    select.innerHTML = '';
    
    // Add ranks to selector
    if (currentGang && currentGang.grades) {
        currentGang.grades.forEach(rank => {
            const option = document.createElement('option');
            option.value = rank.level;
            option.textContent = rank.name;
            select.appendChild(option);
        });
    }
}

// Update gang
function updateGang() {
    if (!currentGang) return;
    
    const label = document.getElementById('edit-gang-label').value.trim();
    const color = document.getElementById('edit-gang-color').value;
    
    // Validate input
    if (!label) {
        showNotification('Please fill in all required fields.', 'error');
        return;
    }
    
    // Get ranks
    const ranks = [];
    document.querySelectorAll('#edit-gang-ranks-container .rank-item').forEach(item => {
        const nameInput = item.querySelector('.rank-name');
        const levelInput = item.querySelector('.rank-level');
        
        if (nameInput && levelInput) {
            ranks.push({
                name: nameInput.value,
                level: parseInt(levelInput.value)
            });
        }
    });
    
    // Sort ranks by level (descending)
    ranks.sort((a, b) => b.level - a.level);
    
    // Create gang data
    const gangData = {
        name: currentGang.name,
        label: label,
        color: color,
        ranks: ranks
    };
    
    // Send to server
    fetch('https://sv-gangs/updateGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(gangData)
    }).then(() => {
        showNotification('Gang updated successfully!', 'success');
        refreshGangList();
    });
}

// Delete gang
function deleteGang() {
    if (!currentGang) return;
    
    deleteGangByName(currentGang.name);
}

// Delete gang by name
function deleteGangByName(gangName) {
    // Send to server
    fetch('https://sv-gangs/deleteGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ name: gangName })
    }).then(() => {
        showNotification('Gang deleted successfully!', 'success');
        refreshGangList();
        
        // Reset manage gang tab
        document.getElementById('select-gang').value = '';
        document.getElementById('manage-gang-content').classList.add('hidden');
        currentGang = null;
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
        showNotification('Member promoted successfully!', 'success');
        refreshGangData();
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
        showNotification('Member demoted successfully!', 'success');
        refreshGangData();
    });
}

// Remove gang member
function removeGangMember(citizenid) {
    // Send to server
    fetch('https://sv-gangs/removeMemberFromGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ gangName: currentGang.name, citizenid: citizenid })
    }).then(() => {
        showNotification('Member removed successfully!', 'success');
        refreshGangData();
    });
}

// Search players
function searchPlayers(query) {
    // Send to server
    fetch('https://sv-gangs/searchPlayers', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ query: query })
    })
    .then(resp => resp.json())
    .then(data => {
        searchResults = data;
        renderSearchResults();
    });
}

// Render search results
function renderSearchResults() {
    const resultsContainer = document.getElementById('search-results');
    const resultsList = document.getElementById('search-results-list');
    
    // Clear list
    resultsList.innerHTML = '';
    
    if (searchResults.length === 0) {
        resultsContainer.classList.add('hidden');
        return;
    }
    
    // Add results to list
    searchResults.forEach(player => {
        const row = document.createElement('tr');
        
        row.innerHTML = `
            <td>${player.name}</td>
            <td>${player.citizenid}</td>
            <td>
                <button class="add-player-btn" data-citizenid="${player.citizenid}">
                    <i class="fas fa-plus"></i> Add
                </button>
            </td>
        `;
        
        resultsList.appendChild(row);
    });
    
    // Add event listeners
    document.querySelectorAll('.add-player-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const citizenid = this.dataset.citizenid;
            const rankLevel = document.getElementById('player-rank').value;
            
            addMemberToGang(citizenid, rankLevel);
        });
    });
    
    // Show results
    resultsContainer.classList.remove('hidden');
}

// Add member to gang
function addMemberToGang(citizenid, rankLevel) {
    if (!currentGang) return;
    
    // Send to server
    fetch('https://sv-gangs/addMemberToGang', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ 
            gangName: currentGang.name, 
            citizenid: citizenid,
            rankLevel: rankLevel
        })
    }).then(() => {
        showNotification('Member added successfully!', 'success');
        
        // Clear search and results
        document.getElementById('search-player').value = '';
        document.getElementById('search-results').classList.add('hidden');
        
        refreshGangData();
    });
}

// Refresh gang data
function refreshGangData() {
    if (!currentGang) return;
    
    // Re-select gang to refresh data
    selectGangToEdit(currentGang.name);
}

// Refresh gang list
function refreshGangList() {
    // Show loading spinner
    document.getElementById('gangs-loading').classList.remove('hidden');
    
    // Fetch gangs from server
    fetch('https://sv-gangs/refreshGangData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// Render leaderboard
function renderLeaderboard() {
    // Get data from gangs (sorted by points)
    const leaderboardList = document.getElementById('leaderboard-list');
    
    // Clear list
    leaderboardList.innerHTML = '';
    
    if (gangs.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td colspan="5" style="text-align: center;">No gangs found</td>';
        leaderboardList.appendChild(row);
        return;
    }
    
    // Sort gangs by points
    const sortedGangs = [...gangs].sort((a, b) => {
        // First by turfs
        if (b.turfs !== a.turfs) {
            return b.turfs - a.turfs;
        }
        // Then by members
        return b.memberCount - a.memberCount;
    });
    
    // Add gangs to leaderboard
    sortedGangs.forEach((gang, index) => {
        const row = document.createElement('tr');
        const positionClass = index < 3 ? `position-${index + 1}` : '';
        
        const colorPreview = `<span class="color-preview" style="background-color: ${gang.color}"></span>`;
        
        row.innerHTML = `
            <td class="${positionClass}">${index + 1}</td>
            <td>${colorPreview}${gang.label}</td>
            <td>${gang.points || 0}</td>
            <td>${gang.turfs}</td>
            <td>${gang.memberCount}</td>
        `;
        
        leaderboardList.appendChild(row);
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
