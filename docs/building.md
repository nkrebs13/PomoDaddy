# Building PomoDaddy

This document covers building, code signing, and distributing PomoDaddy.

## Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **XcodeGen**: For project file generation

## Development Setup

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Generate Xcode Project

```bash
cd /path/to/PomoDaddy
xcodegen generate
```

This creates `PomoDaddy.xcodeproj` from `project.yml`.

### 3. Open and Build

```bash
open PomoDaddy.xcodeproj
```

In Xcode:
- Select the `PomoDaddy` scheme
- Choose `My Mac` as destination
- Build with Cmd+B or Run with Cmd+R

## Build Configurations

| Configuration | Use Case |
|---------------|----------|
| Debug | Development, debugging |
| Release | Distribution, performance testing |

## Code Signing

### Development (Automatic)

The project uses automatic code signing by default:

```yaml
# project.yml
CODE_SIGN_STYLE: Automatic
DEVELOPMENT_TEAM: ""  # Set your team ID
```

Set your development team:
1. Open Xcode project settings
2. Select PomoDaddy target
3. Under Signing & Capabilities, select your team

### Distribution (Manual)

For direct distribution outside the App Store:

1. **Create Developer ID Certificate**
   - Open Keychain Access
   - Certificate Assistant > Request Certificate from Authority
   - In Apple Developer portal, create Developer ID Application certificate

2. **Configure Project**
   ```yaml
   CODE_SIGN_STYLE: Manual
   CODE_SIGN_IDENTITY: "Developer ID Application: Your Name (TEAM_ID)"
   DEVELOPMENT_TEAM: "TEAM_ID"
   ```

3. **Build for Distribution**
   ```bash
   xcodebuild -scheme PomoDaddy \
     -configuration Release \
     -archivePath build/PomoDaddy.xcarchive \
     archive
   ```

## Notarization

Apple requires notarization for distribution outside the App Store.

### Prerequisites

- Apple Developer account
- Developer ID Application certificate
- App-specific password for notarization

### Notarization Steps

1. **Create Archive**
   ```bash
   xcodebuild -scheme PomoDaddy \
     -configuration Release \
     -archivePath build/PomoDaddy.xcarchive \
     archive
   ```

2. **Export App**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/PomoDaddy.xcarchive \
     -exportPath build/export \
     -exportOptionsPlist ExportOptions.plist
   ```

   Create `ExportOptions.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>developer-id</string>
       <key>teamID</key>
       <string>YOUR_TEAM_ID</string>
   </dict>
   </plist>
   ```

3. **Submit for Notarization**
   ```bash
   xcrun notarytool submit build/export/PomoDaddy.app.zip \
     --apple-id "your@email.com" \
     --team-id "TEAM_ID" \
     --password "@keychain:AC_PASSWORD" \
     --wait
   ```

4. **Staple Ticket**
   ```bash
   xcrun stapler staple build/export/PomoDaddy.app
   ```

## Creating DMG

For user-friendly distribution, package the app in a DMG.

### Using create-dmg

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "PomoDaddy" \
  --volicon "PomoDaddy/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "PomoDaddy.app" 150 190 \
  --hide-extension "PomoDaddy.app" \
  --app-drop-link 450 190 \
  "PomoDaddy-1.0.0.dmg" \
  "build/export/"
```

### Manual DMG Creation

1. Create a new disk image in Disk Utility
2. Mount the image
3. Copy `PomoDaddy.app` to the mounted volume
4. Create alias to `/Applications`
5. Arrange icons
6. Unmount and convert to read-only DMG

## Troubleshooting

### Build Errors

**"No signing certificate found"**
- Ensure you have a valid Developer ID certificate
- Check Keychain Access for the certificate
- Verify team ID in project settings

**"Hardened Runtime required"**
- Already enabled in `project.yml` (`ENABLE_HARDENED_RUNTIME: YES`)
- Verify entitlements file exists

### Notarization Errors

**"The signature is invalid"**
- Ensure hardened runtime is enabled
- Check all frameworks are signed
- Verify no unsigned code in bundle

**"The binary uses an SDK older than..."**
- Update deployment target in `project.yml`
- Rebuild with latest Xcode

## Continuous Integration

Example GitHub Actions workflow for building:

```yaml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Project
        run: xcodegen generate

      - name: Build
        run: xcodebuild -scheme PomoDaddy -configuration Debug build
```
