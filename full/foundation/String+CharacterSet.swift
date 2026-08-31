//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// The scalar-boundary walk is derived from swift-foundation
// Sources/FoundationEssentials/String/String+Bridging.swift at pinned commit
// c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc. That implementation is otherwise
// excluded from standalone FoundationEssentials by FOUNDATION_FRAMEWORK.

import FoundationEssentials

public extension String {
    /// Returns substrings divided at every Unicode scalar contained in `set`.
    ///
    /// Foundation treats each matching scalar as one separator and preserves
    /// empty components at the beginning, end, and between adjacent matches.
    /// Walking the scalar view is required here: `CharacterSet` membership is
    /// scalar-based, while Swift `Character` iteration is grapheme-based.
    func components(separatedBy set: CharacterSet) -> [String] {
        let scalars = unicodeScalars
        var result: [String] = []
        var componentStart = scalars.startIndex
        var cursor = scalars.startIndex

        while cursor < scalars.endIndex {
            guard set.contains(scalars[cursor]) else {
                scalars.formIndex(after: &cursor)
                continue
            }

            result.append(String(self[componentStart..<cursor]))
            scalars.formIndex(after: &cursor)
            componentStart = cursor
        }

        result.append(String(self[componentStart..<scalars.endIndex]))
        return result
    }

    /// Returns a new string made by removing scalars in `set` from both ends.
    func trimmingCharacters(in set: CharacterSet) -> String {
        let scalars = unicodeScalars
        var lower = scalars.startIndex

        while lower < scalars.endIndex && set.contains(scalars[lower]) {
            scalars.formIndex(after: &lower)
        }

        guard lower != scalars.endIndex else {
            return ""
        }

        var upper = scalars.endIndex
        repeat {
            scalars.formIndex(before: &upper)
        } while upper > lower && set.contains(scalars[upper])

        if set.contains(scalars[upper]) {
            return ""
        }

        return String(scalars[lower...upper])
    }

    /// Finds the first scalar belonging to `set` in the requested range.
    func rangeOfCharacter(
        from set: CharacterSet,
        options: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> Range<Index>? {
        let bounds = searchRange ?? startIndex..<endIndex
        guard bounds.lowerBound <= bounds.upperBound else { return nil }
        let scalars = unicodeScalars

        if options.contains(.backwards) {
            var upper = bounds.upperBound
            while upper > bounds.lowerBound {
                let lower = scalars.index(before: upper)
                if set.contains(scalars[lower]) {
                    if !options.contains(.anchored) || upper == bounds.upperBound {
                        return lower..<upper
                    }
                    return nil
                }
                if options.contains(.anchored) { return nil }
                upper = lower
            }
            return nil
        }

        var lower = bounds.lowerBound
        while lower < bounds.upperBound {
            let upper = scalars.index(after: lower)
            if set.contains(scalars[lower]) { return lower..<upper }
            if options.contains(.anchored) { return nil }
            lower = upper
        }
        return nil
    }
}
