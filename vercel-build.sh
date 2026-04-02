#!/bin/bash

# 1. Install Flutter stable
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 2. Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web
echo "Enabling Web support..."
flutter config --enable-web

# 4. Install dependencies
echo "Fetching dependencies..."
flutter pub get

# 5. Build Web
echo "Building Web application..."
flutter build web --release

echo "Build complete! Serving build/web..."
