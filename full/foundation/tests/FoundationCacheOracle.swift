import Foundation

private func emit(_ key: String, _ value: Any) {
    if let text = value as? String, text.isEmpty {
        print("\(key)\t<empty>")
        return
    }
    print("\(key)\t\(value)")
}

final class Value: NSObject {
    let marker: Int

    init(_ marker: Int) {
        self.marker = marker
    }
}

final class Delegate: NSObject, NSCacheDelegate {
    var evicted: [Int] = []
    var expectedIdentity: ObjectIdentifier?
    var sameIdentity = true

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if let expectedIdentity {
            sameIdentity = sameIdentity && ObjectIdentifier(cache) == expectedIdentity
        }
        evicted.append((obj as! Value).marker)
    }
}

let absolute = URL(string: "https://example.com/a%20b?q=1#fragment")!
let bridged = absolute as NSURL
let roundTrip = bridged as URL
emit("url.absolute", bridged.absoluteString ?? "nil")
emit("url.relative", bridged.relativeString)
emit("url.round-trip", roundTrip == absolute)
emit("url.equal-separate", bridged.isEqual(absolute as NSURL))
emit("url.hash-separate", bridged.hash == (absolute as NSURL).hash)
emit("url.scheme", bridged.scheme ?? "nil")
emit("url.host", bridged.host ?? "nil")
emit("url.path", bridged.path ?? "nil")
emit("url.query", bridged.query ?? "nil")
emit("url.fragment", bridged.fragment ?? "nil")

let base = URL(string: "https://example.com/base/")!
let relative = URL(string: "child", relativeTo: base)!
let bridgedRelative = relative as NSURL
emit("url.relative-base", bridgedRelative.relativeString)
emit("url.base", bridgedRelative.baseURL?.absoluteString ?? "nil")
emit("url.resolved", bridgedRelative.absoluteString ?? "nil")
emit("url.relative-round-trip", (bridgedRelative as URL) == relative)

let cache = NSCache<NSURL, Value>()
emit("cache.default-name", cache.name)
emit("cache.default-count-limit", cache.countLimit)
emit("cache.default-cost-limit", cache.totalCostLimit)
emit("cache.default-discards", cache.evictsObjectsWithDiscardedContent)

let keyOne = URL(string: "https://example.com/image")! as NSURL
let keyTwo = URL(string: "https://example.com/image")! as NSURL
cache.setObject(Value(1), forKey: keyOne)
emit("cache.equal-key-hit", cache.object(forKey: keyTwo)?.marker ?? -1)
cache.setObject(Value(2), forKey: keyTwo)
emit("cache.replace", cache.object(forKey: keyOne)?.marker ?? -1)

let explicitDelegate = Delegate()
explicitDelegate.expectedIdentity = ObjectIdentifier(cache)
cache.delegate = explicitDelegate
cache.setObject(Value(3), forKey: keyOne)
cache.setObject(Value(4), forKey: keyTwo)
emit("cache.replace-delegate", explicitDelegate.evicted)
cache.removeObject(forKey: keyOne)
emit("cache.explicit-remove-delegate", explicitDelegate.evicted)
emit("cache.delegate-same-identity", explicitDelegate.sameIdentity)

let countCache = NSCache<NSURL, Value>()
let countDelegate = Delegate()
countCache.delegate = countDelegate
countCache.countLimit = 1
countCache.setObject(Value(10), forKey: URL(string: "https://example.com/10")! as NSURL)
countCache.setObject(Value(11), forKey: URL(string: "https://example.com/11")! as NSURL)
emit("cache.count-evicted", countDelegate.evicted)
emit("cache.count-first-present", countCache.object(forKey: URL(string: "https://example.com/10")! as NSURL) != nil)
emit("cache.count-second-present", countCache.object(forKey: URL(string: "https://example.com/11")! as NSURL) != nil)

let costCache = NSCache<NSURL, Value>()
let costDelegate = Delegate()
costCache.delegate = costDelegate
costCache.totalCostLimit = 2
costCache.setObject(Value(20), forKey: URL(string: "https://example.com/20")! as NSURL, cost: 2)
costCache.setObject(Value(21), forKey: URL(string: "https://example.com/21")! as NSURL, cost: 1)
emit("cache.cost-evicted", costDelegate.evicted)
emit("cache.cost-first-present", costCache.object(forKey: URL(string: "https://example.com/20")! as NSURL) != nil)
emit("cache.cost-second-present", costCache.object(forKey: URL(string: "https://example.com/21")! as NSURL) != nil)

costCache.removeAllObjects()
emit("cache.remove-all-delegate", costDelegate.evicted)
emit("cache.remove-all-empty", costCache.object(forKey: URL(string: "https://example.com/21")! as NSURL) == nil)

let lateLimitCache = NSCache<NSURL, Value>()
let lateLimitDelegate = Delegate()
lateLimitCache.delegate = lateLimitDelegate
lateLimitCache.setObject(Value(30), forKey: URL(string: "https://example.com/30")! as NSURL)
lateLimitCache.setObject(Value(31), forKey: URL(string: "https://example.com/31")! as NSURL)
lateLimitCache.countLimit = 1
emit("cache.late-count-evicted", lateLimitDelegate.evicted)
emit("cache.late-count-present", [30, 31].filter { marker in
    lateLimitCache.object(forKey: URL(string: "https://example.com/\(marker)")! as NSURL) != nil
})

let negativeCostCache = NSCache<NSURL, Value>()
let negativeCostDelegate = Delegate()
negativeCostCache.delegate = negativeCostDelegate
negativeCostCache.totalCostLimit = 1
negativeCostCache.setObject(Value(40), forKey: URL(string: "https://example.com/40")! as NSURL, cost: -100)
emit("cache.negative-cost-after-first", negativeCostDelegate.evicted)
negativeCostCache.setObject(Value(41), forKey: URL(string: "https://example.com/41")! as NSURL, cost: 1)
emit("cache.negative-cost-evicted", negativeCostDelegate.evicted)
emit("cache.negative-cost-present", [40, 41].filter { marker in
    negativeCostCache.object(forKey: URL(string: "https://example.com/\(marker)")! as NSURL) != nil
})

let recencyCache = NSCache<NSURL, Value>()
let recencyDelegate = Delegate()
recencyCache.delegate = recencyDelegate
recencyCache.countLimit = 2
let recency50 = URL(string: "https://example.com/50")! as NSURL
let recency51 = URL(string: "https://example.com/51")! as NSURL
let recency52 = URL(string: "https://example.com/52")! as NSURL
recencyCache.setObject(Value(50), forKey: recency50)
recencyCache.setObject(Value(51), forKey: recency51)
_ = recencyCache.object(forKey: recency50)
recencyCache.setObject(Value(52), forKey: recency52)
emit("cache.access-recency-evicted", recencyDelegate.evicted)
emit("cache.access-recency-present", [50, 51, 52].filter { marker in
    recencyCache.object(forKey: URL(string: "https://example.com/\(marker)")! as NSURL) != nil
})

let retentionCache = NSCache<NSURL, Value>()
weak var retainedKey: NSURL?
weak var retainedValue: Value?
do {
    let key = URL(string: "https://example.com/retained")! as NSURL
    let value = Value(60)
    retainedKey = key
    retainedValue = value
    retentionCache.setObject(value, forKey: key)
}
emit("cache.retains-key", retainedKey != nil)
emit("cache.retains-value", retainedValue != nil)
retentionCache.removeObject(
    forKey: URL(string: "https://example.com/retained")! as NSURL
)
emit("cache.releases-key", retainedKey == nil)
emit("cache.releases-value", retainedValue == nil)

weak var releasedDelegate: Delegate?
do {
    let ephemeralDelegate = Delegate()
    releasedDelegate = ephemeralDelegate
    retentionCache.delegate = ephemeralDelegate
}
emit("cache.delegate-is-weak", releasedDelegate == nil)
