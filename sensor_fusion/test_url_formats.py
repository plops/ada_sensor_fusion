#!/usr/bin/env python3
"""
Test different URL formats that Sensor Logger might use
"""
import requests
import json

def test_url_format():
    base_url = "http://10.0.0.146:8080"
    
    # Test different endpoints Sensor Logger might use
    endpoints = [
        "/data",
        "/", 
        "/api/data",
        "/sensor",
        "/push"
    ]
    
    test_data = {"test": "url_format_test", "timestamp": 1234567890}
    
    print("=== Testing Sensor Logger URL Formats ===")
    print(f"Base URL: {base_url}")
    print("")
    
    for endpoint in endpoints:
        url = base_url + endpoint
        try:
            print(f"Testing: {url}")
            response = requests.post(url, 
                               json=test_data,
                               timeout=3)
            print(f"  ✓ Response: {response.status_code}")
        except Exception as e:
            print(f"  ✗ Error: {e}")
        print("")

if __name__ == "__main__":
    test_url_format()
