#!/bin/bash

# 1. Stop on any error
set -e

# 2. IDENTITY FIX: Ensure Flutter knows exactly who is running it
# This clears the "Woah! You appear to be trying to run flutter as root" warning
echo "🏗️ Setting up user permissions for $(whoami)..."
git config --global --add safe.directory '*'

echo "📦 Downloading Flutter Power-Pack (Stable 3.27.3)..."

# 3. Download and unwrap
if [ ! -d "flutter" ]; then
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz
  tar xf flutter_linux_3.27.3-stable.tar.xz
fi

# 4. PERMISSION RESET
# This is the "Master Key" for Vercel permissions
chown -R $(whoami) . || true

# 5. Setup Path
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Web..."
flutter config --no-analytics
flutter config --enable-web

# 6. Build
echo "📦 Fetching AgriBuddy packages..."
flutter pub get

echo "🚀 Compiling Web Production Build..."
# Adding --no-pub ensures we don't trigger the root check twice
flutter build web --release --base-href / --no-pub

echo "✅ Success! AgriBuddy is LIVE."
