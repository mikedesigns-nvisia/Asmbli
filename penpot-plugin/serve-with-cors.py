#!/usr/bin/env python3
"""
HTTP server with CORS enabled for PenPot plugin development.
This allows PenPot to load the plugin from localhost.
"""

import http.server
import socketserver
from functools import partial

PORT = 8765

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS headers."""

    def end_headers(self):
        # Add CORS headers to allow PenPot to access the plugin
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        """Handle OPTIONS preflight requests."""
        self.send_response(200)
        self.end_headers()

if __name__ == '__main__':
    # Change to dist directory
    import os
    os.chdir('dist')

    Handler = CORSRequestHandler

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print("🚀 PenPot Plugin Server with CORS")
        print("=" * 50)
        print(f"\n✅ Server running at http://localhost:{PORT}")
        print(f"\n📦 Plugin URL: http://localhost:{PORT}/manifest.json")
        print("\n🔧 CORS enabled for cross-origin requests")
        print("\nTo install in PenPot:")
        print("1. Open https://design.penpot.app")
        print("2. Press Cmd+Alt+P (or Ctrl+Alt+P)")
        print(f"3. Enter: http://localhost:{PORT}/manifest.json")
        print("4. Click INSTALL")
        print("\nPress Ctrl+C to stop")
        print("=" * 50)
        print()

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n✋ Server stopped")
