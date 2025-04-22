import http.server
import socketserver
import os
import json
from urllib.parse import parse_qs, urlparse

# Mock data for demonstration
MOCK_DATA = {
    "gangs": [
        {
            "name": "ballas",
            "label": "The Ballas",
            "color": "#9b59b6",
            "memberCount": 8,
            "turfs": 3,
            "points": 520,
            "grades": [
                {"name": "Boss", "level": 100},
                {"name": "Underboss", "level": 90},
                {"name": "Lieutenant", "level": 70},
                {"name": "Soldier", "level": 50},
                {"name": "Associate", "level": 10},
                {"name": "Recruit", "level": 0}
            ],
            "members": [
                {"citizenid": "ABC123", "name": "John Doe", "gradeName": "Boss", "gradeLevel": 100, "isOnline": True},
                {"citizenid": "DEF456", "name": "Jane Smith", "gradeName": "Underboss", "gradeLevel": 90, "isOnline": True},
                {"citizenid": "GHI789", "name": "Mike Johnson", "gradeName": "Lieutenant", "gradeLevel": 70, "isOnline": False},
                {"citizenid": "JKL012", "name": "Sarah Williams", "gradeName": "Soldier", "gradeLevel": 50, "isOnline": False}
            ]
        },
        {
            "name": "vagos",
            "label": "Los Vagos",
            "color": "#f1c40f",
            "memberCount": 6,
            "turfs": 2,
            "points": 350
        },
        {
            "name": "families",
            "label": "The Families",
            "color": "#2ecc71",
            "memberCount": 7,
            "turfs": 2,
            "points": 380
        },
        {
            "name": "triads",
            "label": "The Triads",
            "color": "#e74c3c",
            "memberCount": 5,
            "turfs": 1,
            "points": 220
        }
    ],
    "turfs": [
        {"id": 1, "name": "Downtown", "last_captured": "2025-04-20T10:30:00Z"},
        {"id": 2, "name": "Beach Area", "last_captured": "2025-04-19T14:45:00Z"},
        {"id": 3, "name": "Industrial Zone", "last_captured": "2025-04-21T08:15:00Z"}
    ],
    "leaderboard": [
        {"position": 1, "name": "ballas", "label": "The Ballas", "color": "#9b59b6", "points": 520, "turfs": 3, "members": 8},
        {"position": 2, "name": "families", "label": "The Families", "color": "#2ecc71", "points": 380, "turfs": 2, "members": 7},
        {"position": 3, "name": "vagos", "label": "Los Vagos", "color": "#f1c40f", "points": 350, "turfs": 2, "members": 6},
        {"position": 4, "name": "triads", "label": "The Triads", "color": "#e74c3c", "points": 220, "turfs": 1, "members": 5}
    ]
}

class DemoRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle static files
        if self.path == '/':
            self.path = '/html/index.html'
        
        # Handle specific JavaScript files with proper demo mode
        if self.path.endswith('.js'):
            try:
                with open('.' + self.path, 'r') as file:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/javascript')
                    self.end_headers()
                    content = file.read()
                    # Replace the fetch calls to use our mock data
                    content = content.replace('fetch(\'https://sv-gangs/', 'console.log(\'Demo mode, not fetching: https://sv-gangs/')
                    self.wfile.write(content.encode())
                return
            except:
                pass
                
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def do_POST(self):
        # Mock API responses
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        # Parse the URL path
        path = urlparse(self.path).path
        
        response = {"success": True}
        
        # Mock different API endpoints
        if path == '/setGangsData':
            response = MOCK_DATA["gangs"]
        elif path == '/setGangData':
            response = {"gangData": MOCK_DATA["gangs"][0]}
        elif path == '/setGangTurfs':
            response = {"turfs": MOCK_DATA["turfs"]}
        elif path == '/setLeaderboardData':
            response = {"leaderboard": MOCK_DATA["leaderboard"]}
        
        self.wfile.write(json.dumps(response).encode())

# Add demo functions to serve specific panels
def inject_demo_script():
    script = """
    <script>
    // Demo functions to load data
    document.addEventListener('DOMContentLoaded', function() {
        // Set up demo data
        const MOCK_DATA = {
            "gangs": [
                {
                    "name": "ballas",
                    "label": "The Ballas",
                    "color": "#9b59b6",
                    "memberCount": 8,
                    "turfs": 3,
                    "points": 520,
                    "grades": [
                        {"name": "Boss", "level": 100},
                        {"name": "Underboss", "level": 90},
                        {"name": "Lieutenant", "level": 70},
                        {"name": "Soldier", "level": 50},
                        {"name": "Associate", "level": 10},
                        {"name": "Recruit", "level": 0}
                    ],
                    "members": [
                        {"citizenid": "ABC123", "name": "John Doe", "gradeName": "Boss", "gradeLevel": 100, "isOnline": true},
                        {"citizenid": "DEF456", "name": "Jane Smith", "gradeName": "Underboss", "gradeLevel": 90, "isOnline": true},
                        {"citizenid": "GHI789", "name": "Mike Johnson", "gradeName": "Lieutenant", "gradeLevel": 70, "isOnline": false},
                        {"citizenid": "JKL012", "name": "Sarah Williams", "gradeName": "Soldier", "gradeLevel": 50, "isOnline": false}
                    ]
                },
                {
                    "name": "vagos",
                    "label": "Los Vagos",
                    "color": "#f1c40f",
                    "memberCount": 6,
                    "turfs": 2,
                    "points": 350
                },
                {
                    "name": "families",
                    "label": "The Families",
                    "color": "#2ecc71",
                    "memberCount": 7,
                    "turfs": 2,
                    "points": 380
                },
                {
                    "name": "triads",
                    "label": "The Triads",
                    "color": "#e74c3c",
                    "memberCount": 5,
                    "turfs": 1,
                    "points": 220
                }
            ],
            "turfs": [
                {"id": 1, "name": "Downtown", "last_captured": "2025-04-20T10:30:00Z"},
                {"id": 2, "name": "Beach Area", "last_captured": "2025-04-19T14:45:00Z"},
                {"id": 3, "name": "Industrial Zone", "last_captured": "2025-04-21T08:15:00Z"}
            ],
            "leaderboard": [
                {"position": 1, "name": "ballas", "label": "The Ballas", "color": "#9b59b6", "points": 520, "turfs": 3, "members": 8},
                {"position": 2, "name": "families", "label": "The Families", "color": "#2ecc71", "points": 380, "turfs": 2, "members": 7},
                {"position": 3, "name": "vagos", "label": "Los Vagos", "color": "#f1c40f", "points": 350, "turfs": 2, "members": 6},
                {"position": 4, "name": "triads", "label": "The Triads", "color": "#e74c3c", "points": 220, "turfs": 1, "members": 5}
            ]
        };

        // Demo function to show gang HUD
        setTimeout(function() {
            const event = {
                data: {
                    action: 'updateGangHUD',
                    show: true,
                    gang: {
                        label: 'The Ballas',
                        rank: 'Boss', 
                        color: '#9b59b6'
                    }
                }
            };
            window.dispatchEvent(new CustomEvent('message', { detail: event }));
        }, 500);

        // Override the event listener to handle our custom events
        const originalEventListener = window.addEventListener;
        window.addEventListener = function(type, listener, options) {
            if (type === 'message') {
                document.addEventListener('message', function(e) {
                    listener(e.detail);
                }, options);
            } else {
                originalEventListener.call(window, type, listener, options);
            }
        };

        // Demo buttons to show different panels
        const demoDiv = document.createElement('div');
        demoDiv.style.position = 'fixed';
        demoDiv.style.bottom = '20px';
        demoDiv.style.left = '20px';
        demoDiv.style.zIndex = '1000';
        demoDiv.style.backgroundColor = 'rgba(0,0,0,0.7)';
        demoDiv.style.padding = '10px';
        demoDiv.style.borderRadius = '5px';
        demoDiv.innerHTML = `
            <h3 style="color:white;margin-top:0;">QBCore Gang System Demo</h3>
            <button id="show-admin" style="margin:5px;padding:5px 10px;">Show Admin Panel</button>
            <button id="show-gang" style="margin:5px;padding:5px 10px;">Show Gang Panel</button>
            <button id="show-leaderboard" style="margin:5px;padding:5px 10px;">Show Leaderboard</button>
            <button id="show-invite" style="margin:5px;padding:5px 10px;">Show Gang Invite</button>
        `;
        document.body.appendChild(demoDiv);

        // Add event listeners to demo buttons
        document.getElementById('show-admin').addEventListener('click', function() {
            loadPanel('gangadmin');
            // Set gangs data after panel is loaded
            setTimeout(function() {
                if (window.setGangsData) {
                    window.setGangsData(MOCK_DATA.gangs);
                }
            }, 100);
        });

        document.getElementById('show-gang').addEventListener('click', function() {
            loadPanel('gangpanel');
            // Set gang data after panel is loaded
            setTimeout(function() {
                if (window.setGangPanelData) {
                    window.setGangPanelData(MOCK_DATA.gangs[0]);
                }
                if (window.setGangTurfs) {
                    window.setGangTurfs(MOCK_DATA.turfs);
                }
            }, 100);
        });

        document.getElementById('show-leaderboard').addEventListener('click', function() {
            loadPanel('leaderboard');
            // Set leaderboard data after panel is loaded
            setTimeout(function() {
                if (window.setLeaderboardData) {
                    window.setLeaderboardData(MOCK_DATA.leaderboard);
                }
            }, 100);
        });

        document.getElementById('show-invite').addEventListener('click', function() {
            const event = {
                data: {
                    action: 'gangInvite',
                    gangName: 'The Ballas',
                    inviterName: 'John Doe'
                }
            };
            window.dispatchEvent(new CustomEvent('message', { detail: event }));
        });
    });
    </script>
    """
    
    # Inject the script into index.html
    try:
        with open('./html/index.html', 'r') as file:
            content = file.read()
            if '</body>' in content:
                content = content.replace('</body>', script + '</body>')
                with open('./html/index.html', 'w') as outfile:
                    outfile.write(content)
    except Exception as e:
        print(f"Error injecting demo script: {e}")

if __name__ == "__main__":
    # Inject demo script
    inject_demo_script()
    
    # Start server
    PORT = 5000
    Handler = DemoRequestHandler
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving QBCore Gang System Demo at http://localhost:{PORT}")
        httpd.serve_forever()