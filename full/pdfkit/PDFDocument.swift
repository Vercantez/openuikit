import Foundation

public protocol PDFDocumentDelegate: NSObjectProtocol {
    func `class`(forAnnotationType annotationType: String) -> AnyClass
    func classForPage() -> AnyClass
    func didMatchString(_ instance: PDFSelection)
    func documentDidBeginDocumentFind(_ notification: Notification)
    func documentDidBeginPageFind(_ notification: Notification)
    func documentDidEndDocumentFind(_ notification: Notification)
    func documentDidEndPageFind(_ notification: Notification)
    func documentDidFindMatch(_ notification: Notification)
    func documentDidUnlock(_ notification: Notification)
}

public extension PDFDocumentDelegate {
    func `class`(forAnnotationType annotationType: String) -> AnyClass {
        _ = annotationType
        return PDFAnnotation.self
    }

    func classForPage() -> AnyClass { PDFPage.self }
    func didMatchString(_ instance: PDFSelection) { _ = instance }
    func documentDidBeginDocumentFind(_ notification: Notification) { _ = notification }
    func documentDidBeginPageFind(_ notification: Notification) { _ = notification }
    func documentDidEndDocumentFind(_ notification: Notification) { _ = notification }
    func documentDidEndPageFind(_ notification: Notification) { _ = notification }
    func documentDidFindMatch(_ notification: Notification) { _ = notification }
    func documentDidUnlock(_ notification: Notification) { _ = notification }
}

open class PDFDocument: NSObject {
    public weak var delegate: (any PDFDocumentDelegate)?
    public private(set) var documentURL: URL?
    open var documentAttributes: [AnyHashable: Any]?
    open var outlineRoot: PDFOutline? {
        didSet { outlineRoot?.attach(document: self, parent: nil) }
    }

    public private(set) var majorVersion: Int = 1
    public private(set) var minorVersion: Int = 4
    public private(set) var isEncrypted = false
    public private(set) var isLocked = false
    public private(set) var isFinding = false
    public private(set) var permissionsStatus: PDFDocumentPermissions = .owner
    public private(set) var accessPermissions: PDFAccessPermissions = [
        .allowsLowQualityPrinting, .allowsHighQualityPrinting, .allowsDocumentChanges,
        .allowsDocumentAssembly, .allowsContentCopying, .allowsContentAccessibility,
        .allowsCommenting, .allowsFormFieldEntry
    ]

    open var allowsCommenting: Bool { accessPermissions.contains(.allowsCommenting) }
    open var allowsContentAccessibility: Bool { accessPermissions.contains(.allowsContentAccessibility) }
    open var allowsCopying: Bool { accessPermissions.contains(.allowsContentCopying) }
    open var allowsDocumentAssembly: Bool { accessPermissions.contains(.allowsDocumentAssembly) }
    open var allowsDocumentChanges: Bool { accessPermissions.contains(.allowsDocumentChanges) }
    open var allowsFormFieldEntry: Bool { accessPermissions.contains(.allowsFormFieldEntry) }
    open var allowsPrinting: Bool {
        accessPermissions.contains(.allowsLowQualityPrinting)
            || accessPermissions.contains(.allowsHighQualityPrinting)
    }

    #if canImport(CoreGraphics)
    open var documentRef: CGPDFDocument? { nil }
    #endif
    open var pageClass: AnyClass { delegate?.classForPage() ?? PDFPage.self }

    var pages: [PDFPage] = []
    var originalData: Data?
    var mutated = false
    var encryptInfo: PDFKitCrypto.EncryptInfo?

    public override init() {
        super.init()
        documentAttributes = [
            PDFDocumentAttribute.producerAttribute: "OpenUIKit PDFKit"
        ]
    }

    public init?(data: Data) {
        super.init()
        guard ingest(data) else { return nil }
    }

    public init?(url: URL) {
        super.init()
        documentURL = url
        guard let data = try? Data(contentsOf: url), ingest(data) else { return nil }
    }

    public convenience init?(URL url: URL) {
        self.init(url: url)
    }

    open var pageCount: Int { pages.count }

    open var string: String? {
        let combined = pages.compactMap(\.string).filter { !$0.isEmpty }.joined(separator: "\n")
        return combined.isEmpty ? nil : combined
    }

    open func page(at index: Int) -> PDFPage? {
        guard pages.indices.contains(index) else { return nil }
        return pages[index]
    }

    open func index(for page: PDFPage) -> Int {
        pages.firstIndex(where: { $0 === page }) ?? NSNotFound
    }

    open func insert(_ page: PDFPage, at index: Int) {
        let clamped = min(max(0, index), pages.count)
        page.document = self
        pages.insert(page, at: clamped)
        relabelPages()
        mutated = true
    }

    open func removePage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        pages[index].document = nil
        pages.remove(at: index)
        relabelPages()
        mutated = true
    }

    open func exchangePage(at indexA: Int, withPageAt indexB: Int) {
        guard pages.indices.contains(indexA), pages.indices.contains(indexB) else { return }
        pages.swapAt(indexA, indexB)
        relabelPages()
        mutated = true
    }

    open func unlock(withPassword password: String) -> Bool {
        guard isLocked, let originalData else { return false }
        guard let parsed = PDFKitIO.parse(originalData, password: password), !parsed.pages.isEmpty else {
            return false
        }
        applyParsed(parsed, data: originalData)
        isLocked = false
        NotificationCenter.default.post(name: .PDFDocumentDidUnlock, object: self)
        delegate?.documentDidUnlock(Notification(name: .PDFDocumentDidUnlock, object: self))
        return true
    }

    open func dataRepresentation() -> Data? {
        dataRepresentation(options: [:])
    }

    open func dataRepresentation(options: [AnyHashable: Any] = [:]) -> Data? {
        if isLocked { return nil }
        if writeOptionsAreUnsupported(options) { return nil }
        if !mutated, let originalData { return originalData }
        return PDFKitIO.write(pages: pages, attributes: documentAttributes, version: (majorVersion, minorVersion))
    }

    open func write(toFile path: String) -> Bool {
        write(toFile: path, withOptions: nil)
    }

    open func write(toFile path: String, withOptions options: [PDFDocumentWriteOption: Any]? = nil) -> Bool {
        write(to: URL(fileURLWithPath: path), withOptions: options)
    }

    open func write(to url: URL) -> Bool {
        write(to: url, withOptions: nil)
    }

    open func write(to url: URL, withOptions options: [PDFDocumentWriteOption: Any]? = nil) -> Bool {
        NotificationCenter.default.post(name: .PDFDocumentDidBeginWrite, object: self)
        defer { NotificationCenter.default.post(name: .PDFDocumentDidEndWrite, object: self) }
        let mapped = options.map { dictionary in
            Dictionary(uniqueKeysWithValues: dictionary.map { ($0.key as AnyHashable, $0.value) })
        } ?? [:]
        guard let data = dataRepresentation(options: mapped) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    open func findString(
        _ string: String,
        withOptions options: NSString.CompareOptions = []
    ) -> [PDFSelection] {
        guard !string.isEmpty, !isLocked else { return [] }
        var matches: [PDFSelection] = []
        for page in pages {
            matches.append(contentsOf: page.matches(of: string, options: options))
        }
        return matches
    }

    open func findString(
        _ string: String,
        fromSelection selection: PDFSelection?,
        withOptions options: NSString.CompareOptions = []
    ) -> PDFSelection? {
        let all = findString(string, withOptions: options)
        guard let selection else { return all.first }
        return all.first { $0.isAfter(selection, in: self) }
    }

    open func beginFindString(_ string: String, withOptions options: NSString.CompareOptions = []) {
        beginFindStrings([string], withOptions: options)
    }

    open func beginFindStrings(_ strings: [String], withOptions options: NSString.CompareOptions = []) {
        isFinding = true
        NotificationCenter.default.post(name: .PDFDocumentDidBeginFind, object: self)
        delegate?.documentDidBeginDocumentFind(Notification(name: .PDFDocumentDidBeginFind, object: self))
        for page in pages {
            NotificationCenter.default.post(
                name: .PDFDocumentDidBeginPageFind,
                object: self,
                userInfo: [PDFDocumentPageIndexKey: index(for: page)]
            )
            for string in strings {
                for match in page.matches(of: string, options: options) {
                    NotificationCenter.default.post(
                        name: .PDFDocumentDidFindMatch,
                        object: self,
                        userInfo: [PDFDocumentFoundSelectionKey: match]
                    )
                    delegate?.didMatchString(match)
                    delegate?.documentDidFindMatch(
                        Notification(
                            name: .PDFDocumentDidFindMatch,
                            object: self,
                            userInfo: [PDFDocumentFoundSelectionKey: match]
                        )
                    )
                }
            }
            NotificationCenter.default.post(
                name: .PDFDocumentDidEndPageFind,
                object: self,
                userInfo: [PDFDocumentPageIndexKey: index(for: page)]
            )
        }
        isFinding = false
        NotificationCenter.default.post(name: .PDFDocumentDidEndFind, object: self)
        delegate?.documentDidEndDocumentFind(Notification(name: .PDFDocumentDidEndFind, object: self))
    }

    open func cancelFindString() {
        isFinding = false
    }

    open func outlineItem(for selection: PDFSelection) -> PDFOutline? {
        guard let page = selection.pages.first else { return nil }
        return outlineRoot?.firstItem(matchingPage: page)
    }

    open func selection(
        from startPage: PDFPage,
        atCharacterIndex startCharacter: Int,
        to endPage: PDFPage,
        atCharacterIndex endCharacter: Int
    ) -> PDFSelection? {
        let selection = PDFSelection(document: self)
        if startPage === endPage {
            let range = NSRange(
                location: min(startCharacter, endCharacter),
                length: abs(endCharacter - startCharacter)
            )
            if let piece = startPage.selection(for: range) {
                selection.add(piece)
            }
        } else {
            selection.addText(startPage.string ?? "", page: startPage)
            selection.addText(endPage.string ?? "", page: endPage)
        }
        return selection
    }

    open func selection(
        from startPage: PDFPage,
        at startPoint: CGPoint,
        to endPage: PDFPage,
        at endPoint: CGPoint
    ) -> PDFSelection? {
        selection(from: startPage, at: startPoint, to: endPage, at: endPoint, with: .character)
    }

    open func selection(
        from startPage: PDFPage,
        at startPoint: CGPoint,
        to endPage: PDFPage,
        at endPoint: CGPoint,
        with granularity: PDFSelectionGranularity
    ) -> PDFSelection? {
        _ = (startPoint, endPoint, granularity)
        if startPage === endPage {
            return startPage.selectionForWord(at: startPoint) ?? startPage.selection(from: startPoint, to: endPoint)
        }
        let selection = PDFSelection(document: self)
        selection.addText(startPage.string ?? "", page: startPage)
        selection.addText(endPage.string ?? "", page: endPage)
        return selection
    }

    open var selectionForEntireDocument: PDFSelection? {
        let selection = PDFSelection(document: self)
        for page in pages {
            if let text = page.string { selection.addText(text, page: page) }
        }
        return selection
    }

    private func ingest(_ data: Data) -> Bool {
        guard let parsed = PDFKitIO.parse(data) else { return false }
        applyParsed(parsed, data: data)
        return true
    }

    private func applyParsed(_ parsed: PDFKitParsedDocument, data: Data) {
        originalData = data
        mutated = false
        majorVersion = parsed.majorVersion
        minorVersion = parsed.minorVersion
        isEncrypted = parsed.encrypted
        isLocked = parsed.encrypted && parsed.pages.isEmpty
        encryptInfo = parsed.encryptInfo
        permissionsStatus = parsed.permissionsStatus
        accessPermissions = parsed.accessPermissions
        if parsed.pages.isEmpty && parsed.encrypted {
            pages = []
            documentAttributes = parsed.attributes
            return
        }
        documentAttributes = parsed.attributes
        pages = parsed.pages.map { description in
            let page = makePage()
            page.document = self
            page.apply(description)
            return page
        }
        relabelPages()
        if !parsed.outlines.isEmpty {
            let root = PDFOutline()
            root.label = ""
            for item in parsed.outlines {
                root.insertChild(makeOutline(item), at: root.numberOfChildren)
            }
            outlineRoot = root
        }
    }

    private func makePage() -> PDFPage {
        if let type = pageClass as? PDFPage.Type {
            return type.init()
        }
        return PDFPage()
    }

    private func makeOutline(_ parsed: PDFKitParsedOutline) -> PDFOutline {
        let outline = PDFOutline()
        outline.label = parsed.title
        if let pageIndex = parsed.pageIndex, let page = page(at: pageIndex) {
            outline.destination = PDFDestination(page: page, at: CGPoint(x: 0, y: kPDFDestinationUnspecifiedValue))
        }
        for child in parsed.children {
            outline.insertChild(makeOutline(child), at: outline.numberOfChildren)
        }
        return outline
    }

    private func relabelPages() {
        for (index, page) in pages.enumerated() {
            page.label = "\(index + 1)"
            page.document = self
        }
    }

    private func writeOptionsAreUnsupported(_ options: [AnyHashable: Any]) -> Bool {
        let blocked: Set<String> = [
            PDFDocumentWriteOption.ownerPasswordOption.rawValue,
            PDFDocumentWriteOption.userPasswordOption.rawValue,
            PDFDocumentWriteOption.burnInAnnotationsOption.rawValue,
            PDFDocumentWriteOption.saveTextFromOCROption.rawValue
        ]
        for key in options.keys {
            if let option = key as? PDFDocumentWriteOption, blocked.contains(option.rawValue) {
                return true
            }
            if let string = key as? String, blocked.contains(string) {
                return true
            }
        }
        return false
    }
}

open class PDFPage: NSObject {
    public struct ImageInitializationOption: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let mediaBox = ImageInitializationOption(rawValue: "PDFPageImageInitializationOptionMediaBox")
        public static let rotation = ImageInitializationOption(rawValue: "PDFPageImageInitializationOptionRotation")
        public static let upscaleIfSmaller = ImageInitializationOption(rawValue: "PDFPageImageInitializationOptionUpscaleIfSmaller")
        public static let compressionQuality = ImageInitializationOption(rawValue: "PDFPageImageInitializationOptionCompressionQuality")
    }

    public weak var document: PDFDocument?
    open var displaysAnnotations = true
    open var rotation: Int = 0
    public internal(set) var label: String?
    public private(set) var annotations: [PDFAnnotation] = []
    var storedString: String?
    var boxes: [PDFDisplayBox: CGRect] = [
        .mediaBox: CGRect(x: 0, y: 0, width: 612, height: 792)
    ]
    var contentData: Data?
    var resourceKeyCount = 0
    var characters: [PDFKitParsedCharacter] = []

    public required override init() {
        super.init()
    }

    public convenience init?(image: PDFKitImage) {
        self.init(image: image, options: [:])
    }

    public init?(image: PDFKitImage, options: [PDFPage.ImageInitializationOption: Any] = [:]) {
        super.init()
        let media: CGRect
        if let rect = options[.mediaBox] as? CGRect {
            media = rect
        } else {
            let size = image.size == .zero ? CGSize(width: 612, height: 792) : image.size
            media = CGRect(origin: .zero, size: size)
        }
        boxes[.mediaBox] = media
        if let value = options[.rotation] as? Int {
            rotation = value
        }
        storedString = nil
    }

    open func thumbnail(of size: CGSize, for box: PDFDisplayBox) -> PDFKitImage {
        #if canImport(UIKit)
        let thumbSize = CGSize(width: max(1, size.width), height: max(1, size.height))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: thumbSize, format: format)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            let bounds = bounds(for: box)
            let scale = min(
                thumbSize.width / max(bounds.size.width, 1),
                thumbSize.height / max(bounds.size.height, 1)
            )
            context.translateBy(x: 0, y: thumbSize.height)
            context.scaleBy(x: scale, y: -scale)
            draw(with: box, to: context)
        }
        #else
        _ = box
        return PDFKitImage(size: CGSize(width: max(1, size.width), height: max(1, size.height)))
        #endif
    }

    #if canImport(CoreGraphics)
    open var pageRef: CGPDFPage? { nil }

    open func draw(with box: PDFDisplayBox, to context: CGContext) {
        PDFKitRenderer.draw(page: self, box: box, in: context)
    }

    open func transform(_ context: CGContext, for box: PDFDisplayBox) {
        context.concatenate(transform(for: box))
    }

    open func transform(for box: PDFDisplayBox) -> CGAffineTransform {
        PDFKitRenderer.transform(page: self, box: box)
    }
    #endif

    open var string: String? { storedString }

    open var attributedString: NSAttributedString? {
        storedString.map { NSAttributedString(string: $0) }
    }

    open var numberOfCharacters: Int { storedString?.count ?? 0 }

    open var dataRepresentation: Data? {
        PDFKitIO.write(pages: [self], attributes: nil, version: (1, 4))
    }

    open func bounds(for box: PDFDisplayBox) -> CGRect {
        boxes[box] ?? boxes[.mediaBox] ?? .zero
    }

    open func setBounds(_ bounds: CGRect, for box: PDFDisplayBox) {
        boxes[box] = bounds
        document?.mutated = true
    }

    open func addAnnotation(_ annotation: PDFAnnotation) {
        annotation.page = self
        annotations.append(annotation)
        document?.mutated = true
    }

    open func removeAnnotation(_ annotation: PDFAnnotation) {
        annotations.removeAll { $0 === annotation }
        if annotation.page === self { annotation.page = nil }
        document?.mutated = true
    }

    open func annotation(at point: CGPoint) -> PDFAnnotation? {
        annotations.last { $0.bounds.contains(point) }
    }

    open func characterBounds(at index: Int) -> CGRect {
        guard characters.indices.contains(index) else { return .zero }
        return characters[index].bounds
    }

    open func characterIndex(at point: CGPoint) -> Int {
        if let index = characters.firstIndex(where: { $0.bounds.contains(point) }) {
            return index
        }
        return NSNotFound
    }

    open func selection(for range: NSRange) -> PDFSelection? {
        guard let storedString, let swiftRange = Range(range, in: storedString) else { return nil }
        guard let document else { return nil }
        let selection = PDFSelection(document: document)
        selection.addText(String(storedString[swiftRange]), page: self, range: range)
        return selection
    }

    open func selection(for rect: CGRect) -> PDFSelection? {
        _ = rect
        guard let storedString, let document else { return nil }
        let selection = PDFSelection(document: document)
        selection.addText(storedString, page: self)
        return selection
    }

    open func selection(from startPoint: CGPoint, to endPoint: CGPoint) -> PDFSelection? {
        selection(for: CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        ))
    }

    open func selectionForLine(at point: CGPoint) -> PDFSelection? {
        _ = point
        return selection(for: NSRange(location: 0, length: storedString?.count ?? 0))
    }

    open func selectionForWord(at point: CGPoint) -> PDFSelection? {
        _ = point
        guard let storedString, let document else { return nil }
        let word = storedString.split { $0.isWhitespace }.first.map(String.init) ?? storedString
        let selection = PDFSelection(document: document)
        selection.addText(word, page: self)
        return selection
    }

    func apply(_ parsed: PDFKitParsedPage) {
        boxes[.mediaBox] = parsed.mediaBox
        if let crop = parsed.cropBox { boxes[.cropBox] = crop }
        if let bleed = parsed.bleedBox { boxes[.bleedBox] = bleed }
        if let trim = parsed.trimBox { boxes[.trimBox] = trim }
        if let art = parsed.artBox { boxes[.artBox] = art }
        rotation = parsed.rotation
        storedString = parsed.text.isEmpty ? nil : parsed.text
        contentData = parsed.contents
        resourceKeyCount = parsed.resourceKeyCount
        characters = parsed.characters
        for parsedAnnotation in parsed.annotations {
            let annotation = makeAnnotation(parsedAnnotation)
            annotation.page = self
            annotations.append(annotation)
        }
    }

    private func makeAnnotation(_ parsed: PDFKitParsedAnnotation) -> PDFAnnotation {
        let subtype = PDFAnnotationSubtype(rawValue: parsed.subtype.hasPrefix("/") ? parsed.subtype : "/\(parsed.subtype)")
        let annotation = PDFAnnotation(bounds: parsed.bounds, forType: subtype, withProperties: nil)
        annotation.contents = parsed.contents
        annotation.fieldName = parsed.fieldName
        annotation.widgetStringValue = parsed.fieldValue
        if let uri = parsed.uri { annotation.url = URL(string: uri) }
        if !parsed.quadPoints.isEmpty {
            #if canImport(UIKit)
            annotation.quadrilateralPoints = parsed.quadPoints.map { NSValue(cgPoint: $0) }
            #endif
        }
        #if canImport(UIKit)
        if parsed.colorComponents.count >= 3 {
            annotation.color = UIColor(
                red: parsed.colorComponents[0],
                green: parsed.colorComponents[1],
                blue: parsed.colorComponents[2],
                alpha: parsed.colorComponents.count > 3 ? parsed.colorComponents[3] : 1
            )
        }
        #endif
        if let pageIndex = parsed.destinationPageIndex, let page = document?.page(at: pageIndex) {
            annotation.destination = PDFDestination(page: page, at: .zero)
        }
        return annotation
    }

    func matches(of string: String, options: NSString.CompareOptions) -> [PDFSelection] {
        guard let storedString, let document, !string.isEmpty else { return [] }
        var matches: [PDFSelection] = []
        var searchRange = storedString.startIndex..<storedString.endIndex
        while let found = storedString.range(of: string, options: String.CompareOptions(rawValue: options.rawValue), range: searchRange) {
            let nsRange = NSRange(found, in: storedString)
            let selection = PDFSelection(document: document)
            selection.addText(String(storedString[found]), page: self, range: nsRange)
            matches.append(selection)
            searchRange = found.upperBound..<storedString.endIndex
            if found.upperBound == storedString.endIndex { break }
        }
        return matches
    }
}

open class PDFOutline: NSObject {
    public private(set) weak var document: PDFDocument?
    public private(set) weak var parent: PDFOutline?
    open var label: String?
    open var isOpen = true
    open var action: PDFAction?
    open var destination: PDFDestination?
    private var children: [PDFOutline] = []

    public override init() {
        super.init()
    }

    open var numberOfChildren: Int { children.count }

    open var index: Int {
        parent?.children.firstIndex(where: { $0 === self }) ?? 0
    }

    open func child(at index: Int) -> PDFOutline? {
        guard children.indices.contains(index) else { return nil }
        return children[index]
    }

    open func insertChild(_ child: PDFOutline, at index: Int) {
        child.parent?.remove(child)
        child.parent = self
        child.document = document
        let clamped = min(max(0, index), children.count)
        children.insert(child, at: clamped)
    }

    open func removeFromParent() {
        parent?.remove(self)
    }

    func attach(document: PDFDocument, parent: PDFOutline?) {
        self.document = document
        self.parent = parent
        for child in children {
            child.attach(document: document, parent: self)
        }
    }

    func firstItem(matchingPage page: PDFPage) -> PDFOutline? {
        if destination?.page === page { return self }
        for child in children {
            if let found = child.firstItem(matchingPage: page) { return found }
        }
        return nil
    }

    private func remove(_ child: PDFOutline) {
        children.removeAll { $0 === child }
        if child.parent === self { child.parent = nil }
    }
}

open class PDFSelection: NSObject {
    public private(set) weak var owningDocument: PDFDocument?
    public private(set) var pages: [PDFPage] = []
    open var color: PDFKitColor?
    private var pieces: [(page: PDFPage, text: String, range: NSRange?)] = []

    public init(document: PDFDocument) {
        owningDocument = document
        super.init()
    }

    open var string: String? {
        let combined = pieces.map(\.text).joined(separator: " ")
        return combined.isEmpty ? nil : combined
    }

    open var attributedString: NSAttributedString? {
        string.map { NSAttributedString(string: $0) }
    }

    open func add(_ selection: PDFSelection) {
        for piece in selection.pieces {
            addText(piece.text, page: piece.page, range: piece.range)
        }
    }

    open func add(_ selections: [PDFSelection]) {
        for selection in selections { add(selection) }
    }

    open func bounds(for page: PDFPage) -> CGRect {
        pieces.contains(where: { $0.page === page }) ? page.bounds(for: .mediaBox) : .zero
    }

    open func draw(for page: PDFPage, active: Bool) {
        _ = (page, active)
    }

    open func draw(for page: PDFPage, with box: PDFDisplayBox, active: Bool) {
        _ = (page, box, active)
    }

    open func extend(atEnd succeed: Int) {
        guard succeed > 0, let last = pieces.last, let stored = last.page.string else { return }
        let extra = String(stored.prefix(succeed))
        addText(extra, page: last.page)
    }

    open func extend(atStart precede: Int) {
        guard precede > 0, let first = pieces.first, let stored = first.page.string else { return }
        let extra = String(stored.prefix(precede))
        pieces.insert((first.page, extra, nil), at: 0)
        if !pages.contains(where: { $0 === first.page }) {
            pages.insert(first.page, at: 0)
        }
    }

    open func extendForLineBoundaries() {}

    open func numberOfTextRanges(on page: PDFPage) -> Int {
        pieces.filter { $0.page === page }.count
    }

    open func range(at index: Int, on page: PDFPage) -> NSRange {
        let filtered = pieces.filter { $0.page === page }
        guard filtered.indices.contains(index) else { return NSRange(location: 0, length: 0) }
        return filtered[index].range ?? NSRange(location: 0, length: filtered[index].text.count)
    }

    open func selectionsByLine() -> [PDFSelection] {
        guard let owningDocument else { return [self] }
        var lines: [PDFSelection] = []
        for piece in pieces {
            for line in piece.text.split(whereSeparator: \.isNewline) {
                let selection = PDFSelection(document: owningDocument)
                selection.addText(String(line), page: piece.page)
                lines.append(selection)
            }
        }
        return lines.isEmpty ? [self] : lines
    }

    func addText(_ text: String, page: PDFPage, range: NSRange? = nil) {
        pieces.append((page, text, range))
        if !pages.contains(where: { $0 === page }) {
            pages.append(page)
        }
    }

    func isAfter(_ other: PDFSelection, in document: PDFDocument) -> Bool {
        let selfPage = pages.first.flatMap { document.index(for: $0) } ?? Int.max
        let otherPage = other.pages.first.flatMap { document.index(for: $0) } ?? -1
        if selfPage != otherPage { return selfPage > otherPage }
        let selfLocation = pieces.first?.range?.location ?? 0
        let otherRange = other.pieces.first?.range ?? NSRange(location: 0, length: 0)
        return selfLocation >= otherRange.location + otherRange.length
    }
}
