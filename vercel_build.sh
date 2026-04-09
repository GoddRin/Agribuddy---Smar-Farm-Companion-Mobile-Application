#!/bin/bash

# 1. Stop on any error
set -e

# 2. SECURITY FIX: Tell Git to trust the directories we create on Vercel
# This solves the "dubious ownership" error
git config --global --add safe.directory '*'

echo "📦 Downloading Flutter Power-Pack (Stable Linux SDK)..."

# 3. Download and unwrap (Faster and more reliable than git clone)
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz

echo "🔓 Unwrapping the engine..."
tar xf flutter_linux_3.22.2-stable.tar.xz

# 4. Add to path
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Web..."
flutter config --no-analytics
flutter config --enable-web

# 5. Fetch packages and build
echo "📦 Fetching AgriBuddy packages..."
flutter pub get

echo "🚀 Compiling Web Production Build..."
flutter build web --release --base-href /

echo "✅ Success! AgriBuddy is ready for Vercel."
