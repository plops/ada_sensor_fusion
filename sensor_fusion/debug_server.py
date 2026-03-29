#!/usr/bin/env python3
"""
DEBUG TOOL: Python HTTP Server for Sensor Logger Data Analysis
PURPOSE: Debug and verify Sensor Logger phone data transmission
SCOPE: Intermediate debugging tool to understand phone data format
"""

import http.server
import json
from datetime import datetime

PORT = 8080

class DebugHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        print(f"\n=== {datetime.now()} ===")
        print(f"Method: POST")
        print(f"Path: {self.path}")
        print(f"Headers:")
        for header, value in self.headers.items():
            print(f"  {header}: {value}")
        
        # Get content length
        content_length = int(self.headers.get('Content-Length', 0))
        print(f"Content-Length: {content_length}")
        
        # Read raw data
        raw_data = self.rfile.read(content_length)
        print(f"Raw data ({len(raw_data)} bytes):")
        
        try:
            # Try to decode as text
            text_data = raw_data.decode('utf-8')
            print(f"Text: {text_data}")
            
            # Try to parse as JSON
            try:
                json_data = json.loads(text_data)
                print(f"Parsed JSON: {json.dumps(json_data, indent=2)}")
                
                # Analyze payload if present
                if 'payload' in json_data:
                    payload = json_data['payload']
                    print(f"Payload items: {len(payload)}")
                    for i, item in enumerate(payload[:3]):  # Show first 3 items
                        print(f"  Item {i+1}: {item}")
                        
            except json.JSONDecodeError as e:
                print(f"JSON parse error: {e}")
                
        except UnicodeDecodeError:
            print(f"Binary data (hex): {raw_data.hex()}")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Data received for debugging')

    def do_GET(self):
        print(f"\n=== GET Request ===")
        print(f"Path: {self.path}")
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Debug server running')

def main():
    with socketserver.TCPServer(("", PORT), DebugHandler) as httpd:
        print(f"Debug server started on port {PORT}")
        print(f"Target URL: http://10.0.0.146:{PORT}/data")
        print("Waiting for Sensor Logger connections...")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
