import Foundation

/// iMessage extension presentation style.
///
/// Raw values match the pinned macios `[Native]` `ulong` order
/// (`Compact`, `Expanded`, `Transcript`). The Swift overlay uses `UInt`.
public enum MSMessagesAppPresentationStyle: UInt, Hashable, Sendable {
    case compact = 0
    case expanded = 1
    case transcript = 2
}

/// iMessage presentation context.
///
/// The Apple Swift overlay uses `UInt` raw values (`init?(rawValue: UInt)`
/// in the pinned graph). Case order matches macios (`Messages`, `Media`).
public enum MSMessagesAppPresentationContext: UInt, Hashable, Sendable {
    case messages = 0
    case media = 1
}

/// Sticker browser cell size.
///
/// Raw values match the pinned macios `[Native]` `long` order
/// (`Small`, `Regular`, `Large`). Point sizes quoted in those bindings
/// (100 / 136 / 206) are not independently measured here.
public enum MSStickerSize: Int, Hashable, Sendable {
    case small = 0
    case regular = 1
    case large = 2
}
