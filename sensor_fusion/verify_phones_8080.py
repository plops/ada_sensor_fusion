#!/usr/bin/env python3
"""
VERIFICATION TOOL: Phone Connection Detection on Port 8080
PURPOSE: Verify phones send data to original Sensor Logger URL
SCOPE: Final verification tool to confirm phones work without configuration changes
"""

import http.server
import socketserver
import urllib.request
import json
from datetime import datetime

class RedirectHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        print(f"\n=== {datetime.now()} ===")
        print(f"PHONE CONNECTION DETECTED from {self.client_address[0]}")
        
        # Get content length
        content_length = int(self.headers.get('Content-Length', 0))
        print(f"Content-Length: {content_length}")
        
        if content_length > 0:
            # Read raw data
            raw_data = self.rfile.read(content_length)
            print(f"✓ Received {len(raw_data)} bytes from phone!")
            
            try:
                text_data = raw_data.decode('utf-8')
                print(f"First 100 chars: {text_data[:100]}...")
                
                # Parse JSON
                json_data = json.loads(text_data)
                if 'payload' in json_data:
                    payload = json_data['payload']
                    print(f"✓ Payload items: {len(payload)}")
                    
                    # Show sensor types
                    sensor_types = set()
                    for item in payload:
                        if 'name' in item:
                            sensor_types.add(item['name'])
                    print(f"✓ Sensor types: {', '.join(sensor_types)}")
                            
            except Exception as e:
                print(f"Parse error: {e}")
        else:
            print("No data received")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Phone data received by verifier')

def main():
    port = 8080  # Exact same port as Ada server
    server = http.server.HTTPServer(('10.0.0.146', port), RedirectHandler)
    print(f"=== Phone Verification Server (Port 8080) ===")
    print(f"Target: http://10.0.0.146:{port}/data")
    print("Phones can use original configuration!")
    print("Waiting for phone connections...")
    server.serve_forever()

if __name__ == "__main__":
    main()
