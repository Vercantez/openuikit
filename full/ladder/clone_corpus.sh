#!/bin/zsh
# Shallow-clone the app-ladder corpus and pin every clone's SHA.
#
#   ./clone_corpus.sh <corpus-dir>
#
# Writes <corpus-dir>/PINS.txt   (app <tab> url <tab> sha <tab> committer-date)
# A clone that fails is recorded as FAILED rather than silently omitted, so the
# denominator of every downstream count is the list in this file, not "whatever
# happened to be on disk".
set -u
CORPUS="${1:?usage: clone_corpus.sh <corpus-dir>}"
mkdir -p "$CORPUS"

# name                    url
REPOS=(
  "eidolon                https://github.com/artsy/eidolon"
  "duckduckgo-ios         https://github.com/duckduckgo/iOS"
  "ios-oss                https://github.com/kickstarter/ios-oss"
  "pocket-casts-ios       https://github.com/Automattic/pocket-casts-ios"
  "wikipedia-ios          https://github.com/wikimedia/wikipedia-ios"
  "WordPress-iOS          https://github.com/wordpress-mobile/WordPress-iOS"
  "Signal-iOS             https://github.com/signalapp/Signal-iOS"
  "firefox-ios            https://github.com/mozilla-mobile/firefox-ios"
  "focus-ios              https://github.com/mozilla-mobile/focus-ios"
  "mastodon-ios           https://github.com/mastodon/mastodon-ios"
  "home-assistant-ios     https://github.com/home-assistant/iOS"
  "NetNewsWire            https://github.com/Ranchero-Software/NetNewsWire"
  "Telegram-iOS           https://github.com/TelegramMessenger/Telegram-iOS"
  "vlc-ios                https://github.com/videolan/vlc-ios"
  "nextcloud-ios          https://github.com/nextcloud/ios"
  "simplenote-ios         https://github.com/Automattic/simplenote-ios"
  "Hackers                https://github.com/weiran/Hackers"
  "eigen                  https://github.com/artsy/eigen"
  "element-ios            https://github.com/element-hq/element-ios"
  "ProtonMail-ios         https://github.com/ProtonMail/ios-mail"
)

: > "$CORPUS/PINS.txt"
for entry in "${REPOS[@]}"; do
  name="${entry%% *}"
  url="${entry##* }"
  dir="$CORPUS/$name"
  if [ ! -d "$dir/.git" ]; then
    echo "=== cloning $name from $url"
    rm -rf "$dir"
    if ! git clone --depth 1 --single-branch --quiet "$url" "$dir" 2>&1 | tail -3; then
      :
    fi
  fi
  if [ -d "$dir/.git" ]; then
    sha="$(git -C "$dir" rev-parse HEAD)"
    date="$(git -C "$dir" log -1 --format=%cI)"
    printf '%s\t%s\t%s\t%s\n' "$name" "$url" "$sha" "$date" >> "$CORPUS/PINS.txt"
  else
    printf '%s\t%s\tFAILED\tFAILED\n' "$name" "$url" >> "$CORPUS/PINS.txt"
  fi
done
echo "=== pins ==="
cat "$CORPUS/PINS.txt"
