@_spi(PDFKitTesting) import PDFKit
import Foundation

final class PDFViewDelegateSpy: NSObject, PDFViewDelegate {
    var findCount = 0
    var goToPageCount = 0
    var openRemote = 0
    var clicked: URL?
    func pdfViewPerformFind(_ sender: PDFView) {
        _ = sender
        findCount += 1
    }
    func pdfViewPerformGo(toPage sender: PDFView) {
        _ = sender
        goToPageCount += 1
    }
    func pdfViewOpenPDF(_ sender: PDFView, forRemoteGoToAction action: PDFActionRemoteGoTo) {
        _ = sender
        _ = action
        openRemote += 1
    }
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        _ = sender
        clicked = url
    }
}

func testPDFViewAndThumbnailValueSemantics() {
    MainActor.assumeIsolated {
        let empty = PDFDocument()
        let page = PDFPage()
        page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
        empty.insert(page, at: 0)
        let annotation = PDFAnnotation(
            bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
            forType: .link,
            withProperties: nil
        )
        page.addAnnotation(annotation)

        let annotatedView = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        annotatedView.document = empty
        pdfkitExpect(annotatedView.currentPage === page, "in-memory current page")
        pdfkitExpect(
            annotatedView.areaOfInterest(for: CGPoint(x: 12, y: 12)).contains(.annotationArea),
            "annotation area"
        )
        pdfkitExpect(annotatedView.areaOfInterest(forMouse: nil).contains(.pageArea), "mouse area")

        let sample = PDFDocument(data: pdfkitValidHelloPDF())
        let view = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let spy = PDFViewDelegateSpy()
        view.delegate = spy
        view.document = sample
        pdfkitExpect(view.currentPage != nil, "current page after assign")
        pdfkitExpect(view.canGoToNextPage == false, "single page cannot go next")
        pdfkitExpect(view.canGoToLastPage == false, "already last")
        pdfkitExpect(view.canGoToFirstPage == false, "already first")
        pdfkitExpect(view.canGoToPreviousPage == false, "no previous")
        pdfkitExpect(view.canZoomIn, "can zoom in")
        pdfkitExpect(view.canZoomOut, "default scale 1 is above minScaleFactor")
        view.zoomIn(nil)
        pdfkitExpect(view.scaleFactor > 1, "zoom in changes scale")
        pdfkitExpect(view.canZoomOut, "can zoom out after zoom in")
        view.zoomOut(nil)
        view.goToFirstPage(nil)
        view.perform(PDFActionNamed(name: .nextPage))
        view.perform(PDFActionNamed(name: .previousPage))
        view.perform(PDFActionNamed(name: .firstPage))
        view.perform(PDFActionNamed(name: .lastPage))
        view.perform(PDFActionNamed(name: .goBack))
        view.perform(PDFActionNamed(name: .goForward))
        view.perform(PDFActionNamed(name: .zoomIn))
        view.perform(PDFActionNamed(name: .zoomOut))
        view.perform(PDFActionNamed(name: .find))
        pdfkitExpect(spy.findCount == 1, "find delegate")
        view.perform(PDFActionNamed(name: .print))
        view.perform(PDFActionNamed(name: .goToPage))
        view.perform(PDFActionNamed(name: .none))
        if let current = view.currentPage {
            view.perform(PDFActionGoTo(destination: PDFDestination(page: current, at: .zero)))
        }
        view.perform(PDFActionURL(url: URL(string: "https://example.com")!))
        pdfkitExpect(spy.clicked?.host == "example.com", "url delegate")
        view.perform(
            PDFActionRemoteGoTo(pageIndex: 0, at: .zero, fileURL: URL(fileURLWithPath: "/tmp/x.pdf"))
        )
        pdfkitExpect(spy.openRemote == 1, "remote delegate")
        view.selectAll(nil)
        pdfkitExpect(view.currentSelection?.string?.contains("Hello") == true, "select all")
        view.setCurrentSelection(view.currentSelection, animate: false)
        view.scrollSelectionToVisible(nil)
        view.copy(nil)
        view.clearSelection()
        pdfkitExpect(view.currentSelection == nil, "clear selection")
        let converted = view.convert(CGPoint(x: 10, y: 20), from: view.currentPage!)
        pdfkitExpect(converted.x > 0, "convert from page")
        let back = view.convert(converted, to: view.currentPage!)
        pdfkitExpect(abs(back.x - 10) < 0.01, "convert to page")
        let convertedRect = view.convert(CGRect(x: 0, y: 0, width: 10, height: 10), from: view.currentPage!)
        pdfkitExpect(convertedRect.width > 0, "convert rect from")
        let backRect = view.convert(convertedRect, to: view.currentPage!)
        pdfkitExpect(backRect.width > 0, "convert rect to")
        pdfkitExpect(view.visiblePages.count == 1, "visible pages")
        pdfkitExpect(view.rowSize(for: view.currentPage!).width > 0, "row size")
        view.usePageViewController(true, withViewOptions: nil)
        pdfkitExpect(view.isUsingPageViewController, "page view controller flag")
        view.displayMode = .singlePageContinuous
        pdfkitExpect(view.visiblePages.count == 1, "continuous visible")
        view.displayMode = .twoUp
        view.displayMode = .twoUpContinuous
        view.displayBox = .mediaBox
        view.displayDirection = .horizontal
        view.displaysAsBook = true
        view.displaysPageBreaks = false
        view.displaysRTL = true
        view.enableDataDetectors = true
        view.interpolationQuality = .low
        view.pageShadowsEnabled = false
        view.isInMarkupMode = true
        view.isFindInteractionEnabled = true
        view.minScaleFactor = 0.5
        view.maxScaleFactor = 3
        view.highlightedSelections = view.currentSelection.map { [$0] }
        _ = view.currentDestination
        _ = view.canGoBack
        _ = view.canGoForward
        _ = view.pageBreakMargins
        view.pageBreakMargins = PDFKitEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        _ = view.backgroundColor
        view.backgroundColor = .white
        _ = view.documentView
        _ = view.findInteraction
        view.annotationsChanged(on: view.currentPage!)
        view.layoutDocumentView()
        view.autoScales = true
        pdfkitExpect(view.scaleFactorForSizeToFit > 0, "size to fit")
        view.goToLastPage(nil)
        view.goToNextPage(nil)
        view.goToPreviousPage(nil)
        view.goBack(nil)
        view.goForward(nil)
        if let current = view.currentPage {
            view.go(to: current)
            if let dest = view.currentDestination { view.go(to: dest) }
            if let selection = view.document?.selectionForEntireDocument {
                view.go(to: selection)
            }
            view.go(to: CGRect(x: 0, y: 0, width: 10, height: 10), on: current)
            _ = view.page(for: .zero, nearest: true)
            _ = view.page(for: CGPoint(x: 10_000, y: 10_000), nearest: false)
        }

        let thumbs = PDFThumbnailView(frame: .zero)
        thumbs.pdfView = view
        thumbs.layoutMode = .vertical
        thumbs.thumbnailSize = CGSize(width: 40, height: 50)
        thumbs.contentInset = PDFKitEdgeInsets.zero
        thumbs.backgroundColor = .white
        pdfkitExpect(thumbs.selectedPages?.count == 1, "thumbnail selection")
        thumbs.layoutMode = .horizontal
        pdfkitExpect(thumbs.layoutMode == .horizontal, "thumb layout")
        pdfkitExpect(thumbs.thumbnailSize.height == 50, "thumb size")

        spy.pdfViewPerformGo(toPage: view)
        pdfkitExpect(spy.goToPageCount == 1, "go to page delegate")
    }
}
