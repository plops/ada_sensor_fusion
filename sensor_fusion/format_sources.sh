#!/bin/bash

# Simple script to format Ada source files without project dependencies
GNATFORMAT="/home/kiel/.local/share/alire/builds/gnatformat_25.0.0_79117be8/0017788aafd4fb983d818a36b6d7e87c9112b471a9e515ddc947c370fe0a5392/bin/gnatformat"

# Format each source file individually
for file in src/*.adb src/*.ads; do
    if [ -f "$file" ]; then
        echo "Formatting $file..."
        $GNATFORMAT --pipe "$file" > "${file}.formatted"
        mv "${file}.formatted" "$file"
    fi
done

echo "Formatting complete!"
