@_spi(OpenUIKitHost) import Photos
import Foundation

// public-surface.tsv records Sequence.formatted(_:) with Self == FormatInput;
// api-crosswalk.tsv marks it unmatched because it is a Foundation overlay.
// Use the real Foundation protocol with the concrete Photos sequence input.
private struct PhotosInsertedAssetCountsStyle: FormatStyle {
    var multiplier: Int = 1

    func format(_ value: PHPersistentChangeFetchResult) -> [Int] {
        value.map { change in
            let details = try! change.changeDetails(for: .asset)
            return details.insertedLocalIdentifiers.count * multiplier
        }
    }
}

private struct PhotosInsertedAssetCountComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: PHPersistentChange, _ rhs: PHPersistentChange) -> ComparisonResult {
        let left = try! lhs.changeDetails(for: .asset).insertedLocalIdentifiers.count
        let right = try! rhs.changeDetails(for: .asset).insertedLocalIdentifiers.count
        if left == right { return .orderedSame }
        let ascending = order == .forward ? left < right : left > right
        return ascending ? .orderedAscending : .orderedDescending
    }
}

func testPersistentChangeSortedUsingComparators() {
    PHPhotoLibraryPortable._reset()
    defer { PHPhotoLibraryPortable._reset() }
    PHPhotoLibraryPortable._setStatus(.authorized, for: .readWrite)
    let library = PHPhotoLibrary.shared()
    let token = library.currentChangeToken
    for count in [2, 1, 2] {
        try! library.performChangesAndWait {
            for _ in 0..<count {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
            }
        }
    }
    let result = try! library.fetchPersistentChanges(since: token)
    let original = Array(result)
    precondition(PhotosInsertedAssetCountsStyle().format(result) == [2, 1, 2])
    // These are the two distinct Foundation sorted(using:) overloads in the
    // sealed graph: one comparator and a sequence of comparators.
    let ascending = result.sorted(using: PhotosInsertedAssetCountComparator())
    precondition(ascending == [original[1], original[0], original[2]])
    let descending = result.sorted(using: [PhotosInsertedAssetCountComparator(order: .reverse)])
    precondition(descending == [original[0], original[2], original[1]])
    let unchanged = result.sorted(using: [PhotosInsertedAssetCountComparator]())
    precondition(unchanged == original)
    precondition(Array(result) == original)
}

func testPersistentChangeFormattedStyle() {
    PHPhotoLibraryPortable._reset()
    defer { PHPhotoLibraryPortable._reset() }
    PHPhotoLibraryPortable._setStatus(.authorized, for: .readWrite)
    let library = PHPhotoLibrary.shared()
    let token = library.currentChangeToken
    let empty = try! library.fetchPersistentChanges(since: token)
    precondition(empty.formatted(PhotosInsertedAssetCountsStyle()) == [])

    try! library.performChangesAndWait {
        _ = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
    }
    let first = try! library.fetchPersistentChanges(since: token)
    precondition(first.formatted(PhotosInsertedAssetCountsStyle()) == [1])

    try! library.performChangesAndWait {
        _ = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
        _ = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
    }
    let both = try! library.fetchPersistentChanges(since: token)
    precondition(both.formatted(PhotosInsertedAssetCountsStyle()) == [1, 2])
    // Distinct style state proves formatted forwards the supplied instance.
    precondition(both.formatted(PhotosInsertedAssetCountsStyle(multiplier: 10)) == [10, 20])
    precondition(both.formatted(PhotosInsertedAssetCountsStyle()) == [1, 2])
    precondition(first.formatted(PhotosInsertedAssetCountsStyle()) == [1])
    precondition(empty.formatted(PhotosInsertedAssetCountsStyle()) == [])
}
