#!/bin/bash
# Builds "build/Floating Todo.app". Run ./build.sh --install to also copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/Floating Todo.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/FloatingTodo "$APP/Contents/MacOS/FloatingTodo"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>FloatingTodo</string>
    <key>CFBundleIdentifier</key><string>com.kaylainoa.floatingtodo</string>
    <key>CFBundleName</key><string>Floating Todo</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf "/Applications/Floating Todo.app"
    cp -R "$APP" /Applications/
    echo "Installed to /Applications/Floating Todo.app"
fi
