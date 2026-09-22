#!/usr/bin/env python3
"""Which modules does Apple's `import UIKit` re-export on iOS 26.1?

For each candidate module, typecheck a one-line file that imports ONLY UIKit
and names one symbol that exists only in that module, against Xcode's stock
iPhoneSimulator SDK (Apple's UIKit). A clean typecheck means `import UIKit`
brought the module in. Writes reexports-ios26.1.json next to this file.

    python3 probe.py            # needs Xcode
"""
import json, os, subprocess, tempfile

CANDIDATES = {
    "Foundation": "let _ = URL(string: \"a\")",
    "CoreFoundation": "let _ = CFStringGetLength(\"a\" as CFString)",
    "CoreGraphics": "let _: CGContext? = nil; let _ = CGBitmapInfo.byteOrder32Little",
    "QuartzCore": "let _: CADisplayLink? = nil; let _ = CATransform3DIdentity",
    "ImageIO": "let _ = CGImageSourceCreateWithData as Any; let _ = kCGImagePropertyOrientation",
    "CoreImage": "let _: CIImage? = nil",
    "CoreText": "let _ = CTFontGetSize as Any",
    "Dispatch": "let _ = DispatchQueue.main",
    "Darwin": "let _ = strlen(\"a\")",
    "ObjectiveC": "let _ = class_getName(NSObject.self)",
    "UniformTypeIdentifiers": "let _: UTType? = nil",
    "Symbols": "let _: NSSymbolEffect? = nil",
    "Combine": "let _: AnyCancellable? = nil",
    "Observation": "let _: ObservationRegistrar? = nil",
    "os": "let _ = OSLog.default",
    "CoreData": "let _: NSManagedObject? = nil",
    "UserNotifications": "let _: UNNotification? = nil",
    "Metal": "let _: MTLDevice? = nil",
    "CoreMedia": "let _: CMTime? = nil",
    "AVFoundation": "let _: AVPlayer? = nil",
    "FileProvider": "let _: NSFileProviderManager? = nil",
    "Accessibility": "let _: AXCustomContent? = nil",
    "CoreVideo": "let _: CVPixelBuffer? = nil",
    "IOSurface": "let _: IOSurfaceRef? = nil",
    "Security": "let _ = SecRandomCopyBytes as Any",
    "CFNetwork": "let _ = kCFStreamPropertySSLSettings",
    "DataDetection": "let _: DataDetection.DataDetector? = nil",
    "CoreLocation": "let _: CLLocation? = nil",
    "UIKitCore": "let _: UIView? = nil",
}


def main() -> None:
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip()
    result = {}
    with tempfile.TemporaryDirectory() as tmp:
        for module, line in sorted(CANDIDATES.items()):
            src = os.path.join(tmp, "p.swift")
            open(src, "w").write(f"import UIKit\n{line}\n")
            p = subprocess.run(["xcrun", "swiftc", "-typecheck", "-target", "arm64-apple-ios26.1-simulator",
                                "-sdk", sdk, src], capture_output=True, text=True)
            ok = p.returncode == 0
            result[module] = {"reexported": ok, "probe": line,
                              "first_error": None if ok else next((l for l in p.stderr.splitlines() if "error:" in l), p.stderr[:200])}
            print(f"{module:24s} {'YES' if ok else 'no '}  {'' if ok else result[module]['first_error'].split('error:')[-1].strip()}")
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reexports-ios26.1.json")
    json.dump({"sdk": sdk, "triple": "arm64-apple-ios26.1-simulator", "modules": result}, open(out, "w"), indent=1, sort_keys=True)


if __name__ == "__main__":
    main()
