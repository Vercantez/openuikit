// concurrency_probe — does _Concurrency actually SCHEDULE, or merely link?
//
// Every check is designed to FAIL on a runtime that compiles and then does
// nothing. That is the failure mode this stack keeps hitting: the 64 KiB
// InitialAllocationPool that made small programs falsely pass the VA-ceiling
// check, empty Windows-guarded TUs counted as passes, a flaky gate read as
// deterministic. Swift ships UnimplementedMainExecutor/UnimplementedTaskExecutor
// for the `none` and `hooked` configurations, so "it built" proves nothing.
//
// Checks assert HAPPENS-BEFORE, not interleaving, so the same source is valid
// under a dispatch-backed executor (native macOS — our differential oracle) and
// under the single-threaded CooperativeExecutor (our build). A test that only
// held under one would not be a differential.
//
// Dependencies: stdlib + _Concurrency ONLY. No Foundation, no Darwin, no
// dispatch — the point is to test a build that has none of them.
//
// How each check fails on a runtime that does not schedule:
//   1/2 suspend+resume — the continuation is resumed by a SEPARATE task, so
//                        inline completion cannot produce the required order,
//                        and a dead scheduler hangs instead of falsely passing.
//   3   Task.sleep     — elapsed asserted against the request; a no-op sleep
//                        returns ~0 and fails the lower bound.
//   4   @MainActor hop — with one thread this is invisible to thread identity,
//                        so it is detected by ORDER instead.
//   5   many tasks     — 200 tasks, well past any static pool.

@_silgen_name("exit") func c_exit(_ code: Int32) -> Never

/// Race-free by construction: an actor, not a lock we hope is atomic.
actor Trace {
    private var items: [String] = []
    func note(_ s: String) { items.append(s) }
    func snapshot() -> [String] { items }
}

@MainActor final class Counter {
    var n = 0
    func bump() -> Int { n += 1; return n }
}

nonisolated(unsafe) var failures = 0
func check(_ name: String, _ ok: Bool, _ detail: String = "") {
    print("\(ok ? "PASS" : "FAIL")  \(name)\(detail.isEmpty ? "" : "  [\(detail)]")")
    if !ok { failures += 1 }
}

/// Suspension observable, resumption strictly out of line.
func suspendResume(_ t: Trace) async {
    await t.note("A-before-suspend")
#if INLINE_MUTANT
    // NEGATIVE CONTROL (-DINLINE_MUTANT). Resume inline, the way a runtime that
    // does not really schedule would behave. Checks 1 and 2 MUST fail here. A
    // verification that cannot fail is not a verification.
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        cont.resume()
    }
#else
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        // Resumed by a DIFFERENT task: inline completion is impossible by
        // construction, and a scheduler that never runs it hangs the probe.
        Task { await t.note("B-resumer-ran"); cont.resume() }
    }
#endif
    await t.note("D-after-resume")
}

/// A nonisolated context calling a @MainActor method is a real executor hop
/// even when there is only one thread.
nonisolated func hopToMainActor(_ c: Counter, _ t: Trace) async {
    await t.note("E-before-hop")
    let v = await c.bump()
    await t.note("F-after-hop-\(v)")
}

@main
struct Probe {
    static func main() async {
        let t = Trace()
        await suspendResume(t)
        let s = await t.snapshot()

        check("1 suspension is observable",
              s == ["A-before-suspend", "B-resumer-ran", "D-after-resume"],
              s.joined(separator: ","))
        if let b = s.firstIndex(of: "B-resumer-ran"), let d = s.firstIndex(of: "D-after-resume") {
            check("2 resume happened out of line", b < d)
        } else {
            check("2 resume happened out of line", false, "markers missing")
        }

        // 3: a real wait. ContinuousClock is stdlib+_Concurrency, no Foundation.
        let clock = ContinuousClock()
        let want = Duration.milliseconds(50)
        let start = clock.now
        try? await Task.sleep(for: want)
        let elapsed = start.duration(to: clock.now)
        check("3 Task.sleep waits a measurable interval", elapsed >= want,
              "elapsed=\(elapsed) want>=\(want)")

        let c = await MainActor.run { Counter() }
        let t2 = Trace()
        await hopToMainActor(c, t2)
        let s2 = await t2.snapshot()
        check("4 @MainActor hop from a nonisolated context",
              s2 == ["E-before-hop", "F-after-hop-1"], s2.joined(separator: ","))

        // 5: enough tasks to leave any static pool behind.
        let n = 200
        var done = 0
        await withTaskGroup(of: Int.self) { g in
            for i in 0..<n { g.addTask { i } }
            for await _ in g { done += 1 }
        }
        check("5 \(n) tasks all completed", done == n, "done=\(done)")

        print(failures == 0 ? "ALL CHECKS PASSED" : "\(failures) CHECK(S) FAILED")
        c_exit(failures == 0 ? 0 : 1)
    }
}
