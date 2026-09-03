import Foundation

#if canImport(UIKit)
public protocol PDFPageOverlayViewProvider: NSObjectProtocol {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView?
    func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage)
    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage)
}

public extension PDFPageOverlayViewProvider {
    func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
        _ = (pdfView, overlayView, page)
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        _ = (pdfView, overlayView, page)
    }
}
#endif

public protocol PDFViewDelegate: NSObjectProtocol {
    func pdfViewOpenPDF(_ sender: PDFView, forRemoteGoToAction action: PDFActionRemoteGoTo)
    #if canImport(UIKit)
    func pdfViewParentViewController() -> UIViewController
    #endif
    func pdfViewPerformFind(_ sender: PDFView)
    func pdfViewPerformGo(toPage sender: PDFView)
    func pdfViewWillClick(onLink sender: PDFView, with url: URL)
}

public extension PDFViewDelegate {
    func pdfViewOpenPDF(_ sender: PDFView, forRemoteGoToAction action: PDFActionRemoteGoTo) {
        _ = (sender, action)
    }

    #if canImport(UIKit)
    func pdfViewParentViewController() -> UIViewController {
        UIViewController()
    }
    #endif

    func pdfViewPerformFind(_ sender: PDFView) { _ = sender }
    func pdfViewPerformGo(toPage sender: PDFView) { _ = sender }
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) { _ = (sender, url) }
}

#if canImport(UIKit)
private final class PDFKitFindSessionDelegate: NSObject, UIFindInteractionDelegate {
    func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? {
        _ = (interaction, view)
        return nil
    }
}
#endif

#if canImport(UIKit)
public typealias PDFKitViewBase = UIView
#else
open class PDFKitViewBase: NSObject {
    open var frame: CGRect = .zero
    open var bounds: CGRect = .zero
    open var isHidden = false

    public override init() {
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }
}
#endif

@MainActor
open class PDFView: PDFKitViewBase {
    public weak var delegate: (any PDFViewDelegate)?
    #if canImport(UIKit)
    public weak var pageOverlayViewProvider: (any PDFPageOverlayViewProvider)?
    #endif

    private var _document: PDFDocument?
    private var _currentIndex = 0
    private var history: [Int] = []
    private var historyIndex = -1
    private var _scaleFactor: CGFloat = 1
    private var breakTop: CGFloat = 4
    private var breakLeft: CGFloat = 4
    private var breakBottom: CGFloat = 4
    private var breakRight: CGFloat = 4

    #if canImport(UIKit)
    private let findSessionDelegate = PDFKitFindSessionDelegate()
    private lazy var hostedFindInteraction = UIFindInteraction(sessionDelegate: findSessionDelegate)
    private let hostedDocumentView = UIView()
    #endif

    open var document: PDFDocument? {
        get { _document }
        set {
            _document = newValue
            _currentIndex = 0
            history = newValue == nil ? [] : [0]
            historyIndex = newValue == nil ? -1 : 0
            NotificationCenter.default.post(name: .PDFViewDocumentChanged, object: self)
            NotificationCenter.default.post(name: .PDFViewPageChanged, object: self)
            NotificationCenter.default.post(name: .PDFViewVisiblePagesChanged, object: self)
        }
    }

    open var displayBox: PDFDisplayBox = .cropBox {
        didSet { NotificationCenter.default.post(name: .PDFViewDisplayBoxChanged, object: self) }
    }
    open var displayMode: PDFDisplayMode = .singlePage {
        didSet { NotificationCenter.default.post(name: .PDFViewDisplayModeChanged, object: self) }
    }
    open var displayDirection: PDFDisplayDirection = .vertical
    open var displaysAsBook = false
    open var displaysPageBreaks = true
    open var displaysRTL = false
    open var enableDataDetectors = false
    open var interpolationQuality: PDFInterpolationQuality = .none
    open var pageShadowsEnabled = true
    open var isInMarkupMode = false
    open var isFindInteractionEnabled = false
    open var isUsingPageViewController = false
    open var autoScales = false
    open var minScaleFactor: CGFloat = 0.25
    open var maxScaleFactor: CGFloat = 4
    open var currentSelection: PDFSelection? {
        didSet { NotificationCenter.default.post(name: .PDFViewSelectionChanged, object: self) }
    }
    open var highlightedSelections: [PDFSelection]?

    #if canImport(UIKit)
    open var pageBreakMargins: UIEdgeInsets {
        get { UIEdgeInsets(top: breakTop, left: breakLeft, bottom: breakBottom, right: breakRight) }
        set {
            breakTop = newValue.top
            breakLeft = newValue.left
            breakBottom = newValue.bottom
            breakRight = newValue.right
        }
    }

    open var findInteraction: UIFindInteraction { hostedFindInteraction }
    open var documentView: UIView? { hostedDocumentView }

    open override var backgroundColor: UIColor? {
        get { pdfBackgroundColor }
        set { pdfBackgroundColor = newValue ?? UIColor(white: 0.5, alpha: 1) }
    }

    private var pdfBackgroundColor: UIColor = UIColor(white: 0.5, alpha: 1)
    #endif

    open var scaleFactor: CGFloat {
        get { _scaleFactor }
        set {
            let clamped = min(max(newValue, minScaleFactor), maxScaleFactor)
            guard clamped != _scaleFactor else { return }
            _scaleFactor = clamped
            NotificationCenter.default.post(name: .PDFViewScaleChanged, object: self)
        }
    }

    open var scaleFactorForSizeToFit: CGFloat {
        guard let page = currentPage else { return 1 }
        let box = page.bounds(for: displayBox)
        let available = bounds.size.width > 0 ? bounds.size.width : box.size.width
        guard box.size.width > 0 else { return 1 }
        return available / box.size.width
    }

    open var currentPage: PDFPage? { document?.page(at: _currentIndex) }

    open var currentDestination: PDFDestination? {
        guard let page = currentPage else { return nil }
        return PDFDestination(page: page, at: .zero)
    }

    open var visiblePages: [PDFPage] {
        switch displayMode {
        case .singlePage, .twoUp:
            if let page = currentPage { return [page] }
            return []
        case .singlePageContinuous, .twoUpContinuous:
            return document.map { doc in
                (0..<doc.pageCount).compactMap { doc.page(at: $0) }
            } ?? []
        }
    }

    open var canGoBack: Bool { historyIndex > 0 }
    open var canGoForward: Bool { historyIndex + 1 < history.count }
    open var canGoToFirstPage: Bool { _currentIndex > 0 }
    open var canGoToLastPage: Bool {
        guard let count = document?.pageCount else { return false }
        return _currentIndex + 1 < count
    }
    open var canGoToNextPage: Bool { canGoToLastPage }
    open var canGoToPreviousPage: Bool { canGoToFirstPage }
    open var canZoomIn: Bool { _scaleFactor < maxScaleFactor }
    open var canZoomOut: Bool { _scaleFactor > minScaleFactor }

    #if !canImport(UIKit)
    public override init() {
        super.init()
    }
    #endif

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    #endif

    open func go(to page: PDFPage) {
        guard let document, let index = optionalIndex(of: page, in: document) else { return }
        pushHistory(index)
    }

    open func go(to destination: PDFDestination) {
        if let page = destination.page {
            go(to: page)
        }
    }

    open func go(to selection: PDFSelection) {
        if let page = selection.pages.first {
            go(to: page)
        }
        currentSelection = selection
    }

    open func go(to rect: CGRect, on page: PDFPage) {
        _ = rect
        go(to: page)
    }

    @IBAction open func goToFirstPage(_ sender: Any?) {
        _ = sender
        guard let document, document.pageCount > 0 else { return }
        pushHistory(0)
    }

    @IBAction open func goToLastPage(_ sender: Any?) {
        _ = sender
        guard let document, document.pageCount > 0 else { return }
        pushHistory(document.pageCount - 1)
    }

    @IBAction open func goToNextPage(_ sender: Any?) {
        _ = sender
        guard canGoToNextPage else { return }
        pushHistory(_currentIndex + 1)
    }

    @IBAction open func goToPreviousPage(_ sender: Any?) {
        _ = sender
        guard canGoToPreviousPage else { return }
        pushHistory(_currentIndex - 1)
    }

    @IBAction open func goBack(_ sender: Any?) {
        _ = sender
        guard canGoBack else { return }
        historyIndex -= 1
        _currentIndex = history[historyIndex]
        NotificationCenter.default.post(name: .PDFViewChangedHistory, object: self)
        NotificationCenter.default.post(name: .PDFViewPageChanged, object: self)
    }

    @IBAction open func goForward(_ sender: Any?) {
        _ = sender
        guard canGoForward else { return }
        historyIndex += 1
        _currentIndex = history[historyIndex]
        NotificationCenter.default.post(name: .PDFViewChangedHistory, object: self)
        NotificationCenter.default.post(name: .PDFViewPageChanged, object: self)
    }

    @IBAction open func zoomIn(_ sender: Any?) {
        _ = sender
        scaleFactor *= 1.5
    }

    @IBAction open func zoomOut(_ sender: Any?) {
        _ = sender
        scaleFactor /= 1.5
    }

    open func clearSelection() {
        currentSelection = nil
    }

    @IBAction open func selectAll(_ sender: Any?) {
        currentSelection = document?.selectionForEntireDocument
    }

    @IBAction open func copy(_ sender: Any?) {
        _ = sender
        NotificationCenter.default.post(name: .PDFViewCopyPermission, object: self)
    }

    @IBAction open func scrollSelectionToVisible(_ sender: Any?) {
        _ = sender
        if let page = currentSelection?.pages.first {
            go(to: page)
        }
    }

    open func setCurrentSelection(_ selection: PDFSelection?, animate: Bool) {
        _ = animate
        currentSelection = selection
    }

    open func annotationsChanged(on page: PDFPage) {
        _ = page
        layoutDocumentView()
    }

    #if canImport(UIKit)
    open func areaOfInterest(forMouse event: UIEvent) -> PDFAreaOfInterest {
        _ = event
        return .pageArea
    }
    #endif

    open func areaOfInterest(for cursorLocation: CGPoint) -> PDFAreaOfInterest {
        if let page = currentPage, page.annotation(at: cursorLocation) != nil {
            return [.pageArea, .annotationArea]
        }
        return .pageArea
    }

    open func convert(_ point: CGPoint, from page: PDFPage) -> CGPoint {
        let frame = pageFrame(page)
        return CGPoint(x: frame.origin.x + point.x * _scaleFactor, y: frame.origin.y + point.y * _scaleFactor)
    }

    open func convert(_ point: CGPoint, to page: PDFPage) -> CGPoint {
        let frame = pageFrame(page)
        guard _scaleFactor != 0 else { return .zero }
        return CGPoint(x: (point.x - frame.origin.x) / _scaleFactor, y: (point.y - frame.origin.y) / _scaleFactor)
    }

    open func convert(_ rect: CGRect, from page: PDFPage) -> CGRect {
        let origin = convert(rect.origin, from: page)
        return CGRect(origin: origin, size: CGSize(width: rect.size.width * _scaleFactor, height: rect.size.height * _scaleFactor))
    }

    open func convert(_ rect: CGRect, to page: PDFPage) -> CGRect {
        let origin = convert(rect.origin, to: page)
        guard _scaleFactor != 0 else { return .zero }
        return CGRect(origin: origin, size: CGSize(width: rect.size.width / _scaleFactor, height: rect.size.height / _scaleFactor))
    }

    #if canImport(CoreGraphics)
    open func draw(_ page: PDFPage, to context: CGContext) {
        page.draw(with: displayBox, to: context)
    }

    open func drawPagePost(_ page: PDFPage, to context: CGContext) {
        _ = (page, context)
    }
    #endif

    open func layoutDocumentView() {
        NotificationCenter.default.post(name: .PDFViewVisiblePagesChanged, object: self)
    }

    open func page(for point: CGPoint, nearest: Bool) -> PDFPage? {
        guard let document else { return nil }
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), pageFrame(page).contains(point) {
                return page
            }
        }
        return nearest ? currentPage : nil
    }

    open func perform(_ action: PDFAction) {
        if let goTo = action as? PDFActionGoTo {
            go(to: goTo.destination)
            return
        }
        if let named = action as? PDFActionNamed {
            switch named.name {
            case .nextPage: goToNextPage(nil)
            case .previousPage: goToPreviousPage(nil)
            case .firstPage: goToFirstPage(nil)
            case .lastPage: goToLastPage(nil)
            case .goBack: goBack(nil)
            case .goForward: goForward(nil)
            case .zoomIn: zoomIn(nil)
            case .zoomOut: zoomOut(nil)
            case .find: delegate?.pdfViewPerformFind(self)
            default: break
            }
            return
        }
        if let remote = action as? PDFActionRemoteGoTo {
            delegate?.pdfViewOpenPDF(self, forRemoteGoToAction: remote)
            return
        }
        if let urlAction = action as? PDFActionURL, let url = urlAction.url {
            delegate?.pdfViewWillClick(onLink: self, with: url)
        }
    }

    open func rowSize(for page: PDFPage) -> CGSize {
        let box = page.bounds(for: displayBox)
        return CGSize(width: box.size.width * _scaleFactor, height: box.size.height * _scaleFactor)
    }

    open func usePageViewController(_ enable: Bool, withViewOptions viewOptions: [AnyHashable: Any]? = nil) {
        _ = viewOptions
        isUsingPageViewController = enable
    }

    private func pushHistory(_ index: Int) {
        if historyIndex + 1 < history.count {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(index)
        historyIndex = history.count - 1
        _currentIndex = index
        NotificationCenter.default.post(name: .PDFViewChangedHistory, object: self)
        NotificationCenter.default.post(name: .PDFViewPageChanged, object: self)
        NotificationCenter.default.post(name: .PDFViewVisiblePagesChanged, object: self)
    }

    private func optionalIndex(of page: PDFPage, in document: PDFDocument) -> Int? {
        let index = document.index(for: page)
        return index == NSNotFound ? nil : index
    }

    private func pageFrame(_ page: PDFPage) -> CGRect {
        guard let document else { return .zero }
        let index = document.index(for: page)
        let box = page.bounds(for: displayBox)
        let size = CGSize(width: box.size.width * _scaleFactor, height: box.size.height * _scaleFactor)
        if displayDirection == .vertical {
            let y = CGFloat(index) * (size.height + breakTop + breakBottom)
            return CGRect(origin: CGPoint(x: breakLeft, y: y), size: size)
        }
        let x = CGFloat(index) * (size.width + breakLeft + breakRight)
        return CGRect(origin: CGPoint(x: x, y: breakTop), size: size)
    }
}

@MainActor
open class PDFThumbnailView: PDFKitViewBase {
    public weak var pdfView: PDFView?
    open var layoutMode: PDFThumbnailLayoutMode = .vertical
    open var thumbnailSize = CGSize(width: 100, height: 130)

    #if canImport(UIKit)
    open var contentInset = UIEdgeInsets.zero
    #endif

    #if !canImport(UIKit)
    public override init() {
        super.init()
    }
    #endif

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    #endif

    open var selectedPages: [PDFPage]? {
        pdfView?.currentPage.map { [$0] }
    }
}
