#!/usr/bin/env bash
# Source this file to set up the Ada SDK environment in your shell
# Usage: source scripts/env.sh

# Default SDK path - can be overridden with ADA_SDK_PATH environment variable
DEFAULT_SDK_PATH="/home/kiel/stage/ada_lisp/.toolchains/adacore-community"
SDK_PATH="${ADA_SDK_PATH:-$DEFAULT_SDK_PATH}"

# Check if SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "Warning: Ada SDK not found at $SDK_PATH"
    echo "Please set ADA_SDK_PATH environment variable to the correct SDK location"
    return 1 2>/dev/null || exit 1
fi

# Export environment variables
export PATH="$SDK_PATH/bin:$PATH"
export ADA_OBJECTS_PATH="$SDK_PATH/lib/gcc/x86_64-pc-linux-gnu/15.2.0/adalib"
export ADA_INCLUDE_PATH="$SDK_PATH/lib/gcc/x86_64-pc-linux-gnu/15.2.0/adainclude"
export GPR_PROJECT_PATH="$SDK_PATH/share/gpr"

echo "Ada SDK environment configured"
echo "SDK Path: $SDK_PATH"
