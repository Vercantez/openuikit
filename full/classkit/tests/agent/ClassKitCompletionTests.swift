import Foundation
import ClassKit

/// Synchronous completion-handler overlays for the async ClassKit query APIs.
///
/// Apple's `descendantMatchingIdentifierPath:completion:`,
/// `contextsMatchingIdentifierPath:completion:`,
/// `contextsMatchingPredicate:completion:`, `fetchActivityForURL:completion:`,
/// and `updateDescendantsOfContext:completion:` arrive as `async` Swift
/// projections. Each completion below runs before its method returns, so
/// these tests stay synchronous with no suspension, semaphores, or run loops.

func testDescendantMatchingIdentifierPathCompletion() {
    classKitResetStore()
    let root = CLSDataStore.shared.mainAppContext
    let chapter = CLSContext(type: .chapter, identifier: "ch1", title: "Chapter 1")
    let section = CLSContext(type: .section, identifier: "sec1", title: "Section 1")
    root.addChildContext(chapter)
    chapter.addChildContext(section)

    var resolved: CLSContext?
    var resolveError: (any Error)?
    var resolveCalls = 0
    chapter.descendant(matchingIdentifierPath: ["sec1"]) { context, error in
        resolveCalls += 1
        resolved = context
        resolveError = error
    }
    classKitExpect(resolveCalls == 1, "completion once")
    classKitExpect(resolved === section, "resolved section")
    classKitExpect(resolveError == nil, "no error")

    var missing: CLSContext?
    var missingError: (any Error)?
    var missingCalls = 0
    chapter.descendant(matchingIdentifierPath: ["nope"]) { context, error in
        missingCalls += 1
        missing = context
        missingError = error
    }
    classKitExpect(missingCalls == 1, "missing completion once")
    classKitExpect(missing == nil, "missing nil")
    classKitExpect((missingError as? CLSError)?.code == .invalidArgument, "invalidArgument")
}

func testContextsMatchingIdentifierPathCompletion() {
    classKitResetStore()
    let store = CLSDataStore.shared
    let chapter = CLSContext(type: .chapter, identifier: "ch1", title: "Chapter 1")
    store.mainAppContext.addChildContext(chapter)

    var resolved: [CLSContext]?
    var resolveError: (any Error)?
    var resolveCalls = 0
    store.contexts(matchingIdentifierPath: ["ch1"]) { contexts, error in
        resolveCalls += 1
        resolved = contexts
        resolveError = error
    }
    classKitExpect(resolveCalls == 1, "completion once")
    classKitExpect(resolveError == nil, "no error")
    classKitExpect(resolved?.count == 1, "one node")
    classKitExpect(resolved?.first === chapter, "chapter")

    var failed: [CLSContext]?
    var failure: (any Error)?
    store.contexts(matchingIdentifierPath: ["absent"]) { contexts, error in
        failed = contexts
        failure = error
    }
    classKitExpect(failed == nil, "unresolved nil")
    classKitExpect((failure as? CLSError)?.code == .invalidArgument, "invalidArgument")
}

func testContextsMatchingPredicateCompletion() {
    classKitResetStore()
    let store = CLSDataStore.shared
    let wanted = CLSContext(type: .page, identifier: "wanted", title: "Wanted Page")
    let other = CLSContext(type: .page, identifier: "other", title: "Other Page")
    store.mainAppContext.addChildContext(wanted)
    store.mainAppContext.addChildContext(other)
    let predicate = NSPredicate { object, _ in
        (object as? CLSContext)?.title == "Wanted Page"
    }

    var matched: [CLSContext]?
    var matchError: (any Error)?
    var matchCalls = 0
    store.contexts(matching: predicate) { contexts, error in
        matchCalls += 1
        matched = contexts
        matchError = error
    }
    classKitExpect(matchCalls == 1, "completion once")
    classKitExpect(matchError == nil, "no error")
    classKitExpect(matched?.count == 1, "one match")
    classKitExpect(matched?.first === wanted, "wanted page")
}

func testFetchActivityForURLCompletion() {
    classKitResetStore()
    var activity: CLSActivity?
    var received: (any Error)?
    var calls = 0
    CLSDataStore.shared.fetchActivity(for: URL(string: "https://example.test/activity")!) { result, error in
        calls += 1
        activity = result
        received = error
    }
    classKitExpect(calls == 1, "completion once")
    classKitExpect(activity == nil, "no invented activity")
    classKitExpect((received as? CLSError)?.code == .classKitUnavailable, "unavailable")
}

func testUpdateDescendantsCompletion() {
    let provider: any CLSContextProvider = ClassKitEmptyProvider()
    let context = CLSContext(type: .course, identifier: "course", title: "Course")
    var received: (any Error)?
    var calls = 0
    provider.updateDescendants(of: context) { error in
        calls += 1
        received = error
    }
    classKitExpect(calls == 1, "completion once")
    classKitExpect((received as? CLSError)?.code == .classKitUnavailable, "unavailable")
}
