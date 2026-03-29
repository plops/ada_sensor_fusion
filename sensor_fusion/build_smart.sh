#!/bin/bash

# Smart build script that tries multiple approaches
# to work around the shared.gpr conflict

echo "=== Smart Sensor Fusion Build ==="

# Try approach 1: Minimal build first
echo "Trying minimal SPARK build..."
if gprbuild -p -P minimal_sensor_fusion.gpr -j0; then
    echo "✓ Minimal build successful!"
    echo "Run with: ./bin/sensor_fusion_minimal"
    exit 0
fi

# Try approach 2: Direct AWS build with explicit paths
echo "Trying direct AWS build..."
export ADA_INCLUDE_PATH="/home/kiel/.local/share/alire/releases/aws_25.2.0_bb26af84/include:$ADA_INCLUDE_PATH"
export ADA_OBJECTS_PATH="/home/kiel/.local/share/alire/releases/aws_25.2.0_bb26af84/lib:$ADA_OBJECTS_PATH"

if gprbuild -p -P sensor_fusion.gpr -j0; then
    echo "✓ AWS build successful!"
    exit 0
fi

# Try approach 3: Alire with workarounds
echo "Trying Alire with workarounds..."
if alr exec -- gprbuild -p -P sensor_fusion.gpr -j0; then
    echo "✓ Alire build successful!"
    exit 0
fi

echo "✗ All build methods failed"
echo "Recommendation: Use minimal build for SPARK development"
echo "Add HTTP server separately once core is verified"
exit 1
