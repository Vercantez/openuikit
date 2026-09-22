import os

// OSSignposter surface used by NetNewsWire ArticlesTable.swift:28/767/771/777.
let s = OSSignposter(subsystem: "com.example.probe", category: .pointsOfInterest)
print("isEnabled(pointsOfInterest)=\(s.isEnabled)")
print("isEnabled(plain category)=\(OSSignposter(subsystem: "com.example.probe", category: "x").isEnabled)")
print("isEnabled(init())=\(OSSignposter().isEnabled)")
print("isEnabled(disabled log)=\(OSSignposter(logHandle: .disabled).isEnabled)")
let a = s.makeSignpostID()
let b = s.makeSignpostID()
print("makeSignpostID distinct=\(a != b) valid=\(a != .invalid && a != .null && a != .exclusive)")
let st = s.beginInterval("Fetch articles")
s.endInterval("Fetch articles", st, "\(3) articles")
let st2 = s.beginInterval("Fetch articles")
s.endInterval("Fetch articles", st2, "no result set")
s.emitEvent("event")
let r = s.withIntervalSignpost("around") { 42 }
print("withIntervalSignpost returns=\(r)")
print("exclusive raw=0x\(String(OSSignpostID.exclusive.rawValue, radix: 16)) invalid=\(OSSignpostID.invalid.rawValue) null=0x\(String(OSSignpostID.null.rawValue, radix: 16))")
