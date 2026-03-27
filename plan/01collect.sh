#!/bin/bash

# Collection script for sensor fusion project planning
# This script gathers relevant documentation and resources from the submodule
# to provide context for a planning AI

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE_DIR="$PROJECT_ROOT/awesome-sensor-logger"
PLAN_DIR="$PROJECT_ROOT/plan"

echo "Collecting sensor fusion project documentation..."
echo "Project root: $PROJECT_ROOT"
echo "Submodule directory: $SUBMODULE_DIR"
echo "Plan directory: $PLAN_DIR"

# Create collection directories
mkdir -p "$PLAN_DIR/collected_docs"
mkdir -p "$PLAN_DIR/collected_docs/apps"
mkdir -p "$PLAN_DIR/collected_docs/libraries"
mkdir -p "$PLAN_DIR/collected_docs/protocols"

# Collect README and main documentation
if [ -f "$SUBMODULE_DIR/README.md" ]; then
    echo "Copying main README..."
    cp "$SUBMODULE_DIR/README.md" "$PLAN_DIR/collected_docs/00_main_readme.md"
fi

# Collect iOS app information
echo "Collecting iOS sensor app documentation..."
find "$SUBMODULE_DIR" -name "*.md" -path "*/ios/*" -o -name "*.md" -path "*iPhone*" -o -name "*.md" -path "*iOS*" | while read file; do
    cp "$file" "$PLAN_DIR/collected_docs/apps/"
done

# Collect Android app information  
echo "Collecting Android sensor app documentation..."
find "$SUBMODULE_DIR" -name "*.md" -path "*/android/*" -o -name "*.md" -path "*Android*" | while read file; do
    cp "$file" "$PLAN_DIR/collected_docs/apps/"
done

# Collect cross-platform solutions
echo "Collecting cross-platform sensor solutions..."
find "$SUBMODULE_DIR" -name "*.md" | grep -i -E "(cross|platform|universal|multi)" | while read file; do
    cp "$file" "$PLAN_DIR/collected_docs/apps/"
done

# Collect protocol and streaming information
echo "Collecting protocol and streaming documentation..."
find "$SUBMODULE_DIR" -name "*.md" | grep -i -E "(protocol|stream|udp|tcp|mqtt|websocket|network)" | while read file; do
    cp "$file" "$PLAN_DIR/collected_docs/protocols/"
done

# Collect library information
echo "Collecting sensor library documentation..."
find "$SUBMODULE_DIR" -name "*.md" | grep -i -E "(library|lib|sdk|api)" | while read file; do
    cp "$file" "$PLAN_DIR/collected_docs/libraries/"
done

# Extract key app names and URLs for quick reference
echo "Extracting key sensor apps and tools..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "sensor.*log\|sensor.*stream\|sensor.*logger" {} \; > "$PLAN_DIR/collected_docs/key_apps.txt"

# Create a summary of available apps by platform
echo "Creating platform-specific app summaries..."
echo "# iOS Apps" > "$PLAN_DIR/collected_docs/ios_apps.md"
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "ios\|iphone\|apple" {} \; | while read file; do
    echo "## $(basename "$file")" >> "$PLAN_DIR/collected_docs/ios_apps.md"
    grep -i -A 5 -B 5 "sensor.*log\|sensor.*stream\|sensor.*logger" "$file" >> "$PLAN_DIR/collected_docs/ios_apps.md" || true
    echo "" >> "$PLAN_DIR/collected_docs/ios_apps.md"
done

echo "# Android Apps" > "$PLAN_DIR/collected_docs/android_apps.md"
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "android\|samsung\|xiaomi\|realme" {} \; | while read file; do
    echo "## $(basename "$file")" >> "$PLAN_DIR/collected_docs/android_apps.md"
    grep -i -A 5 -B 5 "sensor.*log\|sensor.*stream\|sensor.*logger" "$file" >> "$PLAN_DIR/collected_docs/android_apps.md" || true
    echo "" >> "$PLAN_DIR/collected_docs/android_apps.md"
done

# Create a consolidated protocol summary
echo "Creating protocol summary..."
echo "# Sensor Data Protocols" > "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "## Common protocols for sensor data streaming:" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "- UDP (low latency, preferred for real-time sensor fusion)" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "- TCP (reliable delivery)" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "- HTTP/HTTPS (REST APIs)" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "- MQTT (lightweight messaging)" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "- WebSockets (real-time web communication)" >> "$PLAN_DIR/collected_docs/protocols_summary.md"
echo "" >> "$PLAN_DIR/collected_docs/protocols_summary.md"

# Count collected files
TOTAL_FILES=$(find "$PLAN_DIR/collected_docs" -name "*.md" | wc -l)
echo "Collection complete. Gathered $TOTAL_FILES documentation files."

# Create a quick reference for the planning AI
cat > "$PLAN_DIR/collected_docs/project_context.md" << EOF
# Sensor Fusion Learning Project Context

## Goal
Implement sensor fusion algorithms in Ada/SPARK using data from multiple mobile devices.

## Available Devices
- iPhone 11 (iOS)
- Samsung S10e (Android)
- Samsung A54 (Android) 
- Xiaomi Mi4C (Android)
- Realme C11 2021 (Android)

## Target Architecture
- Mobile devices stream sensor data (accelerometer, gyroscope, magnetometer) over network
- Ada/SPARK program receives and processes data streams
- Implement sensor fusion algorithms (Kalman filters, complementary filters, etc.)
- Multi-device synchronization and data fusion

## Key Requirements
- Cross-platform sensor data collection
- Network protocols for real-time data streaming
- Ada/SPARK implementation with formal verification capabilities
- Timestamp synchronization across devices
- Real-time processing capabilities

## Next Steps for Planning AI
1. Analyze available sensor streaming apps for each platform
2. Recommend optimal data collection strategy
3. Design Ada/SPARK architecture for sensor fusion
4. Plan implementation phases and milestones
EOF

echo "Documentation collection completed successfully!"
echo "Files are ready in: $PLAN_DIR/collected_docs/"
echo "Provide this directory to your planning AI for project analysis."
