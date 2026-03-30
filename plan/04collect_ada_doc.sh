#!/bin/bash  
  
# Comprehensive collection script for sensor fusion project  
# Combines all relevant source files, documentation, and configuration  
# into a single context file for planning AI model  
  
set -e  
  
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  
PLAN_DIR="$PROJECT_ROOT/plan"  
SENSOR_FUSION_DIR="$PROJECT_ROOT/sensor_fusion"  
SUBMODULE_DIR="$PROJECT_ROOT/awesome-sensor-logger"  
  
echo "Collecting comprehensive sensor fusion project context..."  
echo "Project root: $PROJECT_ROOT"  
echo "Plan directory: $PLAN_DIR"  
echo "Sensor fusion directory: $SENSOR_FUSION_DIR"  
echo "Submodule directory: $SUBMODULE_DIR"  
  
# Create collection directory  
mkdir -p "$PLAN_DIR/collected_context"  
  
# Create consolidated context file  
CONSOLIDATED_FILE="$PLAN_DIR/collected_context/comprehensive_project_context.md"  
echo "# Comprehensive Sensor Fusion Project Context" > "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "Generated on: $(date)" >> "$CONSOLIDATED_FILE"  
echo "Project: Ada Sensor Fusion with SPARK Verification" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "This file contains all relevant source files, documentation, and configuration for the sensor fusion project." >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
  
# Function to append file with header  
append_file() {  
    local file="$1"  
    local section="$2"  
    local relative_path="${file#$PROJECT_ROOT/}"  
      
    if [ -f "$file" ]; then  
        echo "## $section: $relative_path" >> "$CONSOLIDATED_FILE"  
        echo "" >> "$CONSOLIDATED_FILE"  
        echo '```' >> "$CONSOLIDATED_FILE"  
        cat "$file" >> "$CONSOLIDATED_FILE"  
        echo '```' >> "$CONSOLIDATED_FILE"  
        echo "" >> "$CONSOLIDATED_FILE"  
        echo "---" >> "$CONSOLIDATED_FILE"  
        echo "" >> "$CONSOLIDATED_FILE"  
    fi  
}  
  
# Function to append directory contents  
append_directory() {  
    local dir="$1"  
    local pattern="$2"  
    local section="$3"  
      
    if [ -d "$dir" ]; then  
        find "$dir" -name "$pattern" -type f | sort | while read file; do  
            local basename=$(basename "$file")  
            append_file "$file" "$section" "$basename"  
        done  
    fi  
}  
  
echo "=== COLLECTING PLANNING DOCUMENTS ==="  
  
# Core planning documents  
append_file "$PLAN_DIR/03implementation_plan.md" "IMPLEMENTATION PLAN"  
append_file "$PLAN_DIR/02prompt.md" "PROJECT PROMPT"  
append_file "$PLAN_DIR/dependencies.md" "DEPENDENCIES"  
append_file "$PROJECT_ROOT/dependencies.md" "ROOT DEPENDENCIES"  
append_file "$PROJECT_ROOT/.gitmodules" "GIT SUBMODULES"  
  
echo "=== COLLECTING PROJECT DOCUMENTATION ==="  
  
# Main README files  
append_file "$PROJECT_ROOT/README.md" "PROJECT README"  
append_file "$SENSOR_FUSION_DIR/README_FUSION_COMPLETE.md" "FUSION COMPLETE README"  
append_file "$SENSOR_FUSION_DIR/BUILD_GUIDE.md" "BUILD GUIDE"  
append_file "$SENSOR_FUSION_DIR/USAGE_GUIDE.md" "USAGE GUIDE"  
append_file "$SENSOR_FUSION_DIR/DATA_ACQUISITION_SUCCESS.md" "DATA ACQUISITION SUCCESS"  
append_file "$SENSOR_FUSION_DIR/SHARED_CONFLICT_RESOLUTION.md" "SHARED CONFLICT RESOLUTION"  
  
echo "=== COLLECTING SENSOR LOGGER DOCUMENTATION ==="  
  
# Key sensor logger documentation  
append_file "$SUBMODULE_DIR/README.md" "SENSOR LOGGER README"  
append_file "$SUBMODULE_DIR/COORDINATES.md" "COORDINATE SYSTEMS"  
append_file "$SUBMODULE_DIR/UNITS.md" "SENSOR UNITS"  
append_file "$SUBMODULE_DIR/SAMPLING.md" "SAMPLING RATES"  
append_file "$SUBMODULE_DIR/PUSHING.md" "HTTP PUSHING"  
append_file "$SUBMODULE_DIR/CROSSPLATFORM.md" "CROSS PLATFORM"  
append_file "$SUBMODULE_DIR/ORIENTATION.md" "ORIENTATION SENSORS"  
append_file "$SUBMODULE_DIR/STUDY_API.md" "API STUDY"  
append_file "$SUBMODULE_DIR/STUDY_WEBHOOKS.md" "WEBHOOK STUDY"  
append_file "$SUBMODULE_DIR/STUDY_DATA_DELIVERY.md" "DATA DELIVERY STUDY"  
  
echo "=== COLLECTING ADA SOURCE CODE ==="  
  
# Core SPARK packages (most important for verification)  
append_file "$SENSOR_FUSION_DIR/src/sensors.ads" "SPARK SENSORS SPEC"  
append_file "$SENSOR_FUSION_DIR/src/sensors.adb" "SPARK SENSERS BODY"  
append_file "$SENSOR_FUSION_DIR/src/math_library.ads" "SPARK MATH LIBRARY SPEC"  
append_file "$SENSOR_FUSION_DIR/src/math_library.adb" "SPARK MATH LIBRARY BODY"  
append_file "$SENSOR_FUSION_DIR/src/platform_normalizer.ads" "PLATFORM NORMALIZER SPEC"  
append_file "$SENSOR_FUSION_DIR/src/platform_normalizer.adb" "PLATFORM NORMALIZER BODY"  
append_file "$SENSOR_FUSION_DIR/src/alignment_engine.ads" "ALIGNMENT ENGINE SPEC"  
append_file "$SENSOR_FUSION_DIR/src/alignment_engine.adb" "ALIGNMENT ENGINE BODY"  
append_file "$SENSOR_FUSION_DIR/src/sensor_fusion_engine.ads" "FUSION ENGINE SPEC"  
append_file "$SENSOR_FUSION_DIR/src/sensor_fusion_engine.adb" "FUSION ENGINE BODY"  
  
# Integration and server components  
append_file "$SENSOR_FUSION_DIR/src/phone_sensor_integration.ads" "PHONE INTEGRATION SPEC"  
append_file "$SENSOR_FUSION_DIR/src/phone_sensor_integration.adb" "PHONE INTEGRATION BODY"  
append_file "$SENSOR_FUSION_DIR/src/ultra_simple_server.adb" "HTTP SERVER"  
append_file "$SENSOR_FUSION_DIR/src/fusion_demo.adb" "FUSION DEMO"  
append_file "$SENSOR_FUSION_DIR/src/strapped_phones_test.adb" "STRAPPED PHONES TEST"  
  
echo "=== COLLECTING BUILD CONFIGURATION ==="  
  
# Project files and build configuration  
append_file "$SENSOR_FUSION_DIR/alire.toml" "ALIRE CONFIGURATION"  
append_file "$SENSOR_FUSION_DIR/sensor_fusion.gpr" "MAIN PROJECT FILE"  
append_file "$SENSOR_FUSION_DIR/minimal_sensor_fusion.gpr" "MINIMAL SPARK PROJECT"  
append_file "$SENSOR_FUSION_DIR/fusion_demo.gpr" "FUSION DEMO PROJECT"  
append_file "$SENSOR_FUSION_DIR/local_shared.gpr" "LOCAL SHARED CONFIG"  
append_file "$SENSOR_FUSION_DIR/custom_aws_config.gpr" "AWS CONFIG"  
  
echo "=== COLLECTING BUILD SCRIPTS ==="  
  
# Essential build and test scripts  
append_file "$SENSOR_FUSION_DIR/build_aws_server.sh" "AWS BUILD SCRIPT"  
append_file "$SENSOR_FUSION_DIR/build_smart.sh" "SMART BUILD SCRIPT"  
append_file "$SENSOR_FUSION_DIR/test_capture.sh" "TEST CAPTURE SCRIPT"  
append_file "$SENSOR_FUSION_DIR/run_ada_server.sh" "RUN SERVER SCRIPT"  
append_file "$SENSOR_FUSION_DIR/fix_shared_conflict.sh" "FIX CONFLICTS SCRIPT"  
append_file "$SENSOR_FUSION_DIR/format_sources.sh" "FORMAT SOURCES SCRIPT"  
  
echo "=== COLLECTING PYTHON UTILITIES ==="  
  
# Python server and test utilities  
append_file "$SENSOR_FUSION_DIR/verify_phones_8080.py" "PYTHON VERIFICATION SERVER"  
append_file "$SENSOR_FUSION_DIR/test_data_capture.py" "PYTHON TEST CLIENT"  
append_file "$SENSOR_FUSION_DIR/capture_phone_data.py" "PHONE DATA CAPTURE"  
append_file "$SENSOR_FUSION_DIR/simulate_phone.py" "PHONE SIMULATOR"  
  
echo "=== COLLECTING CONFIGURATION FILES ==="  
  
# Configuration files  
append_file "$SENSOR_FUSION_DIR/config/sensor_fusion_config.ads" "SENSOR FUSION CONFIG SPEC"  
append_file "$SENSOR_FUSION_DIR/config/sensor_fusion_config.gpr" "SENSOR FUSION CONFIG PROJECT"  
  
echo "=== COLLECTING SAMPLE DATA ==="  
  
# Sample data files (if they exist and are not too large)  
if [ -f "$SENSOR_FUSION_DIR/captured_sensor_data.json" ] && [ $(stat -f%z "$SENSOR_FUSION_DIR/captured_sensor_data.json" 2>/dev/null || stat -c%s "$SENSOR_FUSION_DIR/captured_sensor_data.json" 2>/dev/null || echo 0) -lt 100000 ]; then  
    append_file "$SENSOR_FUSION_DIR/captured_sensor_data.json" "SAMPLE SENSOR DATA"  
fi  
  
# CSV sample (first 50 lines only)  
if [ -f "$SENSOR_FUSION_DIR/phone_data_20260329_203954.csv" ]; then  
    echo "## SAMPLE DATA: phone_data_20260329_203954.csv (first 50 lines)" >> "$CONSOLIDATED_FILE"  
    echo "" >> "$CONSOLIDATED_FILE"  
    echo '```' >> "$CONSOLIDATED_FILE"  
    head -50 "$SENSOR_FUSION_DIR/phone_data_20260329_203954.csv" >> "$CONSOLIDATED_FILE"  
    echo '```' >> "$CONSOLIDATED_FILE"  
    echo "" >> "$CONSOLIDATED_FILE"  
    echo "---" >> "$CONSOLIDATED_FILE"  
    echo "" >> "$CONSOLIDATED_FILE"  
fi  
  
echo "=== CREATING PROJECT SUMMARY ==="  
  
# Add project summary at the end  
echo "# Project Summary" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "## Key Components Collected:" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "### Planning & Documentation" >> "$CONSOLIDATED_FILE"  
echo "- Implementation plan with 5-step roadmap" >> "$CONSOLIDATED_FILE"  
echo "- Project dependencies and setup requirements" >> "$CONSOLIDATED_FILE"  
echo "- Build guides and usage instructions" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "### SPARK Verification Core" >> "$CONSOLIDATED_FILE"  
echo "- Sensors package with formal contracts" >> "$CONSOLIDATED_FILE"  
echo "- Math library with quaternion operations" >> "$CONSOLIDATED_FILE"  
echo "- Platform normalizer for iOS/Android differences" >> "$CONSOLIDATED_FILE"  
echo "- Alignment engine for multi-device synchronization" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "### Integration Layer" >> "$CONSOLIDATED_FILE"  
echo "- HTTP server for receiving sensor data" >> "$CONSOLIDATED_FILE"  
echo "- Phone sensor integration for device management" >> "$CONSOLIDATED_FILE"  
echo "- Real-time data processing and validation" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "### Build & Test Infrastructure" >> "$CONSOLIDATED_FILE"  
echo "- Multiple build strategies for different environments" >> "$CONSOLIDATED_FILE"  
echo "- Python utilities for testing and validation" >> "$CONSOLIDATED_FILE"  
echo "- Comprehensive test suites and examples" >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
echo "## Implementation Status: COMPLETE" >> "$CONSOLIDATED_FILE"  
echo "All 5 implementation steps have been completed with real phone data validation." >> "$CONSOLIDATED_FILE"  
echo "" >> "$CONSOLIDATED_FILE"  
  
# Get final file size  
FILE_SIZE=$(wc -l < "$CONSOLIDATED_FILE")  
echo "Comprehensive context file created: $CONSOLIDATED_FILE"  
echo "Total lines: $FILE_SIZE"  
echo "File size: $(du -h "$CONSOLIDATED_FILE" | cut -f1)"  
  
# Create a shorter version for quick reference  
QUICK_FILE="$PLAN_DIR/collected_context/quick_reference.md"  
echo "# Sensor Fusion Project - Quick Reference" > "$QUICK_FILE"  
echo "" >> "$QUICK_FILE"  
echo "## Key Files for Planning AI:" >> "$QUICK_FILE"  
echo "" >> "$QUICK_FILE"  
echo "1. **Implementation Plan**: plan/03implementation_plan.md" >> "$QUICK_FILE"  
echo "2. **Project Structure**: sensor_fusion/README_FUSION_COMPLETE.md" >> "$QUICK_FILE"  
echo "3. **Build Guide**: sensor_fusion/BUILD_GUIDE.md" >> "$QUICK_FILE"  
echo "4. **SPARK Core**: sensor_fusion/src/sensors.ads" >> "$QUICK_FILE"  
echo "5. **Math Library**: sensor_fusion/src/math_library.ads" >> "$QUICK_FILE"  
echo "6. **Dependencies**: dependencies.md" >> "$QUICK_FILE"  
echo "" >> "$QUICK_FILE"  
echo "For complete context, see: comprehensive_project_context.md" >> "$QUICK_FILE"  
  
echo "Quick reference created: $QUICK_FILE"  
echo ""  
echo "Collection complete! Use comprehensive_project_context.md for full context or quick_reference.md for key files."

