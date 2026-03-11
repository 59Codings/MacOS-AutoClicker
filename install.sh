#!/bin/bash

set -e

APP="AutoClicker"
REPO="59Codings/MacOS-AutoClicker"

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

RELEASE_JSON=$(curl -s https://api.github.com/repos/$REPO/releases/latest)

if [ "$ARCH" = "arm64" ]; then
    DMG_URL=$(echo "$RELEASE_JSON" | grep browser_download_url | grep -i "arm64\|apple.silicon\|universal" | head -1 | cut -d '"' -f 4)
fi

if [ -z "$DMG_URL" ]; then
    DMG_URL=$(echo "$RELEASE_JSON" | grep browser_download_url | grep -i "x86_64\|intel\|universal" | head -1 | cut -d '"' -f 4)
fi

if [ -z "$DMG_URL" ]; then
    DMG_URL=$(echo "$RELEASE_JSON" | grep browser_download_url | grep .dmg | head -1 | cut -d '"' -f 4)
fi

if [ -z "$DMG_URL" ]; then
    echo "Error: Could not find a DMG download URL in the latest release."
    exit 1
fi

echo "Downloading: $DMG_URL"
curl -L "$DMG_URL" -o "$APP.dmg"

hdiutil attach "$APP.dmg" -nobrowse

cp -R "/Volumes/$APP/$APP.app" /Applications/

hdiutil detach "/Volumes/$APP"

rm "$APP.dmg"

echo "Installed $APP to /Applications"
