// t2_bridge.swift — the decisive Swift <-> ObjC bridging test.
//
// This exact source must compile and run BOTH against real macOS Foundation
// (the oracle, run natively on macOS) and against our slice under machorun.
// Every line prints `key=value` so the two runs diff byte-for-byte.
//
// Nothing here is slice-specific: it is ordinary Foundation API.

import Foundation

// 1. String -> NSString. Routes through String._bridgeToObjectiveC(), which
//    calls the stdlib's _bridgeToObjectiveCImpl(), which hands back a
//    __StringStorage whose class connectNSBaseClasses re-parented onto NSString.
//    `length` is then an objc_msgSend into the Swift stdlib's own @objc method.
let s = "hi" as NSString
print("nsstring.length=\(s.length)")
print("nsstring.char0=\(s.character(at: 0))")

let longer = "hello, world" as NSString
print("longer.length=\(longer.length)")

// 2. NSString -> String, the other direction through the conformance.
let back = longer as String
print("roundtrip=\(back)")
print("roundtrip.eq=\(back == "hello, world")")

// 3. Non-ASCII, to prove the UTF-16 path is not accidentally byte-oriented.
let uni = "caf\u{e9}" as NSString
print("unicode.length=\(uni.length)")
print("unicode.roundtrip=\((uni as String) == "caf\u{e9}")")

// 4. NSArray, with Int elements bridged through _bridgeAnythingToObjectiveC.
let a = NSArray(array: [1, 2, 3])
print("nsarray.count=\(a.count)")
print("nsarray.first.isNumber=\(a.object(at: 0) is NSNumber)")
print("nsarray.0=\((a.object(at: 0) as! NSNumber).intValue)")
print("nsarray.2=\((a.object(at: 2) as! NSNumber).intValue)")

// 5. An NSArray of bridged Strings — String -> NSString inside a collection.
let sa = NSArray(array: ["alpha", "beta"])
print("strarray.count=\(sa.count)")
print("strarray.0.length=\((sa.object(at: 0) as! NSString).length)")

// 6. Identity/equality across the bridge.
let x = "abc" as NSString
let y = "abc" as NSString
print("equal=\(x.isEqual(to: y as String))")
