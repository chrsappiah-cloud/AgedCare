#!/bin/bash
set -e

echo "=== AgedCare App Launcher ==="

# 1. Start backend
if lsof -ti:8081 &>/dev/null; then
  echo "✅ Backend already running on port 8081"
else
  echo "Starting backend server..."
  nohup python3 backend/server.py > /tmp/agedcare_backend.log 2>&1 &
  sleep 2
  echo "✅ Backend started (PID $!)"
fi

# 2. Boot simulator
if xcrun simctl list devices 2>&1 | grep -q "AgedCare-Phone.*Booted"; then
  echo "✅ Simulator already booted"
else
  echo "Booting AgedCare-Phone simulator..."
  xcrun simctl boot "AgedCare-Phone" 2>&1
  sleep 3
  echo "✅ Simulator booted"
fi

# 3. Build and install
echo "Building app..."
xcodebuild -scheme AgedCareApp -project AgedCare.xcodeproj -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3

APP_PATH=$(xcodebuild -scheme AgedCareApp -project AgedCare.xcodeproj -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -showBuildSettings CODE_SIGNING_ALLOWED=NO 2>/dev/null | grep BUILT_PRODUCTS_DIR | head -1 | awk '{print $3}')/AgedCareApp.app
xcrun simctl install "AgedCare-Phone" "$APP_PATH" 2>&1
xcrun simctl launch "AgedCare-Phone" com.agedcare.app 2>&1

echo ""
echo "=== All systems go ==="
echo "  Backend:  http://localhost:8081"
echo "  Simulator: open -a Simulator"
echo "  Login:     admin@gvcare.com / password"