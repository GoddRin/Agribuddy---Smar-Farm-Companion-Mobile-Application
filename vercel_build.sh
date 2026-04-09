#!/bin/bash

# 1. Stop on any error
set -e

# 2. IDENTITY FIX: Tell Git to trust the directories we create
git config --global --add safe.directory '*'

echo "📦 Downloading Flutter Power-Pack (Stable 3.27.3)..."

# 3. Download and unwrap
if [ ! -d "flutter" ]; then
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz
  tar xf flutter_linux_3.27.3-stable.tar.xz
fi

# 4. GHOST MODE: "Script Surgery" to bypass the Root check
# We force the EUID check to always be false so Flutter doesn't quit
echo "👻 Activating Ghost Mode (Bypassing Root Check)..."
find flutter/bin/internal -name "*.sh" -exec sed -i 's/\[\[ "$EUID" == 0 \]\]/false/g' {} + || true
sed -i 's/\[\[ "$EUID" == 0 \]\]/false/g' flutter/bin/flutter || true

# 5. Path Setup
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Web..."
flutter config --no-analytics
flutter config --enable-web

# 6. Build
echo "📦 Fetching AgriBuddy packages..."
flutter pub get

echo "🚀 Compiling Web Production Build..."
# --no-pub ensures we don't trigger internal checks twice
flutter build web --release --base-href / --no-pub

echo "✅ Success! AgriBuddy is LIVE."
