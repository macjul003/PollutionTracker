#!/bin/bash

# Configuration
APP_NAME="PollutionTracker"
SOURCE_PLIST="Sources/PollutionTracker/Info.plist"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Using Info.plist from: $SOURCE_PLIST"

# Build the project
echo "Building $APP_NAME..."
swift build -c release

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

# Create App Bundle Structure
echo "Creating App Bundle..."
if [ -d "$APP_BUNDLE" ]; then
    rm -rf "$APP_BUNDLE"
fi

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
if [ -f "$SOURCE_PLIST" ]; then
    cp "$SOURCE_PLIST" "$CONTENTS_DIR/Info.plist"
else
    echo "Warning: Info.plist not found at $SOURCE_PLIST"
fi

# Package Widget Extension
WIDGET_PLIST="Sources/PollutionWidget/Info.plist"
PLUGINS_DIR="$CONTENTS_DIR/PlugIns"
WIDGET_BUNDLE="$PLUGINS_DIR/PollutionWidget.appex"
WIDGET_MACOS="$WIDGET_BUNDLE/Contents/MacOS"

echo "Packaging PollutionWidget..."
mkdir -p "$WIDGET_MACOS"
cp "$BUILD_DIR/PollutionWidget" "$WIDGET_MACOS/"
cp "$WIDGET_PLIST" "$WIDGET_BUNDLE/Contents/Info.plist"

# Remove PkgInfo if it exists, simple package doesn't need it but good practice to clean
# chmod +x "$MACOS_DIR/$APP_NAME"

echo "$APP_NAME.app created successfully!"

# Copy to /Applications
echo "Installing to /Applications..."
if [ -d "/Applications/$APP_BUNDLE" ]; then
    rm -rf "/Applications/$APP_BUNDLE"
fi
cp -R "$APP_BUNDLE" /Applications/

echo "$APP_NAME installed to /Applications successfully!"
echo "You can now launch it from your Applications folder or Spotlight."
