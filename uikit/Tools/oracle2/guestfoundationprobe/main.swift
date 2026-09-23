// guestfoundationprobe -- the Apple side and the guest side of the guest
// Foundation facade gaps (docs/agent_reports/guest-swift-modules.md).
//
// The SAME file is compiled against the iOS 26.1 simulator's Foundation
// (run.sh, transcript-ios26.1.txt) and against the Linux Mach-O guest's
// Foundation facade (Tools/guestprobes/GuestFoundationProbe.probe.sh), whose
// output must equal the simulator transcript line for line. Only
// deterministic facts are printed: no addresses, no timings beyond bounds.
import Foundation

final class ThreadBox: @unchecked Sendable {
    let lock = NSLock()
    var lines: [String] = []
    func add(_ line: String) { lock.lock(); lines.append(line); lock.unlock() }
}

final class SelectorTarget: NSObject, @unchecked Sendable {
    let done = DispatchSemaphore(value: 0)
    var seen = ""
    @objc func run(_ argument: Any?) {
        seen = "arg=\(argument as? String ?? "nil") main=\(Thread.isMainThread)"
        done.signal()
    }
}

final class SubclassedThread: Thread, @unchecked Sendable {
    let done = DispatchSemaphore(value: 0)
    var ranMain = false
    var sawSelf = false
    var seenName = ""
    override func main() {
        ranMain = true
        sawSelf = Thread.current === self
        seenName = String(describing: Thread.current.name)
        done.signal()
    }
}

func say(_ section: String, _ items: Any...) {
    print(([section] + items.map { "\($0)" }).joined(separator: " "))
}

func threads() {
    say("thread.main", "isMainThread=\(Thread.isMainThread)",
        "current.isMainThread=\(Thread.current.isMainThread)",
        "current===main=\(Thread.current === Thread.main)",
        "main.isMainThread=\(Thread.main.isMainThread)",
        "stable=\(Thread.current === Thread.current)")
    say("thread.main.name", "\(String(describing: Thread.main.name))")
    say("thread.main.qos", Thread.main.qualityOfService.rawValue)
    say("thread.main.state", "executing=\(Thread.main.isExecuting)",
        "finished=\(Thread.main.isFinished)", "cancelled=\(Thread.main.isCancelled)")
    say("thread.callStackSymbols.nonEmpty", !Thread.callStackSymbols.isEmpty)
    say("thread.callStackReturnAddresses.nonEmpty", !Thread.callStackReturnAddresses.isEmpty)

    let dict = Thread.current.threadDictionary
    dict["guest.probe"] = "value"
    say("thread.threadDictionary", "roundtrip=\(dict["guest.probe"] as? String ?? "nil")",
        "sameObject=\(dict === Thread.current.threadDictionary)")
    dict.removeObject(forKey: "guest.probe")
    say("thread.threadDictionary.removed", dict["guest.probe"] == nil)

    // A fresh Thread is not started: not executing, not finished.
    let idle = Thread { }
    say("thread.new", "executing=\(idle.isExecuting)", "finished=\(idle.isFinished)",
        "cancelled=\(idle.isCancelled)", "isMainThread=\(idle.isMainThread)",
        "name=\(String(describing: idle.name))",
        "qos=\(idle.qualityOfService.rawValue)", "stackSize=\(idle.stackSize)",
        "priority=\(idle.threadPriority)")
    idle.cancel()
    say("thread.new.cancel", "cancelled=\(idle.isCancelled)", "finished=\(idle.isFinished)")

    // Thread(block:) with a name; the block observes its own identity.
    let box = ThreadBox()
    let started = DispatchSemaphore(value: 0)
    var worker: Thread!
    worker = Thread {
        let me = Thread.current
        box.add("thread.block isMainThread=\(Thread.isMainThread) current.isMainThread=\(me.isMainThread) current===worker=\(me === worker!) current===main=\(me === Thread.main) name=\(String(describing: me.name)) executing=\(me.isExecuting) finished=\(me.isFinished) stable=\(me === Thread.current)")
        me.threadDictionary["k"] = 1
        box.add("thread.block.dictionary own=\(me.threadDictionary["k"] as? Int ?? -1)")
        started.signal()
    }
    worker.name = "guest-probe-worker"
    worker.stackSize = 1 << 20
    say("thread.block.beforeStart", "name=\(worker.name ?? "nil")", "stackSize=\(worker.stackSize)")
    worker.start()
    started.wait()
    // isFinished flips after the block returns; poll with a bound.
    let deadline = Date().addingTimeInterval(5)
    while !worker.isFinished && Date() < deadline { Thread.sleep(forTimeInterval: 0.001) }
    for line in box.lines { print(line) }
    say("thread.block.after", "finished=\(worker.isFinished)", "executing=\(worker.isExecuting)")
    say("thread.main.dictionary.untouched", Thread.main.threadDictionary["k"] == nil)

    // detachNewThread
    let detached = DispatchSemaphore(value: 0)
    let dbox = ThreadBox()
    Thread.detachNewThread {
        dbox.add("thread.detach isMainThread=\(Thread.isMainThread) current===main=\(Thread.current === Thread.main) name=\(String(describing: Thread.current.name)) executing=\(Thread.current.isExecuting)")
        detached.signal()
    }
    detached.wait()
    for line in dbox.lines { print(line) }
    say("thread.isMultiThreaded", Thread.isMultiThreaded())

    // detachNewThreadSelector
    let target = SelectorTarget()
    Thread.detachNewThreadSelector(#selector(SelectorTarget.run(_:)), toTarget: target, with: "payload")
    target.done.wait()
    say("thread.detachSelector", target.seen)

    // Thread(target:selector:object:)
    let target2 = SelectorTarget()
    let selThread = Thread(target: target2, selector: #selector(SelectorTarget.run(_:)), object: "obj")
    selThread.start()
    target2.done.wait()
    say("thread.targetSelector", target2.seen)

    // Subclass overriding main()
    let sub = SubclassedThread()
    sub.start()
    sub.done.wait()
    say("thread.subclass", "ranMain=\(sub.ranMain)", "sawSelf=\(sub.sawSelf)", "name=\(sub.seenName)")

    // Cancelled before start: does the body still run?
    let ranBox = ThreadBox()
    let early = Thread { ranBox.add("ran") }
    early.cancel()
    early.start()
    let earlyDeadline = Date().addingTimeInterval(5)
    while !early.isFinished && Date() < earlyDeadline { Thread.sleep(forTimeInterval: 0.001) }
    Thread.sleep(forTimeInterval: 0.05)
    say("thread.cancelledThenStarted", "finished=\(early.isFinished)", "cancelled=\(early.isCancelled)",
        "bodyRan=\(!ranBox.lines.isEmpty)")

    // A dispatch worker thread is a Thread too, not the main one.
    let gq = DispatchSemaphore(value: 0)
    let gbox = ThreadBox()
    DispatchQueue.global().async {
        gbox.add("thread.dispatchGlobal isMainThread=\(Thread.isMainThread) current===main=\(Thread.current === Thread.main) stable=\(Thread.current === Thread.current) name=\(String(describing: Thread.current.name)) executing=\(Thread.current.isExecuting)")
        gq.signal()
    }
    gq.wait()
    for line in gbox.lines { print(line) }

    // sleep
    let t0 = Date()
    Thread.sleep(forTimeInterval: 0.05)
    let slept = Date().timeIntervalSince(t0)
    say("thread.sleep.forTimeInterval", "atLeast50ms=\(slept >= 0.049)", "under2s=\(slept < 2)")
    let t1 = Date()
    Thread.sleep(until: t1.addingTimeInterval(0.03))
    let slept2 = Date().timeIntervalSince(t1)
    say("thread.sleep.until", "atLeast30ms=\(slept2 >= 0.029)", "under2s=\(slept2 < 2)")
    let t2 = Date()
    Thread.sleep(until: t2.addingTimeInterval(-10))
    say("thread.sleep.past", "returnsImmediately=\(Date().timeIntervalSince(t2) < 0.5)")
}

/// Never answers: a resumed task stays outstanding until it is cancelled.
final class HangingProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {}
    override func stopLoading() {}
}

func locks() {
    let recursive = NSRecursiveLock()
    recursive.lock(); recursive.lock()
    let tryOwn = recursive.try()
    recursive.unlock(); recursive.unlock(); recursive.unlock()
    let other = DispatchSemaphore(value: 0)
    let obox = ThreadBox()
    recursive.lock()
    Thread.detachNewThread {
        obox.add("otherTry=\(recursive.try())")
        obox.add("otherBefore=\(recursive.lock(before: Date(timeIntervalSinceNow: 0.02)))")
        other.signal()
    }
    other.wait()
    recursive.unlock()
    say("lock.recursive", "reentrant=\(tryOwn)", obox.lines.joined(separator: " "),
        "name=\(String(describing: recursive.name))")

    let condition = NSCondition()
    var ready = false
    let cbox = ThreadBox()
    let finished = DispatchSemaphore(value: 0)
    Thread.detachNewThread {
        condition.lock()
        while !ready { condition.wait() }
        cbox.add("woken ready=\(ready)")
        condition.unlock()
        finished.signal()
    }
    Thread.sleep(forTimeInterval: 0.02)
    condition.lock(); ready = true; condition.signal(); condition.unlock()
    finished.wait()
    condition.lock()
    let timedOut = condition.wait(until: Date(timeIntervalSinceNow: 0.02))
    condition.unlock()
    say("lock.condition", cbox.lines.joined(separator: " "), "waitUntilPast=\(timedOut)")

    let conditionLock = NSConditionLock(condition: 1)
    let wrong = conditionLock.tryLock(whenCondition: 2)
    let right = conditionLock.tryLock(whenCondition: 1)
    conditionLock.unlock(withCondition: 2)
    say("lock.conditionLock", "wrong=\(wrong)", "right=\(right)", "condition=\(conditionLock.condition)",
        "timed=\(conditionLock.lock(whenCondition: 3, before: Date(timeIntervalSinceNow: 0.02)))")
}

func urlSessionTasks() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [HangingProtocol.self]
    let session = URLSession(configuration: configuration)
    func census(_ label: String) {
        let done = DispatchSemaphore(value: 0)
        let box = ThreadBox()
        session.getTasksWithCompletionHandler { data, upload, download in
            box.add("urlsession.getTasks.\(label) data=\(data.count) upload=\(upload.count) download=\(download.count) main=\(Thread.isMainThread)")
            done.signal()
        }
        done.wait()
        for line in box.lines { print(line) }
        let all = DispatchSemaphore(value: 0)
        let abox = ThreadBox()
        session.getAllTasks { tasks in
            abox.add("urlsession.getAllTasks.\(label) count=\(tasks.count) states=\(tasks.map { $0.state.rawValue }.sorted())")
            all.signal()
        }
        all.wait()
        for line in abox.lines { print(line) }
    }
    census("empty")
    // Created but never resumed: not outstanding (measured).
    let url = URL(string: "https://guest-probe.invalid/")!
    let d1 = session.dataTask(with: url)
    let d2 = session.dataTask(with: URLRequest(url: url))
    let u1 = session.uploadTask(with: URLRequest(url: url), from: Data([1, 2, 3]))
    let dl = session.downloadTask(with: url)
    census("created")
    say("urlsession.kinds", "upload.isData=\((u1 as URLSessionTask) is URLSessionDataTask)",
        "d1.state=\(d1.state.rawValue)")
    // Resumed and never answered: outstanding, and split by kind (an upload
    // task is listed as an upload, not as a data task).
    d1.resume(); d2.resume(); u1.resume(); dl.resume()
    census("resumed")
    d2.suspend()
    census("oneSuspended")
    // Cancelling completes a task; it leaves the census.
    let cancelled = DispatchSemaphore(value: 0)
    let cancelBox = ThreadBox()
    let d3 = session.dataTask(with: url) { _, _, error in
        let code = (error as? URLError)?.code.rawValue ?? 0
        cancelBox.add("urlsession.cancel.completion code=\(code)")
        cancelled.signal()
    }
    d3.resume()
    d3.cancel()
    cancelled.wait()
    for line in cancelBox.lines { print(line) }
    d1.cancel(); d2.cancel(); u1.cancel(); dl.cancel()
    // Completion is asynchronous; wait for the census to drain with a bound.
    let deadline = Date().addingTimeInterval(5)
    var remaining = -1
    while Date() < deadline {
        let done = DispatchSemaphore(value: 0)
        let box = ThreadBox()
        session.getAllTasks { box.add("\($0.count)"); done.signal() }
        done.wait()
        remaining = Int(box.lines.first ?? "-1") ?? -1
        if remaining == 0 { break }
        Thread.sleep(forTimeInterval: 0.01)
    }
    say("urlsession.afterCancel", "remaining=\(remaining)")
    session.invalidateAndCancel()
}

func defaults() {
    let suite = "guest.probe.defaults.\(getpid())"
    guard let store = UserDefaults(suiteName: suite) else { say("defaults.suite", "nil"); return }
    store.setValue("hello", forKey: "s")
    store.setValue(42, forKey: "i")
    store.setValue(true, forKey: "b")
    say("defaults.setValue", "string=\(store.string(forKey: "s") ?? "nil")",
        "integer=\(store.integer(forKey: "i"))", "bool=\(store.bool(forKey: "b"))",
        "object=\(store.object(forKey: "s") as? String ?? "nil")",
        "value=\(store.value(forKey: "s") as? String ?? "nil")")
    store.setValue(nil, forKey: "s")
    say("defaults.setValue.nil", "removed=\(store.object(forKey: "s") == nil)")
    store.removePersistentDomain(forName: suite)
}

func nsstringNumbers() {
    let inputs = ["3.5", " 12abc", "abc", "1e3", "", "  -2.5e-1x", "0x10", "+7", ".5", "5.",
                  "1,5", "\t\n 8", "inf", "-infinity", "nan", "1e400", "-1e400", "1e-400",
                  "00012.50", "٣", "1_000", "  +", "-", "9007199254740993",
                  "\t8", "\n8", "\u{a0}8", "\u{2003}8", "\u{3000}8", "2e", "2e+", "2E2", "-.5",
                  "+-1", "--1", " - 1", "1.5e+2.5", "٣.٥", "１２", "0.1e1", "1e-2", ".", "e5",
                  "4.9e-324", "2.5e-324", "1.7976931348623157e308", "123456789012345678901234567890",
                  "-0", "0000", "3.99999999999999999999", " \u{0660}1"]
    for text in inputs {
        let ns = text as NSString
        let escaped = text.unicodeScalars.map { $0.isASCII && $0.value >= 32 ? String($0) : "\\u{\(String($0.value, radix: 16))}" }.joined()
        say("nsstring.numbers", "[\(escaped)]", "double=\(ns.doubleValue)", "float=\(ns.floatValue)",
            "int=\(ns.intValue)", "integer=\(ns.integerValue)", "longLong=\(ns.longLongValue)",
            "bool=\(ns.boolValue)")
    }
    for text in ["YES", "yes", "Y", "t", "true", "1", "0", "no", " 2", "-1", "+1", "0.9", "N"] {
        say("nsstring.bool", "[\(text)]", (text as NSString).boolValue)
    }
    for text in ["2147483648", "-2147483649", "9223372036854775808", "-9223372036854775809", "12.9", "-12.9"] {
        let ns = text as NSString
        say("nsstring.int", "[\(text)]", "int=\(ns.intValue)", "integer=\(ns.integerValue)",
            "longLong=\(ns.longLongValue)")
    }
}

func stringFormatLocale() {
    // NetNewsWire ActivityLog's own calls.
    let posix = Locale(identifier: "en_US_POSIX")
    say("string.format.locale", String(format: "%.2fs", locale: posix, 3.14159))
    say("string.format.locale", String(format: "%.1fs", locale: posix, 12.25))
    say("string.format.locale.nil", String(format: "%.3f", locale: nil, 2.0))
    say("string.format.locale.args", String(format: "%@-%ld", locale: posix, arguments: ["a", 7]))
    // With any locale: upper-case exponent, the '0' flag pads with spaces.
    // Values stay under 1000, so no grouping is involved: the guest's
    // Locale(identifier:) is en_001 for every identifier today (see
    // docs/agent_reports/guest-swift-modules.md), which would make grouping
    // rows compare the guest's Locale rather than String(format:locale:).
    let text = String(format: "%d|%.2f|%f|%.0f|%e|%g|%5.1f|%-8.1f|%08.2f|%+.1f|%@|%i|%u|%x|%.3g|%E",
                      locale: posix, 123, 123.891, 12.5, 12.5, 12.5, 12.5, 12.5, 12.25, 12.25, 3.5,
                      "s", -12, 12, 255, 1.2345678, 0.000123)
    say("string.format.locale.posix", text)
}

@main
struct GuestFoundationProbe {
    static func main() {
        print("guestfoundationprobe v1")
        threads()
        locks()
        urlSessionTasks()
        defaults()
        nsstringNumbers()
        stringFormatLocale()
        print("guestfoundationprobe done")
    }
}
