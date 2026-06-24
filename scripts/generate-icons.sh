#!/bin/bash
set -e
ICON_SVG="icon.svg"
TMP="build/icons"

rm -rf "$TMP"
mkdir -p "$TMP"

echo "=== Generating base PNGs from SVG ==="
for size in 16 20 29 32 40 48 58 60 64 72 76 80 87 96 100 120 128 144 152 167 172 180 192 196 216 234 256 324 400 500 512 1024; do
  rsvg-convert -w "$size" -h "$size" "$ICON_SVG" > "$TMP/${size}.png"
done
echo "    done"

echo "=== macOS AppIcon ==="
cp "$TMP/16.png"  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
cp "$TMP/32.png"  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
cp "$TMP/64.png"  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
cp "$TMP/128.png" macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
cp "$TMP/256.png" macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
cp "$TMP/512.png" macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
cp "$TMP/1024.png" macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
echo "    done"

echo "=== iOS AppIcon ==="
cp "$TMP/40.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
cp "$TMP/60.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
cp "$TMP/29.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
cp "$TMP/58.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
cp "$TMP/87.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
cp "$TMP/80.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
cp "$TMP/120.png"  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
cp "$TMP/120.png"  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
cp "$TMP/180.png"  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
cp "$TMP/20.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
cp "$TMP/40.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png  # iPad
cp "$TMP/58.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png  # already
cp "$TMP/40.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png  # already
cp "$TMP/76.png"   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
cp "$TMP/152.png"  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
cp "$TMP/167.png"  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
cp "$TMP/1024.png" ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
echo "    done"

echo "=== Android mipmap ==="
cp "$TMP/48.png"  android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp "$TMP/72.png"  android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp "$TMP/96.png"  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp "$TMP/144.png" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp "$TMP/192.png" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
echo "    done"

echo "=== Windows .ico ==="
convert "$TMP/256.png" -define icon:auto-resize=256,64,48,32,16 \
  windows/runner/resources/app_icon.ico
echo "    done"

# echo "=== Web icons ==="
# cp "$TMP/192.png" web/icons/Icon-192.png
# cp "$TMP/512.png" web/icons/Icon-512.png
# cp "$TMP/512.png" web/favicon.png
# echo "    done"

echo "=== All icons generated successfully ==="
