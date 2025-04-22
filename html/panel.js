// Gang Panel Functionality

// Update Gang Panel UI with data
function updateGangPanelUI(data) {
    if (!data || !data.gang) return;
    
    const gang = data.gang;
    const members = data.members || [];
    const ranks = data.ranks || [];
    const turfs = data.turfs || [];
    
    // Update members list
    updateMembersList(members, ranks);
    
    // Update ranks table
    updateRanksTable(ranks);
    
    // Update turfs table
    updateGangTurfsTable(turfs, gang.id);
    
    // Add member button
    const addMemberBtn = document.getElementById('add-member-btn');
    const addMemberModal = document.getElementById('add-member-modal');
    
    if (addMemberBtn && addMemberModal) {
        addMemberBtn.addEventListener('click', function() {
            // Populate rank select
            const rankSelect = document.getElementById('rank-select');
            if (rankSelect) {
                rankSelect.innerHTML = '';
                ranks.forEach(rank => {
                    // Don't allow adding members with equal or higher rank than current user
                    if (rank.level < gang.rank) {
                        const option = document.createElement('option');
                        option.value = rank.level;
                        option.textContent = rank.name;
                        rankSelect.appendChild(option);
                    }
                });
            }
            
            addMemberModal.style.display = 'block';
        });
    }
    
    // Add member form submission
    const addMemberForm = document.getElementById('add-member-form');
    if (addMemberForm) {
        addMemberForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const playerId = document.getElementById('player-id-input').value;
            const rankLevel = document.getElementById('rank-select').value;
            
            if (!playerId) {
                alert('Please enter a player ID');
                return;
            }
            
            // Send add member request
            fetch('https://sv-gangsystem/addGangMember', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    gangId: gang.id,
                    playerId: playerId,
                    rank: rankLevel
                })
            });
            
            // Close modal and reset form
            addMemberModal.style.display = 'none';
            addMemberForm.reset();
            
            // Refresh data after a brief delay
            setTimeout(() => {
                refreshGangData();
            }, 500);
        });
    }
    
    // Edit rank modal
    const editRankModal = document.getElementById('edit-rank-modal');
    const editRankForm = document.getElementById('edit-rank-form');
    
    if (editRankForm) {
        editRankForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const rankLevel = document.getElementById('edit-rank-level').value;
            const rankName = document.getElementById('edit-rank-name').value;
            
            if (!rankName) {
                alert('Please enter a rank name');
                return;
            }
            
            // Send update rank request
            fetch('https://sv-gangsystem/updateGangRank', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    gangId: gang.id,
                    rankLevel: rankLevel,
                    rankName: rankName
                })
            });
            
            // Close modal and reset form
            editRankModal.style.display = 'none';
            editRankForm.reset();
            
            // Refresh data after a brief delay
            setTimeout(() => {
                refreshGangData();
            }, 500);
        });
    }
}

// Update members list
function updateMembersList(members, ranks) {
    const memberListElement = document.getElementById('member-list');
    if (!memberListElement) return;
    
    memberListElement.innerHTML = '';
    
    if (members && members.length > 0) {
        members.forEach(member => {
            const memberItem = document.createElement('div');
            memberItem.className = 'member-item';
            
            memberItem.innerHTML = `
                <div class="member-info">
                    <div class="member-name">${member.player_name}</div>
                    <div class="member-details">
                        Rank: <span class="rank-${member.rank}">${member.rank_name}</span> | Joined: ${formatDate(member.joined_at)}
                    </div>
                </div>
                <div class="member-actions">
                    <button class="btn change-rank" data-id="${member.player_id}" data-name="${member.player_name}" data-rank="${member.rank}">
                        <i class="fas fa-exchange-alt"></i> Change Rank
                    </button>
                    <button class="btn btn-danger kick-member" data-id="${member.player_id}" data-name="${member.player_name}">
                        <i class="fas fa-user-times"></i> Kick
                    </button>
                </div>
            `;
            
            memberListElement.appendChild(memberItem);
        });
        
        // Add event listeners for member actions
        const kickButtons = document.querySelectorAll('.kick-member');
        kickButtons.forEach(btn => {
            btn.addEventListener('click', function() {
                const playerId = this.getAttribute('data-id');
                const playerName = this.getAttribute('data-name');
                
                if (confirm(`Are you sure you want to kick ${playerName} from the gang?`)) {
                    // Send kick request
                    fetch('https://sv-gangsystem/removeGangMember', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ playerId: playerId })
                    });
                    
                    // Refresh data after a brief delay
                    setTimeout(() => {
                        refreshGangData();
                    }, 500);
                }
            });
        });
        
        const changeRankButtons = document.querySelectorAll('.change-rank');
        changeRankButtons.forEach(btn => {
            btn.addEventListener('click', function() {
                const playerId = this.getAttribute('data-id');
                const playerName = this.getAttribute('data-name');
                const currentRank = parseInt(this.getAttribute('data-rank'));
                
                // Create and show a custom rank selection dialog
                let rankOptions = '';
                ranks.forEach(rank => {
                    // Don't show current rank or ranks equal to or higher than user's rank
                    if (rank.level !== currentRank && rank.level < currentGang.rank) {
                        rankOptions += `<option value="${rank.level}">${rank.name}</option>`;
                    }
                });
                
                const dialog = document.createElement('div');
                dialog.className = 'modal';
                dialog.style.display = 'block';
                dialog.innerHTML = `
                    <div class="modal-content">
                        <span class="modal-close">&times;</span>
                        <h3>Change Rank for ${playerName}</h3>
                        <form id="change-rank-form">
                            <div class="form-group">
                                <label>Select New Rank:</label>
                                <select id="new-rank-select">
                                    ${rankOptions}
                                </select>
                            </div>
                            <button type="submit" class="btn">Save Changes</button>
                        </form>
                    </div>
                `;
                
                document.body.appendChild(dialog);
                
                // Close button
                dialog.querySelector('.modal-close').addEventListener('click', function() {
                    document.body.removeChild(dialog);
                });
                
                // Form submission
                dialog.querySelector('#change-rank-form').addEventListener('submit', function(e) {
                    e.preventDefault();
                    
                    const newRank = document.getElementById('new-rank-select').value;
                    
                    // Send update rank request
                    fetch('https://sv-gangsystem/updateMemberRank', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            playerId: playerId,
                            newRank: newRank
                        })
                    });
                    
                    // Remove dialog
                    document.body.removeChild(dialog);
                    
                    // Refresh data after a brief delay
                    setTimeout(() => {
                        refreshGangData();
                    }, 500);
                });
                
                // Close on outside click
                dialog.addEventListener('click', function(event) {
                    if (event.target === dialog) {
                        document.body.removeChild(dialog);
                    }
                });
            });
        });
    } else {
        memberListElement.innerHTML = '<div class="empty-message">No members found</div>';
    }
}

// Update ranks table
function updateRanksTable(ranks) {
    const rankTableBody = document.getElementById('rank-body');
    if (!rankTableBody) return;
    
    rankTableBody.innerHTML = '';
    
    if (ranks && ranks.length > 0) {
        ranks.forEach(rank => {
            const row = document.createElement('tr');
            
            row.innerHTML = `
                <td>${rank.level}</td>
                <td class="rank-${rank.level}">${rank.name}</td>
                <td>
                    <button class="btn edit-rank" data-level="${rank.level}" data-name="${rank.name}">
                        <i class="fas fa-edit"></i> Edit
                    </button>
                </td>
            `;
            
            rankTableBody.appendChild(row);
        });
        
        // Add event listeners for edit rank buttons
        const editButtons = document.querySelectorAll('.edit-rank');
        const editRankModal = document.getElementById('edit-rank-modal');
        
        editButtons.forEach(btn => {
            btn.addEventListener('click', function() {
                const rankLevel = this.getAttribute('data-level');
                const rankName = this.getAttribute('data-name');
                
                // Don't allow editing ranks equal to or higher than current user's rank
                if (parseInt(rankLevel) >= currentGang.rank) {
                    alert('You cannot edit this rank');
                    return;
                }
                
                // Populate form
                document.getElementById('edit-rank-level').value = rankLevel;
                document.getElementById('edit-rank-name').value = rankName;
                
                // Show modal
                editRankModal.style.display = 'block';
            });
        });
    }
}

// Update gang turfs table
function updateGangTurfsTable(turfs, gangId) {
    const turfTableBody = document.getElementById('gang-turf-body');
    if (!turfTableBody) return;
    
    turfTableBody.innerHTML = '';
    
    // Filter turfs controlled by this gang
    const gangTurfs = turfs.filter(turf => turf.gang_id === gangId);
    
    if (gangTurfs.length > 0) {
        gangTurfs.forEach(turf => {
            const row = document.createElement('tr');
            
            // Check if turf is on cooldown
            const now = new Date();
            const cooldownUntil = turf.cooldown_until ? new Date(turf.cooldown_until) : null;
            const isOnCooldown = cooldownUntil && cooldownUntil > now;
            
            row.innerHTML = `
                <td>${turf.turf_name}</td>
                <td>${turf.captured_at ? formatDate(turf.captured_at) : 'N/A'}</td>
                <td>${isOnCooldown ? 
                    `<span style="color: #F44336;">On Cooldown (${Math.ceil((cooldownUntil - now) / 1000 / 60)} min)</span>` : 
                    '<span style="color: #66BB6A;">Active</span>'}
                </td>
            `;
            
            turfTableBody.appendChild(row);
        });
    } else {
        const emptyRow = document.createElement('tr');
        emptyRow.innerHTML = '<td colspan="3" style="text-align: center;">Your gang does not control any turfs</td>';
        turfTableBody.appendChild(emptyRow);
    }
}

// Refresh gang data
function refreshGangData() {
    fetch('https://sv-gangsystem/refreshData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}
