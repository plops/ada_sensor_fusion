#!/usr/bin/env bash
set -eu

# Wrapper script to run commands with Ada SDK environment
# Usage: ./scripts/with-sdk.sh <command>

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the SDK setup
source "$SCRIPT_DIR/setup-sdk.sh"

# Execute the command with SDK environment
exec "$@"
