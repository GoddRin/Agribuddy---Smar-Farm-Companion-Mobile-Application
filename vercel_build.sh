#!/bin/bash

# 1. Stop on any error
set -e

echo "📦 Downloading Flutter Power-Pack (Stable Linux SDK)..."

# 2. Download a pre-compiled version directly (Faster and more reliable than git clone)
# Using 3.22.2 as a known stable target
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz

echo "🔓 Unwrapping the engine..."
tar xf flutter_linux_3.22.2-stable.tar.xz

# 3. Add to path
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Web..."
flutter config --no-analytics
flutter config --enable-web

# 4. Fetch packages and build
echo "📦 Fetching AgriBuddy packages..."
flutter pub get

echo "🚀 Compiling Web Production Build..."
flutter build web --release --base-href /

echo "✅ Success! AgriBuddy is ready for Vercel."
