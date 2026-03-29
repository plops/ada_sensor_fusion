#!/usr/bin/env python3
"""
Enhanced Python Server with Data Saving
Captures real Sensor Logger data and saves to CSV for Ada processing
"""

import http.server
import json
import csv
import os
from datetime import datetime, timezone

class DataCaptureHandler(http.server.BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.csv_file = None
        self.csv_writer = None
        super().__init__(*args, **kwargs)
    
    def do_POST(self):
        print(f"\n=== {datetime.now()} ===")
        print(f"PHONE CONNECTION from {self.client_address[0]}")
        
        # Get content length
        content_length = int(self.headers.get('Content-Length', 0))
        print(f"Content-Length: {content_length}")
        
        if content_length > 0:
            # Read raw data
            raw_data = self.rfile.read(content_length)
            print(f"✓ Received {len(raw_data)} bytes")
            
            try:
                text_data = raw_data.decode('utf-8')
                json_data = json.loads(text_data)
                
                if 'payload' in json_data:
                    payload = json_data['payload']
                    print(f"✓ Payload items: {len(payload)}")
                    
                    # Extract device info from first payload item or use defaults
                    device_id = "unknown_device"
                    platform = "unknown_platform"
                    
                    # Try to extract device info from JSON if available
                    if 'deviceId' in json_data:
                        device_id = json_data['deviceId']
                    if 'platform' in json_data:
                        platform = json_data['platform']
                    
                    # Extract sensor types
                    sensor_types = set()
                    for item in payload:
                        if 'name' in item:
                            sensor_types.add(item['name'])
                    print(f"✓ Sensor types: {', '.join(sensor_types)}")
                    
                    # Save to CSV
                    self.save_to_csv(payload, device_id, platform)
                    
                else:
                    print("✗ No payload found in JSON")
                    
            except Exception as e:
                print(f"Parse error: {e}")
        else:
            print("No data received")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Data received and saved')
    
    def save_to_csv(self, payload, device_id, platform):
        """Save sensor payload to CSV file"""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        filename = f"phone_data_{timestamp}.csv"
        
        # Create CSV file if it doesn't exist
        file_exists = os.path.exists(filename)
        
        with open(filename, 'a', newline='') as csvfile:
            fieldnames = ['timestamp_ns', 'platform', 'device_id', 'sensor_type', 'x', 'y', 'z']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            # Write header if new file
            if not file_exists:
                writer.writeheader()
            
            # Write each sensor reading
            for item in payload:
                if 'name' in item and 'values' in item and 'time' in item:
                    values = item['values']
                    
                    # Handle different value formats
                    if isinstance(values, dict):
                        if 'x' in values and 'y' in values and 'z' in values:
                            row = {
                                'timestamp_ns': item['time'],
                                'platform': platform,
                                'device_id': device_id,
                                'sensor_type': item['name'],
                                'x': values['x'],
                                'y': values['y'], 
                                'z': values['z']
                            }
                        elif 'qw' in values:  # Quaternion/orientation data
                            row = {
                                'timestamp_ns': item['time'],
                                'platform': platform,
                                'device_id': device_id,
                                'sensor_type': item['name'],
                                'x': values['qw'],  # Store quaternion w in x
                                'y': values['qx'],  # Store quaternion x in y
                                'z': values['qy']   # Store quaternion y in z
                            }
                        else:
                            continue
                    else:
                        continue
                    
                    writer.writerow(row)
        
        print(f"✓ Saved {len(payload)} readings to {filename}")

def main():
    port = 8080
    server_address = ('10.0.0.146', port)
    
    with http.server.HTTPServer(server_address, DataCaptureHandler) as httpd:
        print(f"=== Enhanced Phone Data Capture Server ===")
        print(f"Target: http://10.0.0.146:{port}/data")
        print(f"Saving data to CSV files: phone_data_*.csv")
        print("Waiting for phone connections...")
        print()
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped by user")

if __name__ == "__main__":
    main()
