#!/bin/bash

# 1. Exit immediately if a command exits with a non-zero status
set -e

echo "快速开始: Installing Flutter SDK (Shallow Clone for speed)..."

# 2. Only clone the latest stable commit to save memory/time
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 3. Add Flutter to the path
export PATH="$PATH:`pwd`/flutter/bin"

echo "⚙️ Configuring Flutter Web..."
flutter config --no-analytics
flutter config --enable-web

# 4. Pre-download the Web SDK to avoid timeouts during build
echo "🚚 Pre-loading Web SDK..."
flutter precache --web

# 5. Build
echo "📦 Fetching packages..."
flutter pub get

echo "🚀 Building Web Release..."
flutter build web --release --base-href /

echo "✅ Build Complete! Files are ready in build/web"
