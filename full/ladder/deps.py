#!/usr/bin/env python3
"""Separate an app's imports into IN-TREE modules and EXTERNAL dependencies.

THE DISTINCTION IS MEASURED, NOT GUESSED. A module is IN-TREE if the clone
itself declares or contains it:

  * a `.target(name: "X")` / `.executableTarget` / `.testTarget` / `.systemLibrary`
    / `.binaryTarget` in ANY in-tree `Package.swift`, or
  * a `PRODUCT_NAME` build setting in any `project.pbxproj`, or
  * a directory of that name anywhere in the clone (source folder or
    checked-in vendored copy)

Anything else that is not an Apple framework is EXTERNAL: it must be fetched
AND COMPILED AGAINST OUR STACK before the app can build at all.

WHY THIS IS ITS OWN DEMAND ROW rather than a build-shape note: an app's own
code can be perfectly UIKit-shaped while a dependency is not. A reactive
framework is a heavy Swift-generics and runtime workout; a dependency that is
itself SwiftUI/Combine-bound drags the app to FAR regardless of the app's own
code. So the WORST dependency bounds the app's rung.

A THIRD SIGNAL WAS TRIED AND REMOVED AFTER MEASURING: `productName = X;` in
project.pbxproj. Xcode writes that key for SPM *package product* references, so
it names EXTERNAL dependencies, not in-tree targets -- it silently reclassified
SnapKit, NextcloudKit, RealmSwift, ObjectMapper and HAKit as in-tree, i.e. it
deleted five real dependencies from the very list this file exists to produce.
`PRODUCT_NAME` (a build setting of a real target) is kept.

KNOWN IMPRECISION, and it runs in one direction. Rule (c) -- "a directory of
that name exists" -- will call a module IN-TREE when a repo happens to have a
same-named folder, and every clone here has `Pods/`/`Carthage/` absent, so a
vendored dep is not mistaken for in-tree. So this UNDER-counts external deps;
the external list is a FLOOR. Every name on it was eyeballed once against the
app's manifests.

    ./deps.py <corpus> <imports-full.json> <out.json>
"""
import json, os, re, sys
from collections import defaultdict

TARGET_RE = re.compile(r'\.(?:executableTarget|testTarget|systemLibrary|binaryTarget|target)'
                       r'\s*\(\s*name\s*:\s*"([^"]+)"')
LIBRARY_RE = re.compile(r'\.library\s*\(\s*name\s*:\s*"([^"]+)"')
PBX_PRODNAME = re.compile(r'PRODUCT_NAME\s*=\s*"?([A-Za-z_][A-Za-z0-9_$()]*)"?\s*;')

APPLE = set("""Foundation UIKit SwiftUI Combine CoreData CoreGraphics QuartzCore AVFoundation
AVKit CoreLocation MapKit WebKit Photos PhotosUI Contacts ContactsUI MessageUI StoreKit
SafariServices UserNotifications LocalAuthentication Security CryptoKit CommonCrypto os OSLog
Dispatch Darwin XCTest Testing SwiftData Charts WidgetKit AppIntents ActivityKit BackgroundTasks
CallKit PushKit Intents IntentsUI CoreMedia CoreImage CoreText CoreTelephony CoreMotion
CoreBluetooth CoreServices MobileCoreServices Network NetworkExtension SystemConfiguration
AudioToolbox MediaPlayer VideoToolbox Accelerate Metal MetalKit SceneKit SpriteKit ARKit Vision
NaturalLanguage CoreML GameController GameplayKit HealthKit HomeKit PassKit EventKit EventKitUI
Social Speech QuickLook QuickLookThumbnailing FileProvider FileProviderUI UniformTypeIdentifiers
LinkPresentation AuthenticationServices DeviceCheck AdSupport AppTrackingTransparency TipKit
Translation VisionKit ImageIO ObjectiveC MachO Accessibility CarPlay ClockKit WatchKit
WatchConnectivity MultipeerConnectivity GameKit GLKit OpenGLES ExternalAccessory
NearbyInteraction Observation Synchronization _Concurrency RegexBuilder Algorithms Collections
OrderedCollections AsyncAlgorithms System CoreSpotlight CoreNFC MetricKit CoreHaptics
GroupActivities ShazamKit SoundAnalysis CoreAudio CoreAudioTypes AudioUnit CoreVideo
CoreFoundation IOKit CloudKit AlarmKit AppKit PDFKit SwiftUICore DeveloperToolsSupport
PackageDescription CompilerPluginSupport SwiftSyntax MediaAccessibility ScreenTime
ManagedSettings FamilyControls DataDetection BrowserEngineKit ExtensionKit ExtensionFoundation
StoreKitTest XCUIAutomation Darwin_C SwiftShims
Cocoa Compression MetalPerformanceShaders MetalPerformanceShadersGraph JavaScriptCore simd
CFNetwork AVFAudio UserNotificationsUI NotificationCenter ReplayKit CoreTransferable
CoreMediaIO FoundationModels SQLite3 zlib notify Darwin_POSIX CryptoTokenKit VideoSubscriberAccount
AVRouting Symbols Translation_ CoreSpotlightContinuation AutomaticAssessmentConfiguration
DeviceActivity CoreMIDI OpenAL AudioUnitSDK CoreWLAN ServiceManagement AppleArchive
FinanceKit ProximityReader NearbyShare SensitiveContentAnalysis DockKit Cinematic
MediaExtension ThreadNetwork MatterSupport WorkoutKit Journaling BrowserEngineCore
CoreHID libkern MachPorts SwiftUIGlue Combine_ RealityKit RealityFoundation
FoundationEssentials FoundationInternationalization CoreAudioKit Speech_
InputMethodKit LatentSemanticMapping ScriptingBridge OSAKit""".split())


def in_tree_modules(root):
    names = set()
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d != ".git"]
        for d in dn:
            names.add(d)
            if d.endswith(".xcodeproj"):
                pbx = os.path.join(dp, d, "project.pbxproj")
                if os.path.exists(pbx):
                    src = open(pbx, encoding="utf-8", errors="ignore").read()
                    names |= set(PBX_PRODNAME.findall(src))
        for f in fn:
            if f == "Package.swift":
                src = open(os.path.join(dp, f), encoding="utf-8", errors="ignore").read()
                names |= set(TARGET_RE.findall(src))
                names |= set(LIBRARY_RE.findall(src))
    # Xcode target names are commonly spelled with spaces/dashes; imports are not.
    return names | {n.replace("-", "_") for n in names} | {n.replace(" ", "") for n in names}


def main():
    corpus, impf, outf = sys.argv[1:4]
    imports = json.load(open(impf))
    out, ext_apps, ext_files = {}, defaultdict(set), defaultdict(int)
    for app, imps in imports.items():
        tree = in_tree_modules(os.path.join(corpus, app))
        ext = {m: c for m, c in imps.items()
               if m not in APPLE and m not in tree and not m.startswith("_")}
        intree = {m: c for m, c in imps.items() if m in tree and m not in APPLE}
        out[app] = {"in_tree": dict(sorted(intree.items(), key=lambda kv: -kv[1])),
                    "external": dict(sorted(ext.items(), key=lambda kv: -kv[1]))}
        for m, c in ext.items():
            ext_apps[m].add(app)
            ext_files[m] += c
    out["_union_external"] = [
        {"module": m, "apps": len(ext_apps[m]), "importing_files": ext_files[m],
         "in": sorted(ext_apps[m])}
        for m in sorted(ext_apps, key=lambda m: (-len(ext_apps[m]), -ext_files[m]))]
    json.dump(out, open(outf, "w"), indent=1)

    print(f"{'app':<20}{'in-tree':>9}{'external':>10}   top external (files importing)")
    for app in sorted(k for k in out if not k.startswith("_")):
        e = out[app]["external"]
        print(f"{app:<20}{len(out[app]['in_tree']):>9}{len(e):>10}   "
              + ", ".join(f"{m}({c})" for m, c in list(e.items())[:8]))
    print(f"\nEXTERNAL DEPENDENCIES BY APP-REACH ({len(imports)} apps):")
    print(f"  {'module':<26}{'apps':>5}{'files':>7}")
    for r in out["_union_external"][:40]:
        print(f"  {r['module']:<26}{r['apps']:>5}{r['importing_files']:>7}")


main()
