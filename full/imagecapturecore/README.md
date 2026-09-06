# ImageCaptureCore (Linux starting point)

This directory is a fail-closed portable `ImageCaptureCore` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **649 implemented / 6 declared / 655 total** (above the medium-full
floor of 328).

## What is real

- Device/location/EXIF/media-presentation enums with documented `UInt`/`Int`
  raw values (`ICDeviceType.camera = 1`, location bits `0x100…0x800`,
  EXIF 1…8, `ICMediaPresentation` 1 and 2).
- `ICReturnCodeOffset` bases (`-21000`, `-21050`, … `-21450`) and nested
  error codes derived as `offset` minus `0…n`, plus the ICA legacy range
  `-9900…-9921` and the primary `ICReturn.Code` range `0` then `-9922…-9958`.
- Bridged `NSError` types (`ICReturn`, `ICLegacyReturn`, connection /
  download / metadata / object / PTP / thumbnail) with `ICErrorDomain`
  (`com.apple.ImageCaptureCore`), `userInfo`, equality, hashing, and `~=`.
- Typed NSString keys (`ICAuthorizationStatus`, capabilities, transports,
  download/session options, delete keys) using TBD export names as raw
  values.
- `ICDeviceBrowser` start/stop browsing state, empty catalogs, and
  contents/control authorization that completes with `.denied`.
- `ICDevice` / `ICCameraDevice` session, eject, delete, download, and PTP
  entry points that fail-closed with documented codes. `mediaPresentation`
  and `ptpEventHandler` are stored process-locally.
- `ICCameraFile` offset/length validation (`offset < 0` →
  `codeObjectDataOffsetInvalid`, `length <= 0` → `codeObjectDataEmpty`)
  before the hardware boundary. Cache flush actually clears local storage.

## Fail-closed boundaries

Linux has no Image Capture daemon (`icdd`), PTP/USB camera, scanner,
tethered capture, TCC Photo/Camera authorization, or Apple fingerprint
service.

- `ICDeviceBrowser.devices` never contains hardware. Browsing is a local
  flag.
- Authorization statuses stay `.denied`. Prompts complete synchronously.
- `requestOpenSession` never sets `hasOpenSession`. Delegate/error is
  `deviceFailedToOpenSession`.
- Downloads, deletes, PTP, thumbnails, metadata, and security-scoped URLs
  never succeed. Completions run on the caller thread.
- `ICCameraFile.fingerprintForFile(at:)` always returns `nil`.
- CoreGraphics `CGImage` is a typealias to `NSObject`; icons/thumbnails
  are always `nil`. Objective-C `Selector` is a string overlay and is
  never performed.

Six async overlays are `declared` only: the sealed runner has no run loop,
so those methods are not invoked. Equivalent completion/selector entry
points are exercised synchronously.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or agent tests. After this pass:
**649 implemented / 6 declared / 0 deferred**.

The six `declared` rows are the async overlays of session open/close, PTP
send, metadata dictionary, read-data, and thumbnail-data.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 44 | `ICEnumTests.swift#testICReturnCodeRawValues` |
| 40 | `ICErrorTests.swift#testICReturnStaticCodeAliases` |
| 26 | `ICEnumTests.swift#testICLegacyReturnCodeRawValues` |
| 24 | `ICCameraTests.swift#testICCameraItemHostPropertiesAndCache` |
| 23 | `ICCameraTests.swift#testICCameraFileRemainingProperties` |

`testICReturnCodeRawValues` and `testICLegacyReturnCodeRawValues` are
table-driven enum/member value tests. Static code aliases are the Swift
overlay of those same C error constants. Remaining implemented rows stay
well under the 40% bulk-relabel bound.

The sealed host gate was run as
`bash full/imagecapturecore/tests/acceptance/test_host.sh` and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ImageCaptureCore lane=medium-full symbols=655
FRAMEWORK_FANOUT_REFERENCE_OK
IMAGECAPTURECORE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ImageCaptureCore dylib=libImageCaptureCore.dylib
```

`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). `swiftc --version`
is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. The sealed gate was
not weakened.
