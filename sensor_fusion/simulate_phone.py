#!/usr/bin/env python3
"""
Phone Simulator - Sends Sensor Logger data to test Ada server
Mimics the exact data format we saw from phones
"""

import requests
import json
import time
import random

def create_sensor_batch():
    """Create a batch of sensor data like phones send"""
    timestamp = int(time.time() * 1_000_000_000)  # Nanoseconds
    
    payload = []
    
    # Add accelerometer data
    payload.append({
        "name": "accelerometer",
        "values": {
            "x": random.uniform(-2.0, 2.0),
            "y": random.uniform(-2.0, 2.0), 
            "z": random.uniform(-2.0, 2.0)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Add gyroscope data
    payload.append({
        "name": "gyroscopeuncalibrated",
        "values": {
            "x": random.uniform(-1.0, 1.0),
            "y": random.uniform(-1.0, 1.0),
            "z": random.uniform(-1.0, 1.0)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Add magnetometer data
    payload.append({
        "name": "magnetometeruncalibrated",
        "values": {
            "x": random.uniform(-500, 500),
            "y": random.uniform(-500, 500),
            "z": random.uniform(-500, 500)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    # Add orientation data
    payload.append({
        "name": "orientation",
        "values": {
            "qw": random.uniform(-1, 1),
            "qx": random.uniform(-0.1, 0.1),
            "qy": random.uniform(-0.1, 0.1),
            "qz": random.uniform(-1, 1),
            "roll": random.uniform(-3.14, 3.14),
            "pitch": random.uniform(-3.14, 3.14),
            "yaw": random.uniform(-3.14, 3.14)
        },
        "accuracy": 3,
        "time": timestamp
    })
    
    return payload

def send_to_ada_server():
    """Send sensor data to Ada server"""
    url = "http://10.0.0.146:8080/data"
    
    # Create data like phones send
    sensor_data = {
        "payload": create_sensor_batch()
    }
    
    json_data = json.dumps(sensor_data)
    
    print(f"=== Phone Simulator ===")
    print(f"Sending to: {url}")
    print(f"Data size: {len(json_data)} bytes")
    print(f"Payload items: {len(sensor_data['payload'])}")
    print(f"First 100 chars: {json_data[:100]}...")
    
    try:
        response = requests.post(url, 
                           data=json_data,
                           headers={'Content-Type': 'application/json'},
                           timeout=5)
        print(f"Response: {response.status_code} - {response.text}")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("=== Phone Simulator for Ada Server Test ===")
    print("This simulates Sensor Logger phone data")
    print("Target: http://10.0.0.146:8080/data")
    print("")
    
    # Test multiple sends
    for i in range(3):
        print(f"\n--- Test {i+1} ---")
        success = send_to_ada_server()
        if success:
            print("✓ Send successful")
        else:
            print("✗ Send failed")
        
        if i < 2:  # Wait between sends
            time.sleep(1)
    
    print("\n=== Test Complete ===")
    print("Check Ada server output for received data")

if __name__ == "__main__":
    main()
