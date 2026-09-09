#!/bin/zsh
# Reproduces the objc-impl-chain1 wall. Two builds:
#   1. -DPROBE_SAME_MODULE: the grandchild lives in the implementing module
#      (OpenUIKit's own UIButton : UIControl : UIView) -> ProbeButton fails;
#   2. default: the implementing module builds; the grandchild in ProbeClient
#      (an app's cell class) fails the same way.
# Exit 0 when both reproduce (exactly one required-initializer error each).
set -u
cd "$(dirname "$0")" || exit 1
ok=1
for mode in same cross; do
  if [[ $mode == same ]]; then flags=(-Xswiftc -DPROBE_SAME_MODULE); else flags=(); fi
  out=$(timeout 300 swift build "${flags[@]}" 2>&1)
  print -- "== $mode-module grandchild"
  print -- "$out" | grep -E "^/.*(error|note)" | sed "s|$PWD/||" | sort -u
  n=$(print -- "$out" | grep -E "^/.*error" | sort -u | grep -c "'required' initializer 'init(coder:)' must be provided by subclass of 'ProbeView'")
  print -- "required-initializer errors: $n (expect 1)"
  [[ $n -eq 1 ]] || ok=0
done
swift --version 2>&1 | head -1
[[ $ok -eq 1 ]]
