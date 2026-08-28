#!/bin/zsh
# Clone the corpus's heavy EXTERNAL dependencies, so they can be run through the
# SAME instruments as the apps. A dependency is not a build-shape note: it must
# itself compile against our stack, and a dep that is SwiftUI/Combine-bound or
# ObjC drags its app to FAR regardless of the app's own code.
#
# Selection rule, stated so the set is not ad hoc: every external module that is
# either (a) imported by >=2 of the 20 apps, or (b) imported by >=25 files in
# any single app. Closed-source/binary deps (Stripe, CardFlight, WebRTC,
# Firebase, GoogleSignIn) are DELIBERATELY ABSENT -- there is no source to
# measure, which is itself the finding.
#
#   ./clone_deps.sh <deps-dir>
set -u
D="${1:?usage: clone_deps.sh <deps-dir>}"
mkdir -p "$D"

REPOS=(
  "ReactiveSwift    https://github.com/ReactiveCocoa/ReactiveSwift"
  "RxSwift          https://github.com/ReactiveX/RxSwift"
  "Moya             https://github.com/Moya/Moya"
  "Apollo           https://github.com/apollographql/apollo-ios"
  "PromiseKit       https://github.com/mxcl/PromiseKit"
  "GRDB             https://github.com/groue/GRDB.swift"
  "SwiftProtobuf    https://github.com/apple/swift-protobuf"
  "Kingfisher       https://github.com/onevcat/Kingfisher"
  "SDWebImage       https://github.com/SDWebImage/SDWebImage"
  "Lottie           https://github.com/airbnb/lottie-ios"
  "Alamofire        https://github.com/Alamofire/Alamofire"
  "AlamofireImage   https://github.com/Alamofire/AlamofireImage"
  "SwiftSoup        https://github.com/scinfu/SwiftSoup"
  "Sentry           https://github.com/getsentry/sentry-cocoa"
  "SwiftyJSON       https://github.com/SwiftyJSON/SwiftyJSON"
  "Nuke             https://github.com/kean/Nuke"
  "DifferenceKit    https://github.com/ra1028/DifferenceKit"
  "SnapKit          https://github.com/SnapKit/SnapKit"
  "Starscream       https://github.com/daltoniam/Starscream"
  "KeychainAccess   https://github.com/kishikawakatsumi/KeychainAccess"
  "CocoaLumberjack  https://github.com/CocoaLumberjack/CocoaLumberjack"
  "RealmSwift       https://github.com/realm/realm-swift"
  "Quick            https://github.com/Quick/Quick"
  "Nimble           https://github.com/Quick/Nimble"
  "SwipeCellKit     https://github.com/SwipeCellKit/SwipeCellKit"
  "Interstellar     https://github.com/JensRavens/Interstellar"
  "HAKit            https://github.com/home-assistant/HAKit"
  "NextcloudKit     https://github.com/nextcloud/NextcloudKit"
  "SVProgressHUD    https://github.com/SVProgressHUD/SVProgressHUD"
  "ObjectMapper     https://github.com/tristanhimmelman/ObjectMapper"
)

: > "$D/PINS.txt"
for entry in "${REPOS[@]}"; do
  name="${entry%% *}"; url="${entry##* }"
  dir="$D/$name"
  [ -d "$dir/.git" ] || { echo "=== $name"; rm -rf "$dir"; \
      git clone --depth 1 --single-branch --quiet "$url" "$dir" 2>&1 | tail -2; }
  if [ -d "$dir/.git" ]; then
    printf '%s\t%s\t%s\t%s\n' "$name" "$url" \
      "$(git -C "$dir" rev-parse HEAD)" "$(git -C "$dir" log -1 --format=%cI)" >> "$D/PINS.txt"
  else
    printf '%s\t%s\tFAILED\tFAILED\n' "$name" "$url" >> "$D/PINS.txt"
  fi
done
cat "$D/PINS.txt"
