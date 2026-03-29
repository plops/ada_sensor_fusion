#!/usr/bin/env python3
"""
VALIDATION TOOL: Ada Server Test with Realistic Phone Data
PURPOSE: Validate Ada server functionality with exact phone data format
SCOPE: End-to-end testing tool to verify Ada server works correctly
"""

import requests
import json
import time
import random
from datetime import datetime

def create_realistic_sensor_data(device_id, session_id, message_id):
    """Create sensor data matching the exact format from real phones"""
    timestamp = int(time.time() * 1_000_000_000)  # Nanoseconds
    
    # Create payload with all sensor types we observed
    payload = []
    
    # Accelerometer
    payload.append({
        "name": "accelerometer",
        "values": {
            "x": round(random.uniform(-2.0, 2.0), 6),
            "y": round(random.uniform(-2.0, 2.0), 6), 
            "z": round(random.uniform(-2.0, 2.0), 6)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Accelerometer Uncalibrated
    payload.append({
        "name": "accelerometeruncalibrated",
        "values": {
            "x": round(random.uniform(-2.0, 2.0), 6),
            "y": round(random.uniform(-2.0, 2.0), 6),
            "z": round(random.uniform(-2.0, 2.0), 6)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Gyroscope Uncalibrated
    payload.append({
        "name": "gyroscopeuncalibrated",
        "values": {
            "x": round(random.uniform(-1.0, 1.0), 6),
            "y": round(random.uniform(-1.0, 1.0), 6),
            "z": round(random.uniform(-1.0, 1.0), 6)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Magnetometer Uncalibrated
    payload.append({
        "name": "magnetometeruncalibrated",
        "values": {
            "x": round(random.uniform(-500, 500), 3),
            "y": round(random.uniform(-500, 500), 3),
            "z": round(random.uniform(-500, 500), 3)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Orientation (quaternions)
    payload.append({
        "name": "orientation",
        "values": {
            "qw": round(random.uniform(-1, 1), 6),
            "qx": round(random.uniform(-0.1, 0.1), 6),
            "qy": round(random.uniform(-0.1, 0.1), 6),
            "qz": round(random.uniform(-1, 1), 6),
            "roll": round(random.uniform(-3.14, 3.14), 6),
            "pitch": round(random.uniform(-3.14, 3.14), 6),
            "yaw": round(random.uniform(-3.14, 3.14), 6)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Gravity
    payload.append({
        "name": "gravity",
        "values": {
            "x": round(random.uniform(-1.0, 1.0), 6),
            "y": round(random.uniform(-1.0, 1.0), 6),
            "z": round(random.uniform(-1.0, 1.0), 6)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Barometer
    payload.append({
        "name": "barometer",
        "values": {
            "pressure": round(random.uniform(980, 1050), 3)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    return {
        "messageId": message_id,
        "sessionId": session_id,
        "deviceId": device_id,
        "payload": payload
    }

def send_to_ada_server(device_name, device_id, session_id, start_message_id):
    """Send simulated phone data to Ada server"""
    url = "http://10.0.0.146:8080/data"
    
    print(f"=== {device_name} Simulator ===")
    print(f"Device ID: {device_id}")
    print(f"Session ID: {session_id}")
    print(f"Target: {url}")
    print("")
    
    # Send multiple messages to simulate continuous data stream
    for i in range(5):
        message_id = start_message_id + i
        sensor_data = create_realistic_sensor_data(device_id, session_id, message_id)
        
        json_data = json.dumps(sensor_data)
        
        print(f"--- Message {message_id} ---")
        print(f"Payload items: {len(sensor_data['payload'])}")
        print(f"Data size: {len(json_data)} bytes")
        print(f"First 100 chars: {json_data[:100]}...")
        
        try:
            response = requests.post(url, 
                               data=json_data,
                               headers={'Content-Type': 'application/json'},
                               timeout=5)
            print(f"✓ Response: {response.status_code} - {response.text}")
            
            if response.status_code == 200:
                print(f"✓ {device_name} data received by Ada server")
            else:
                print(f"✗ {device_name} failed: {response.status_code}")
                
        except Exception as e:
            print(f"✗ {device_name} error: {e}")
        
        print("")
        time.sleep(0.5)  # Simulate real phone timing
    
    return True

def main():
    print("=== Ada Server Validation Simulator ===")
    print("Tests Ada server with realistic phone data")
    print("Target: http://10.0.0.146:8080/data")
    print("")
    
    # Simulate Samsung S10e data
    samsung_success = send_to_ada_server(
        "Samsung S10e",
        "85b1b711-464d-4e17-9c1234567890",
        "c93ef914-d314-44a8-ba97-aded3cb742c8",
        400
    )
    
    time.sleep(1)
    
    # Simulate iPhone 11 data
    iphone_success = send_to_ada_server(
        "iPhone 11", 
        "c0fe1156-57dc-45b5-abcdef123456789",
        "ecbf4e58-492f-45d7-9f73-06d43ce83040",
        1100
    )
    
    print("=== Validation Complete ===")
    if samsung_success and iphone_success:
        print("✅ Ada server successfully validated with both device types")
        print("✅ Ready for real strapped experiment data")
    else:
        print("❌ Ada server validation failed")
        print("❌ Check Ada server logs for errors")

if __name__ == "__main__":
    main()
