#!/usr/bin/env bash
set -eu

# SDK Setup Script for Ada Sensor Fusion Project
# This script configures the environment to use the Ada SDK

# Default SDK path - can be overridden with ADA_SDK_PATH environment variable
DEFAULT_SDK_PATH="/home/kiel/stage/ada_lisp/.toolchains/adacore-community"
SDK_PATH="${ADA_SDK_PATH:-$DEFAULT_SDK_PATH}"

# Alire path
ALIRE_PATH="${HOME}/Downloads/alire/bin/alr"

# Check if SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "Error: Ada SDK not found at $SDK_PATH"
    echo "Please set ADA_SDK_PATH environment variable to the correct SDK location"
    echo "Example: export ADA_SDK_PATH=/path/to/your/ada-sdk"
    exit 1
fi

# Check if essential tools are available
if [ ! -x "$SDK_PATH/bin/gnat" ]; then
    echo "Error: GNAT not found in $SDK_PATH/bin"
    exit 1
fi

if [ ! -x "$SDK_PATH/bin/gprbuild" ]; then
    echo "Error: GPRBuild not found in $SDK_PATH/bin"
    exit 1
fi

# Export environment variables
export PATH="$SDK_PATH/bin:$PATH"
export ADA_OBJECTS_PATH="$SDK_PATH/lib/gcc/x86_64-pc-linux-gnu/15.2.0/adalib"
export ADA_INCLUDE_PATH="$SDK_PATH/lib/gcc/x86_64-pc-linux-gnu/15.2.0/adainclude"
export GPR_PROJECT_PATH="$SDK_PATH/share/gpr"

# Add Alire to PATH if it exists
if [ -x "$ALIRE_PATH" ]; then
    export PATH="$HOME/Downloads/alire/bin:$PATH"
    echo "Alire found: $(alr version 2>/dev/null || echo 'Version unknown')"
else
    echo "Warning: Alire not found at $ALIRE_PATH"
fi

echo "Ada SDK configured successfully"
echo "SDK Path: $SDK_PATH"
echo "GNAT Version: $(gnat version 2>/dev/null || echo 'Unknown')"

# Execute any additional arguments
exec "$@"
