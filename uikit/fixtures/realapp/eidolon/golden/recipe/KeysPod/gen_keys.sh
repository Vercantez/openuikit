#!/bin/bash
# Writes the Keys pod that cocoapods-keys 2.0.6 would generate after
# `fastlane oss_keys` (every key set to "-"), at the lock's path
# Pods/CocoaPodsKeys. Plain string literals replace the plugin's obfuscated
# char tables; the class name, property names, and values are the same.
set -euo pipefail
out="$1"
mkdir -p "$out"
keys=(ArtsyAPIClientSecret ArtsyAPIClientKey HockeyProductionSecret HockeyBetaSecret SegmentWriteKey
      CardflightProductionAPIClientKey CardflightProductionMerchantAccountToken StripeProductionPublishableKey
      CardflightStagingAPIClientKey CardflightStagingMerchantAccountToken StripeStagingPublishableKey)
lc() { echo "$(echo "${1:0:1}" | tr '[:upper:]' '[:lower:]')${1:1}"; }
{
  echo '#import <Foundation/Foundation.h>'
  echo
  echo '@interface EidolonKeys : NSObject'
  for k in "${keys[@]}"; do echo "@property (nonatomic, readonly) NSString *$(lc "$k");"; done
  echo '@end'
} > "$out/EidolonKeys.h"
{
  echo '#import "EidolonKeys.h"'
  echo
  echo '@implementation EidolonKeys'
  for k in "${keys[@]}"; do echo "- (NSString *)$(lc "$k") { return @\"-\"; }"; done
  echo '@end'
} > "$out/EidolonKeys.m"
cat > "$out/Keys.podspec.json" <<'EOF'
{
  "name": "Keys",
  "version": "1.0.1",
  "summary": "Keys are secrets (cocoapods-keys layout; oss_keys values \"-\").",
  "homepage": "https://github.com/orta/cocoapods-keys",
  "license": { "type": "MIT" },
  "authors": { "Orta Therox": "orta.therox@gmail.com" },
  "source": { "git": "https://github.com/orta/cocoapods-keys.git" },
  "platforms": { "ios": "10.0" },
  "source_files": "*.{h,m}",
  "requires_arc": true
}
EOF
