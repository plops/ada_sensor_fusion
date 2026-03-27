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

# Create consolidated documentation file for planning AI
echo "Creating consolidated documentation file..."
CONSOLIDATED_FILE="$PLAN_DIR/collected_docs/consolidated_documentation.md"
echo "# Consolidated Sensor Fusion Documentation" > "$CONSOLIDATED_FILE"
echo "" >> "$CONSOLIDATED_FILE"
echo "This file contains relevant documentation from the awesome-sensor-logger submodule for planning the sensor fusion project." >> "$CONSOLIDATED_FILE"
echo "" >> "$CONSOLIDATED_FILE"

# Function to append file with header
append_file() {
    local file="$1"
    local relative_path="${file#$SUBMODULE_DIR/}"
    echo "## File: $relative_path" >> "$CONSOLIDATED_FILE"
    echo "" >> "$CONSOLIDATED_FILE"
    cat "$file" >> "$CONSOLIDATED_FILE"
    echo "" >> "$CONSOLIDATED_FILE"
    echo "---" >> "$CONSOLIDATED_FILE"
    echo "" >> "$CONSOLIDATED_FILE"
}

# Most relevant: Sensor Logger app documentation (since you decided to use it)
echo "Adding Sensor Logger documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "sensor.*logger\|tszheichoi" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

# Coordinate system documentation (important for device differences)
echo "Adding coordinate system documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "coordinate\|axis\|orientation\|quaternion" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

# iOS sensor documentation
echo "Adding iOS sensor documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "ios\|iphone\|apple.*sensor" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

# Android sensor documentation  
echo "Adding Android sensor documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "android.*sensor\|samsung.*sensor" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

# HTTP streaming and protocol documentation
echo "Adding HTTP streaming documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "http.*stream\|http.*post\|network.*sensor" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

# General sensor fusion and processing documentation
echo "Adding sensor fusion documentation..."
find "$SUBMODULE_DIR" -name "*.md" -exec grep -l -i "sensor.*fusion\|kalman\|filter\|accelerometer.*gyroscope.*magnetometer" {} \; | sort | while read file; do
    echo "Processing: $file"
    append_file "$file"
done

echo "Consolidated documentation created: $CONSOLIDATED_FILE"
echo "File size: $(wc -l < "$CONSOLIDATED_FILE") lines"
