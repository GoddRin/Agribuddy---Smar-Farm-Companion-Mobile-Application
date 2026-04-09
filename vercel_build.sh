#!/bin/bash

# Vercel doesn't have Flutter pre-installed, so we grab it directly from GitHub!
echo "⬇️ Cloning Flutter SDK (Stable Channel)..."
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to the temporary server environment path
export PATH="$PATH:`pwd`/flutter/bin"

# Ensure we're ready
echo "⚙️ Configuring Flutter..."
flutter config --no-analytics

# Get dependencies and build!
echo "📦 Fetching packages..."
flutter pub get

echo "🚀 Building Web Release..."
flutter build web --release

echo "✅ Build Complete!"
