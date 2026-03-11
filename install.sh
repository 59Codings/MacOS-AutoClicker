#!/bin/bash

set -e

APP="AutoClicker"
REPO="59Codings/MacOS-AutoClicker"

DMG_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep browser_download_url | grep .dmg | cut -d '"' -f 4)

curl -L "$DMG_URL" -o "$APP.dmg"

hdiutil attach "$APP.dmg" -nobrowse

cp -R "/Volumes/$APP/$APP.app" /Applications/

hdiutil detach "/Volumes/$APP"

rm "$APP.dmg"

echo "Installed $APP to /Applications"
