Focus guest package resources, copied byte-for-byte from mozilla-mobile/focus-ios
commit a2832521c1daa0c23419c73705ae043ed60c9791:

- BlockzillaPackage/Sources/DesignSystem/Colors.xcassets (40 files, 18621 bytes)
- BlockzillaPackage/Sources/DesignSystem/Assets.xcassets (77 files, 150818 bytes)

The original MPL-2.0 application source and asset metadata are unchanged.
`full/scripts/build_full.sh` runs the existing `full/xcassets/xcassets_tool.py`
to index these source catalogs into FocusDesignSystem.bundle. The guest reads
and rasterizes the actual PDF/PNG payloads through its existing image decoder.
The separate historical fixture DesignSystem still owns the prior 14 screens.
