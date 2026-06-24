#!/bin/bash
set -e

NEW_VERSION="$1"
if [ -z "$NEW_VERSION" ]; then
  echo "Usage: $0 <new-version>"
  exit 1
fi

BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")

sed -i "s/^version: .*/version: $NEW_VERSION+$BUILD_NUMBER/" pubspec.yaml
sed -i 's/version = ".*"/version = "'"$NEW_VERSION"'"/' remote_turner.koplugin/_meta.lua

echo "Updated pubspec.yaml to version $NEW_VERSION+$BUILD_NUMBER"
echo "Updated remote_turner.koplugin/_meta.lua to version $NEW_VERSION"
