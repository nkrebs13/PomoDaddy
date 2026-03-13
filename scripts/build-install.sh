#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="PomoDaddy"
INSTALL_DIR="/Applications"

echo "==> Cleaning build artifacts..."
rm -rf "$BUILD_DIR"

echo "==> Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate

echo "==> Building $APP_NAME (Release)..."
xcodebuild build \
    -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    DEVELOPMENT_TEAM="" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tail -20

APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "$APP_NAME.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Build failed — $APP_NAME.app not found in build output"
    exit 1
fi

# Ad-hoc sign
codesign --force --deep -s "-" "$APP_PATH"

# Create release zip
cd "$(dirname "$APP_PATH")"
ditto -c -k --keepParent "$APP_NAME.app" "$BUILD_DIR/$APP_NAME.zip"
echo "==> Release zip: $BUILD_DIR/$APP_NAME.zip"

# Install to /Applications
echo "==> Installing to $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "    Removing existing $APP_NAME.app..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

cp -R "$APP_PATH" "$INSTALL_DIR/$APP_NAME.app"
echo "==> Installed: $INSTALL_DIR/$APP_NAME.app"

# Clean DerivedData but keep the zip
rm -rf "$BUILD_DIR/DerivedData"

echo "==> Done! $APP_NAME installed to $INSTALL_DIR."
echo "    Release zip at: $BUILD_DIR/$APP_NAME.zip"
