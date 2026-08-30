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

public extension String {
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
}
