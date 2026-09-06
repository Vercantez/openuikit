@_exported import Foundation

/// Linux starting point for Apple's public `Assignables` module.
///
/// Value types, assignment state, scoring arithmetic, and error codes are
/// real and process-local. PDF import/export, thumbnails, Pencil markup, and
/// SwiftUI layout require Apple services that this host does not provide.
/// Those paths stay fail-closed or inert (`EmptyView`, empty `PDFDocument`).
///
/// This file is the required primary product source for the sealed fan-out
/// gate. Declarations live in the companion sources listed in
/// `assignables_guest_sources.txt`.
public enum AssignablesModule {
    /// Human-readable overlay identity; not an Apple public symbol.
    public static let portableOverlayName = "Assignables"
}
