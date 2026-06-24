#!/bin/bash
set -e

VERSION="$1"
ARCH="$2"
if [ -z "$VERSION" ] || [ -z "$ARCH" ]; then
  echo "Usage: $0 <version> <arch>"
  exit 1
fi

DIST_DIR="dist"
BUILD_DIR="build/linux/${ARCH}/release/bundle"
DEB_DIR="build/deb/koreader-remote-turner_${VERSION}_${ARCH}"
ICON_SRC="macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"

mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/share/koreader-remote-turner"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$DEB_DIR/usr/share/doc/koreader-remote-turner"

# Copy control file with version + arch
sed "s/Version: 0.0.0/Version: $VERSION/; s/Architecture: amd64/Architecture: $ARCH/" \
  installers/linux/DEBIAN/control > "$DEB_DIR/DEBIAN/control"

# Copy desktop entry
cp installers/linux/usr/share/applications/koreader-remote-turner.desktop "$DEB_DIR/usr/share/applications/"

# Copy wrapper script
cp installers/linux/usr/bin/koreader-remote-turner "$DEB_DIR/usr/bin/"
chmod 755 "$DEB_DIR/usr/bin/koreader-remote-turner"

# Copy Flutter bundle
cp -r "$BUILD_DIR"/* "$DEB_DIR/usr/share/koreader-remote-turner/"
chmod 755 "$DEB_DIR/usr/share/koreader-remote-turner/koreader_remote_turner"

# Copy icon
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/koreader-remote-turner.png"
fi

# Generate changelog
echo "koreader-remote-turner ($VERSION) unstable; urgency=medium

  * New release.

 -- Shin Curry <shin@curry.jp>  $(date -R)" | gzip -9 > "$DEB_DIR/usr/share/doc/koreader-remote-turner/changelog.gz"

# Build .deb
mkdir -p "$DIST_DIR"
dpkg-deb --build "$DEB_DIR" "$DIST_DIR/koreader-remote-${VERSION}-linux-${ARCH}.deb"

echo "Built $DIST_DIR/koreader-remote-${VERSION}-linux-${ARCH}.deb"
