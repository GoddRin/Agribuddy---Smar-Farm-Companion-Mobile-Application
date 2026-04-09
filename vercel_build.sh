#!/bin/bash

# 1. Stop on any error
set -e

# 2. SECURITY: Tell Git to trust the directories we create on Vercel
git config --global --add safe.directory '*'

echo "📦 Upgrading to newest Flutter Power-Pack (Stable 3.27.3)..."

# 3. Download the NEWEST version to support permission_handler and Dart 3.5+
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz

echo "🔓 Unwrapping the new engine..."
tar xf flutter_linux_3.27.3-stable.tar.xz

# 4. Add to path
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Web..."
flutter config --no-analytics
flutter config --enable-web

# 5. Build
echo "📦 Fetching AgriBuddy packages..."
flutter pub get

echo "🚀 Compiling Web Production Build..."
flutter build web --release --base-href /

echo "✅ Success! AgriBuddy is LIVE."
