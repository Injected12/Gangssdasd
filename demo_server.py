import http.server
import socketserver
import os

class SimpleRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle static files
        if self.path == '/':
            self.path = '/html/index.html'
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

if __name__ == "__main__":
    # Start server
    PORT = 5000
    Handler = SimpleRequestHandler
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving QBCore Gang System at http://localhost:{PORT}")
        httpd.serve_forever()