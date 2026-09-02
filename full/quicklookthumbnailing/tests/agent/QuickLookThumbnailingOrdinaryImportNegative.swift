import QuickLookThumbnailing

/// Ordinary-import negative surface probe. Compiled separately with a plain
/// `import QuickLookThumbnailing` and must fail to typecheck SPI / graph-absent
/// host controls. Not a `*Tests.swift` file: the sealed runner requires tests
/// to compile.
enum QuickLookThumbnailingOrdinaryImportNegative {
    static func mustNotSeeLinuxPortSPI(_ generator: QLThumbnailGenerator) {
        _ = generator.callbackQueue
    }
}
