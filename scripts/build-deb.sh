#!/usr/bin/env bash
set -euo pipefail

# Build a Debian package for the Linux release bundle produced by Flutter.
# Usage: ./scripts/build-deb.sh [output-dir]

OUT_DIR=${1:-build/deb}
APP_NAME=velotask
PKG_DIR="$OUT_DIR/${APP_NAME}_pkg"

VERSION_LINE=$(grep '^version:' pubspec.yaml || true)
if [ -z "$VERSION_LINE" ]; then
  echo "Unable to determine version from pubspec.yaml"
  exit 1
fi
RAW_VERSION=$(echo "$VERSION_LINE" | awk '{print $2}')
DEB_VERSION=$(echo "$RAW_VERSION" | cut -d'+' -f1)

echo "Building Flutter linux release..."
BUNDLE_DIR="build/linux/x64/release/bundle"

# If bundle already exists, skip rebuild to allow packaging job to reuse bundle
if [ -d "$BUNDLE_DIR" ] && [ -x "$BUNDLE_DIR/$APP_NAME" ]; then
  echo "Found existing bundle at $BUNDLE_DIR, skipping flutter build."
else
  echo "No existing bundle found; building Flutter linux release..."
  flutter pub get
  if command -v dart >/dev/null 2>&1; then
    dart run build_runner build --delete-conflicting-outputs || true
  fi
  flutter build linux --release
fi

BUNDLE_DIR="build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Expected linux bundle at $BUNDLE_DIR"
  ls -la build/linux || true
  exit 1
fi

rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/lib/$APP_NAME"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/512x512/apps"

echo "Copying bundle files..."
  cp -r "$BUNDLE_DIR"/* "$PKG_DIR/usr/lib/$APP_NAME/"

EXEC_PATH="/usr/lib/$APP_NAME/$APP_NAME"
cat > "$PKG_DIR/usr/bin/$APP_NAME" <<EOF
#!/usr/bin/env bash
exec "$EXEC_PATH" "$@"
EOF
chmod +x "$PKG_DIR/usr/bin/$APP_NAME"

# Desktop file
cat > "$PKG_DIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=VeloTask
Exec=$APP_NAME
Icon=$APP_NAME
Categories=Utility;
Terminal=false
EOF

# Icon: try linux runner icon first, fallback to web icon
if [ -f linux/runner/resources/app_icon.png ]; then
  cp linux/runner/resources/app_icon.png "$PKG_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
elif [ -f web/icons/Icon-512.png ]; then
  cp web/icons/Icon-512.png "$PKG_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
fi

# Control file
INSTALLED_SIZE=1024
cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $DEB_VERSION
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0 (>= 3.0)
Maintainer: VeloTask <no-reply@example.com>
Installed-Size: $INSTALLED_SIZE
Description: VeloTask - lightweight task manager
 A simple productivity app built with Flutter.
EOF

chmod 755 "$PKG_DIR/DEBIAN"

OUT_DEB="$OUT_DIR/${APP_NAME}_${DEB_VERSION}_amd64.deb"
mkdir -p "$OUT_DIR"

echo "Building .deb package: $OUT_DEB"
if command -v fakeroot >/dev/null 2>&1; then
  fakeroot dpkg-deb --build "$PKG_DIR" "$OUT_DEB"
else
  dpkg-deb --build "$PKG_DIR" "$OUT_DEB"
fi

echo "Deb package created: $OUT_DEB"
