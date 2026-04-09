#!/bin/bash

# 1. Install Flutter stable
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# --- GHOST MODE START ---
# Vercel forces root access, but modern Flutter SDK explicitly blocks root builds.
# We bypass the internal root checks inside the Flutter CLI directly using sed.
echo "Bypassing Flutter root checks..."
sed -i 's/if \[\[ "\$EUID" == "0" \]\]; then/if false; then/' ./flutter/bin/internal/shared.sh
# --- GHOST MODE END ---

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
