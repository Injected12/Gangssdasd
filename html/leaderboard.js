// SouthVale RP Gang System - Leaderboard JS

// Global variables
let leaderboardData = [];

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Refresh button click
    document.getElementById('refresh-btn')?.addEventListener('click', function() {
        refreshLeaderboard();
    });
    
    // Initial load of leaderboard
    refreshLeaderboard();
});

// Set leaderboard data from main script
window.setLeaderboardData = function(data) {
    leaderboardData = data;
    updateLeaderboard();
};

// Update leaderboard with data
function updateLeaderboard() {
    const tableBody = document.getElementById('leaderboard-list');
    const loadingElement = document.getElementById('leaderboard-loading');
    
    // Hide loading spinner
    loadingElement.classList.add('hidden');
    
    // Update top 3 gangs
    updateTopGangs();
    
    // Clear table
    tableBody.innerHTML = '';
    
    if (!leaderboardData || leaderboardData.length === 0) {
        // Show empty state
        tableBody.innerHTML = `
            <tr>
                <td colspan="5">
                    <div class="empty-leaderboard">
                        <i class="fas fa-trophy"></i>
                        <p>No gangs found. Be the first to start a gang!</p>
                    </div>
                </td>
            </tr>
        `;
        return;
    }
    
    // Add gangs to table (starting from 4th place)
    for (let i = 3; i < leaderboardData.length; i++) {
        const gang = leaderboardData[i];
        const row = document.createElement('tr');
        
        const colorIndicator = `<span class="gang-color-indicator" style="background-color: ${gang.color}"></span>`;
        
        row.innerHTML = `
            <td>${gang.position}</td>
            <td>${colorIndicator}${gang.label}</td>
            <td>${gang.points || 0}</td>
            <td>${gang.turfs || 0}</td>
            <td>${gang.members || 0}</td>
        `;
        
        tableBody.appendChild(row);
    }
}

// Update top 3 gangs
function updateTopGangs() {
    // Get elements
    const firstPlace = document.getElementById('first-place');
    const secondPlace = document.getElementById('second-place');
    const thirdPlace = document.getElementById('third-place');
    
    // Reset if no data
    if (!leaderboardData || leaderboardData.length === 0) {
        firstPlace.querySelector('.gang-name').textContent = '-';
        firstPlace.querySelector('.gang-points').textContent = '-';
        secondPlace.querySelector('.gang-name').textContent = '-';
        secondPlace.querySelector('.gang-points').textContent = '-';
        thirdPlace.querySelector('.gang-name').textContent = '-';
        thirdPlace.querySelector('.gang-points').textContent = '-';
        return;
    }
    
    // Update first place
    if (leaderboardData.length > 0) {
        const gang = leaderboardData[0];
        firstPlace.querySelector('.gang-name').textContent = gang.label;
        firstPlace.querySelector('.gang-points').textContent = `${gang.points || 0} points`;
        firstPlace.style.backgroundColor = gang.color || 'var(--gold)';
    }
    
    // Update second place
    if (leaderboardData.length > 1) {
        const gang = leaderboardData[1];
        secondPlace.querySelector('.gang-name').textContent = gang.label;
        secondPlace.querySelector('.gang-points').textContent = `${gang.points || 0} points`;
        secondPlace.style.backgroundColor = gang.color || 'var(--silver)';
    } else {
        secondPlace.querySelector('.gang-name').textContent = '-';
        secondPlace.querySelector('.gang-points').textContent = '-';
    }
    
    // Update third place
    if (leaderboardData.length > 2) {
        const gang = leaderboardData[2];
        thirdPlace.querySelector('.gang-name').textContent = gang.label;
        thirdPlace.querySelector('.gang-points').textContent = `${gang.points || 0} points`;
        thirdPlace.style.backgroundColor = gang.color || 'var(--bronze)';
    } else {
        thirdPlace.querySelector('.gang-name').textContent = '-';
        thirdPlace.querySelector('.gang-points').textContent = '-';
    }
}

// Refresh leaderboard
function refreshLeaderboard() {
    // Show loading spinner
    document.getElementById('leaderboard-loading').classList.remove('hidden');
    
    // Fetch leaderboard from server
    fetch('https://sv-gangs/refreshLeaderboard', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}
