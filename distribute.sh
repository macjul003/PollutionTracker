#!/bin/bash

# Configuration
APP_NAME="PollutionTracker"
APP_BUNDLE="$APP_NAME.app"
ZIP_NAME="$APP_NAME.zip"

# Ensure clean build
echo "Running install script to build fresh app..."
./install.sh

if [ $? -ne 0 ]; then
    echo "Error: Build failed. Cannot package."
    exit 1
fi

# verification
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found."
    exit 1
fi

# Create Zip
echo "Creating $ZIP_NAME..."
# -r for recursive, -y to store symlinks as symlinks (important for apps)
zip -r -y "$ZIP_NAME" "$APP_BUNDLE"

if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "✅ Package created successfully: $ZIP_NAME"
    echo "You can now share '$ZIP_NAME' with your friends."
    echo "--------------------------------------------------------"
else
    echo "Error: Failed to create zip file."
    exit 1
fi
