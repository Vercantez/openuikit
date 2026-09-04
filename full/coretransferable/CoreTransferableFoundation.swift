extension Never: Transferable, TransferRepresentation {
    public typealias Representation = Never
    public typealias Item = Never
    public typealias Body = Never

    public static var transferRepresentation: Never {
        preconditionFailure("Never has no transfer representation")
    }

    public var body: Never {
        preconditionFailure("Never has no TransferRepresentation body")
    }
}

extension Data: Transferable {
    public typealias Representation = DataRepresentation<Data>

    public static var transferRepresentation: DataRepresentation<Data> {
        DataRepresentation(
            contentType: .data,
            exporting: { item in item },
            importing: { data in data }
        )
    }
}

extension String: Transferable {
    public typealias Representation = DataRepresentation<String>

    public static var transferRepresentation: DataRepresentation<String> {
        DataRepresentation(
            contentType: .utf8PlainText,
            exporting: { item in Data(item.utf8) },
            importing: { data in
                guard let text = String(data: data, encoding: .utf8) else {
                    throw TransferableError.importNotSupported(
                        contentType: UTType.utf8PlainText.identifier
                    )
                }
                return text
            }
        )
    }
}

extension URL: Transferable {
    public typealias Representation = DataRepresentation<URL>

    public static var transferRepresentation: DataRepresentation<URL> {
        DataRepresentation(
            contentType: .url,
            exporting: { item in Data(item.absoluteString.utf8) },
            importing: { data in
                guard let text = String(data: data, encoding: .utf8),
                    let url = URL(string: text)
                else {
                    throw TransferableError.importNotSupported(
                        contentType: UTType.url.identifier
                    )
                }
                return url
            }
        )
    }
}

extension AttributedString: Transferable {
    public typealias Representation = DataRepresentation<AttributedString>

    public static var transferRepresentation: DataRepresentation<AttributedString> {
        DataRepresentation(
            contentType: .utf8PlainText,
            exporting: { item in
                Data(String(item.characters).utf8)
            },
            importing: { data in
                guard let text = String(data: data, encoding: .utf8) else {
                    throw TransferableError.importNotSupported(
                        contentType: UTType.utf8PlainText.identifier
                    )
                }
                return AttributedString(text)
            }
        )
    }
}
