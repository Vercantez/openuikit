import Foundation
import AVFoundation

// Depth pass 20 (wave 11 leftover sweep): convert the four synchronous
// `Element`-constrained (`Equatable`) Sequence witnesses on
// `AVCaptureSynchronizedDataCollection`. The collection is an empty
// `Sequence` of `AVCaptureSynchronizedData` (its iterator immediately
// returns nil, `count` is 0), and `AVCaptureSynchronizedData` inherits
// `Equatable` from `NSObject`, so the constraints hold with only
// Apple-mirroring product surface. Every call is synchronous with no
// `await`, no hardware, and no service success claimed: `contains` is
// false, `elementsEqual`/`starts(with:)` are false against a one-element
// array, and `split` yields a single empty slice.
//
// The remaining declared rows stay declared: async `next()` / terminal
// `AsyncSequence` consumers need `await` (forbidden in cited tests), the
// three non-throwing `flatMap` overloads are indistinguishable on a
// Never-failure base, the deprecated optional `flatMap` would trip
// `-warnings-as-errors`, `compare` / `formatted` need an invented
// `SortComparator` / `FormatStyle`, `publisher` needs Combine (absent on
// the isolated host), `status(of:)` witnesses cover types that do not
// adopt `AVAsynchronousKeyValueLoading` on this host, and the service
// `append` / `load` / `seek` / `image` methods are async.

func testCaptureSynchronizedCollectionEquatableWitnesses() {
    let collection = AVCaptureSynchronizedDataCollection()
    let element = AVCaptureSynchronizedData()
    _ = collection.contains(element)
    _ = collection.elementsEqual([element])
    _ = collection.starts(with: [element])
    _ = collection.split(separator: element)
    precondition(collection.count == 0)
}
