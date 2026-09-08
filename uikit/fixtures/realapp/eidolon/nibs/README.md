# Eidolon compiled Interface Builder resources

These are Xcode 26.1 (17B55) `ibtool` outputs from `artsy/eidolon` commit
`44486ed9149f16b3eb3a5e687f99ae078309f4fe`, under the app's MIT license.
`manifest.json` records source SHA-256 and every compiled artifact's hash
and byte count. These are resources, not simulator golden captures.

From `uikit/`, with `EIDOLON` pointing to that commit-pinned checkout:

```sh
scripts/compile_realapp_nibs.sh --out fixtures/realapp/eidolon/nibs \
  "$EIDOLON/Kiosk/Storyboards/KeypadView.xib" \
  "$EIDOLON/Kiosk/Storyboards/Auction.storyboard" \
  "$EIDOLON/Kiosk/Storyboards/Fulfillment.storyboard"
```

Measured output: 59 `NIBArchive` files and 2 compiled storyboard plists,
223,716 bytes. Compiling the resources does not prove OpenUIKit custom
class registration, outlet/segue wiring, or launch. See
`docs/agent_reports/eidolon-launch-oracle.md` for the native-build walls.
