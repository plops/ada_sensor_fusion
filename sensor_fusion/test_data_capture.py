#!/usr/bin/env python3
"""
Test script to verify the Ada server data capture functionality.
This simulates the Sensor Logger app data format.
"""

import requests
import json
import time
import random

def create_sensor_data(sensor_name, timestamp, values):
    """Create a sensor data entry in the real Sensor Logger format."""
    return {
        "name": sensor_name,
        "values": values,
        "accuracy": 3,
        "time": timestamp
    }

def create_payload(sensor_readings):
    """Create the full payload expected by the Ada server."""
    return {
        "payload": sensor_readings
    }

def test_iphone_data():
    """Test with iPhone-like data."""
    print("Testing iPhone data capture...")
    
    # Create sample accelerometer data
    timestamp = int(time.time() * 1e9)  # nanoseconds
    readings = []
    
    for i in range(10):
        readings.append(create_sensor_data(
            "accelerometer",
            timestamp + i * 100000000,  # 100ms intervals
            {
                "x": round(random.uniform(-2.0, 2.0), 6),
                "y": round(random.uniform(-2.0, 2.0), 6), 
                "z": round(random.uniform(9.0, 11.0), 6)
            }
        ))
    
    payload = create_payload(readings)
    
    try:
        response = requests.post("http://localhost:8080/data", 
                               json=payload, 
                               timeout=5)
        print(f"iPhone test response: {response.status_code}")
        print(f"Response body: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending iPhone data: {e}")

def test_samsung_data():
    """Test with Samsung/Android data."""
    print("Testing Samsung data capture...")
    
    # Create sample gyroscope data
    timestamp = int(time.time() * 1e9)  # nanoseconds
    readings = []
    
    for i in range(10):
        readings.append(create_sensor_data(
            "gyroscopeuncalibrated",
            timestamp + i * 100000000,  # 100ms intervals
            {
                "x": round(random.uniform(-1.0, 1.0), 6),
                "y": round(random.uniform(-1.0, 1.0), 6),
                "z": round(random.uniform(-1.0, 1.0), 6)
            }
        ))
    
    payload = create_payload(readings)
    
    try:
        response = requests.post("http://localhost:8080/data", 
                               json=payload, 
                               timeout=5)
        print(f"Samsung test response: {response.status_code}")
        print(f"Response body: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending Samsung data: {e}")

def test_mixed_sensors():
    """Test with multiple sensor types."""
    print("Testing mixed sensor data...")
    
    timestamp = int(time.time() * 1e9)
    readings = []
    
    # Add different sensor types
    readings.append(create_sensor_data(
        "accelerometer",
        timestamp,
        {
            "x": round(0.1, 6),
            "y": round(0.2, 6),
            "z": round(9.8, 6)
        }
    ))
    
    readings.append(create_sensor_data(
        "gyroscopeuncalibrated", 
        timestamp + 50000000,
        {
            "x": round(0.01, 6),
            "y": round(-0.02, 6),
            "z": round(0.03, 6)
        }
    ))
    
    readings.append(create_sensor_data(
        "magnetometeruncalibrated",
        timestamp + 100000000,
        {
            "x": round(25.0, 6),
            "y": round(-15.0, 6),
            "z": round(45.0, 6)
        }
    ))
    
    readings.append(create_sensor_data(
        "orientation",
        timestamp + 150000000,
        {
            "qw": round(0.9, 6),
            "qx": round(0.1, 6),
            "qy": round(0.2, 6),
            "qz": round(0.3, 6),
            "roll": round(1.57, 6),
            "pitch": round(0.78, 6),
            "yaw": round(0.39, 6)
        }
    ))
    
    payload = create_payload(readings)
    
    try:
        response = requests.post("http://localhost:8080/data", 
                               json=payload, 
                               timeout=5)
        print(f"Mixed sensor test response: {response.status_code}")
        print(f"Response body: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending mixed data: {e}")

if __name__ == "__main__":
    print("Testing Ada server data capture functionality...")
    print("Make sure the Ada server is running on localhost:8080")
    print()
    
    # Wait a moment for user to ensure server is running
    input("Press Enter to start testing...")
    
    test_iphone_data()
    print()
    time.sleep(1)
    
    test_samsung_data()
    print()
    time.sleep(1)
    
    test_mixed_sensors()
    print()
    
    print("Testing complete! Check the server output and generated CSV files.")
