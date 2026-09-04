extension Transferable {
    public var suggestedFilename: String? {
        _hostSuggestedFilenameUsingRepresentation(
            Self.transferRepresentation,
            item: self
        )
    }

    public static func exportedContentTypes(
        visibility: TransferRepresentationVisibility = .all
    ) -> [UTType] {
        transferRepresentation._hostExportedContentTypes(visibility: visibility)
    }

    public func exportedContentTypes(
        _ visibility: TransferRepresentationVisibility = .all
    ) -> [UTType] {
        Self.exportedContentTypes(visibility: visibility)
    }

    public static func importedContentTypes() -> [UTType] {
        transferRepresentation._hostImportedContentTypes()
    }

    public func importedContentTypes() -> [UTType] {
        Self.importedContentTypes()
    }

    public func exported(as contentType: UTType?) async throws -> Data {
        try await _hostExportDataUsingRepresentation(
            Self.transferRepresentation,
            item: self,
            contentType: contentType
        )
    }

    public func export(
        to destinationDirectory: URL,
        contentType: UTType?
    ) async throws -> URL {
        let sent = try await _hostExportFileUsingRepresentation(
            Self.transferRepresentation,
            item: self,
            contentType: contentType
        )
        try FileManager.default.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )
        let name = suggestedFilename ?? sent.file.lastPathComponent
        let destination = destinationDirectory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sent.file, to: destination)
        return destination
    }

    public func withExportedFile<Result>(
        contentType: UTType?,
        fileHandler: (URL) async throws -> Result
    ) async throws -> Result {
        let sent = try await _hostExportFileUsingRepresentation(
            Self.transferRepresentation,
            item: self,
            contentType: contentType
        )
        return try await fileHandler(sent.file)
    }

    public init(importing data: Data, contentType: UTType?) async throws {
        self = try await _hostImportDataUsingRepresentation(
            Self.transferRepresentation,
            data: data,
            contentType: contentType
        )
    }

    public init(importing file: URL, contentType: UTType?) async throws {
        self = try await _hostImportFileUsingRepresentation(
            Self.transferRepresentation,
            file: ReceivedTransferredFile(file: file, isOriginalFile: false),
            contentType: contentType
        )
    }

    func _hostSentFile(contentType: UTType?) async throws -> SentTransferredFile {
        try await _hostExportFileUsingRepresentation(
            Self.transferRepresentation,
            item: self,
            contentType: contentType
        )
    }
}

private func _hostSuggestedFilenameUsingRepresentation<R: TransferRepresentation, T>(
    _ representation: R,
    item: T
) -> String? {
    guard let typed = item as? R.Item else { return nil }
    return representation._hostSuggestedFileName(typed)
}

private func _hostExportDataUsingRepresentation<R: TransferRepresentation, T>(
    _ representation: R,
    item: T,
    contentType: UTType?
) async throws -> Data {
    guard let typed = item as? R.Item else {
        throw TransferableError.exportNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }
    return try await representation._hostExportData(typed, contentType: contentType)
}

private func _hostExportFileUsingRepresentation<R: TransferRepresentation, T>(
    _ representation: R,
    item: T,
    contentType: UTType?
) async throws -> SentTransferredFile {
    guard let typed = item as? R.Item else {
        throw TransferableError.exportNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }
    return try await representation._hostExportFile(typed, contentType: contentType)
}

private func _hostImportDataUsingRepresentation<R: TransferRepresentation, T>(
    _ representation: R,
    data: Data,
    contentType: UTType?
) async throws -> T {
    let imported = try await representation._hostImportData(
        data,
        contentType: contentType
    )
    guard let typed = imported as? T else {
        throw TransferableError.importNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }
    return typed
}

private func _hostImportFileUsingRepresentation<R: TransferRepresentation, T>(
    _ representation: R,
    file: ReceivedTransferredFile,
    contentType: UTType?
) async throws -> T {
    let imported = try await representation._hostImportFile(
        file,
        contentType: contentType
    )
    guard let typed = imported as? T else {
        throw TransferableError.importNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }
    return typed
}
