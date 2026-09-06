// UIPrintInteractionController / UIPrinterPickerController — fail-closed.
// No print spooler. `isPrintingAvailable` is false; present methods return
// false and invoke the completion with completed == false.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import Foundation
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif
// Guest library route (x86 cycle c4dce839 UIPrintInteractionController.swift:44,
// URL/Data at 146–147): Foundation is hidden; both types live on
// FoundationEssentials, which OpenUIKit already sees (UIDatePicker sibling).
#if !canImport(Foundation) && canImport(FoundationEssentials)
import struct FoundationEssentials.URL
import struct FoundationEssentials.Data
#endif

public enum UIPrinterCutterBehavior: Int, Sendable {
    case noCut = 0
    case printerDefault = 1
    case cutAfterEachPage = 2
    case cutAfterEachCopy = 3
    case cutAfterEachJob = 4
}

@preconcurrency @MainActor
open class UIPrinter: NSObject {
    public struct JobTypes: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let unknown: JobTypes = []
        public static let document = JobTypes(rawValue: 1 << 0)
        public static let envelope = JobTypes(rawValue: 1 << 1)
        public static let label = JobTypes(rawValue: 1 << 2)
        public static let photo = JobTypes(rawValue: 1 << 3)
        public static let receipt = JobTypes(rawValue: 1 << 4)
        public static let roll = JobTypes(rawValue: 1 << 5)
        public static let largeFormat = JobTypes(rawValue: 1 << 6)
        public static let postcard = JobTypes(rawValue: 1 << 7)
    }

    public let url: URL
    public var displayName: String = ""
    public var displayLocation: String?
    public var makeAndModel: String?
    public var supportedJobTypes: JobTypes = .unknown
    public var supportsColor: Bool = false
    public var supportsDuplex: Bool = false

    public class func printer(with url: URL) -> UIPrinter {
        UIPrinter(url: url)
    }

    public init(url: URL) {
        self.url = url
        super.init()
    }

    public func contactPrinter(_ completionHandler: ((Bool) -> Void)?) {
        completionHandler?(false)
    }
}

@preconcurrency @MainActor
open class UIPrintInfo: NSObject {
    public enum OutputType: Int, Sendable {
        case general = 0
        case photo = 1
        case grayscale = 2
        case photoGrayscale = 3
    }
    public enum Orientation: Int, Sendable {
        case portrait = 0
        case landscape = 1
    }
    public enum Duplex: Int, Sendable {
        case none = 0
        case longEdge = 1
        case shortEdge = 2
    }

    public var printerID: String?
    public var jobName: String = ""
    public var outputType: OutputType = .general
    public var orientation: Orientation = .portrait
    public var duplex: Duplex = .none
    public var dictionaryRepresentation: [AnyHashable: Any] { [:] }

    public class func printInfo() -> UIPrintInfo { UIPrintInfo() }
    public class func printInfo(dictionary: [AnyHashable: Any]?) -> UIPrintInfo {
        UIPrintInfo(dictionary: dictionary)
    }

    /// Focus OpenUtils.swift:19 `UIPrintInfo(dictionary: nil)`. Convenience
    /// so NSObject.init() stays inherited for `printInfo()`.
    public convenience init(dictionary: [AnyHashable: Any]?) {
        self.init()
        _ = dictionary
    }
}

@preconcurrency @MainActor
open class UIPrintPaper: NSObject {
    public var paperSize: CGSize = .zero
    public var printableRect: CGRect = .zero
}

@preconcurrency @MainActor
open class UIPrintPageRenderer: NSObject {
    public var headerHeight: CGFloat = 0
    public var footerHeight: CGFloat = 0
    public var paperRect: CGRect = .zero
    public var printableRect: CGRect = .zero
    public var numberOfPages: Int { 0 }

    /// Focus OpenUtils.swift:25. Fail-closed: no spooler.
    open func addPrintFormatter(_ formatter: UIPrintFormatter, startingAtPageAt pageIndex: Int) {
        _ = (formatter, pageIndex)
    }
}

@preconcurrency @MainActor
open class UIPrintFormatter: NSObject {
    public var startPage: Int = 0
    public var pageCount: Int = 0
}

@preconcurrency @MainActor
public protocol UIPrintInteractionControllerDelegate: AnyObject {
    func printInteractionControllerParentViewController(_ printInteractionController: UIPrintInteractionController) -> UIViewController?
    func printInteractionControllerWillPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController)
    func printInteractionControllerDidPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController)
    func printInteractionControllerWillDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController)
    func printInteractionControllerDidDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController)
    func printInteractionControllerWillStartJob(_ printInteractionController: UIPrintInteractionController)
    func printInteractionControllerDidFinishJob(_ printInteractionController: UIPrintInteractionController)
}

extension UIPrintInteractionControllerDelegate {
    public func printInteractionControllerParentViewController(_ printInteractionController: UIPrintInteractionController) -> UIViewController? { nil }
    public func printInteractionControllerWillPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController) {}
    public func printInteractionControllerDidPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController) {}
    public func printInteractionControllerWillDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {}
    public func printInteractionControllerDidDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {}
    public func printInteractionControllerWillStartJob(_ printInteractionController: UIPrintInteractionController) {}
    public func printInteractionControllerDidFinishJob(_ printInteractionController: UIPrintInteractionController) {}
}

@preconcurrency @MainActor
open class UIPrintInteractionController: NSObject {
    public typealias CompletionHandler = (UIPrintInteractionController, Bool, Error?) -> Void

    public static var isPrintingAvailable: Bool { false }
    public static var printableUTIs: Set<String> { [] }
    public class func canPrint(_ url: URL) -> Bool { false }
    public class func canPrint(_ data: Data) -> Bool { false }

    public static let shared = UIPrintInteractionController()
    public static var sharedPrintController: UIPrintInteractionController { shared }

    public var printInfo: UIPrintInfo?
    public weak var delegate: UIPrintInteractionControllerDelegate?
    public var showsNumberOfCopies: Bool = true
    public var showsPaperSelectionForLoadedPapers: Bool = false
    public var showsPaperOrientation: Bool = true
    public private(set) var printPaper: UIPrintPaper?
    public var printPageRenderer: UIPrintPageRenderer?
    public var printFormatter: UIPrintFormatter?
    public var printingItem: Any?
    public var printingItems: [Any]?

    public func present(animated: Bool, completionHandler completion: CompletionHandler?) -> Bool {
        completion?(self, false, nil)
        return false
    }

    public func present(from rect: CGRect, in view: UIView, animated: Bool,
                        completionHandler completion: CompletionHandler?) -> Bool {
        _ = rect
        _ = view
        completion?(self, false, nil)
        return false
    }

    public func present(from item: UIBarButtonItem, animated: Bool,
                        completionHandler completion: CompletionHandler?) -> Bool {
        _ = item
        completion?(self, false, nil)
        return false
    }

    public func print(to printer: UIPrinter, completionHandler completion: CompletionHandler?) -> Bool {
        _ = printer
        completion?(self, false, nil)
        return false
    }

    public func dismiss(animated: Bool) {}
}

extension UIView {
    /// Focus WebViewController.swift:87 `browserView.viewPrintFormatter()`.
    open func viewPrintFormatter() -> UIPrintFormatter { UIPrintFormatter() }
}

@preconcurrency @MainActor
public protocol UIPrinterPickerControllerDelegate: AnyObject {
    func printerPickerControllerParentViewController(_ printerPickerController: UIPrinterPickerController) -> UIViewController?
    func printerPickerController(_ printerPickerController: UIPrinterPickerController, shouldShow printer: UIPrinter) -> Bool
    func printerPickerControllerWillPresent(_ printerPickerController: UIPrinterPickerController)
    func printerPickerControllerDidPresent(_ printerPickerController: UIPrinterPickerController)
    func printerPickerControllerWillDismiss(_ printerPickerController: UIPrinterPickerController)
    func printerPickerControllerDidDismiss(_ printerPickerController: UIPrinterPickerController)
    func printerPickerControllerDidSelectPrinter(_ printerPickerController: UIPrinterPickerController)
}

extension UIPrinterPickerControllerDelegate {
    public func printerPickerControllerParentViewController(_ printerPickerController: UIPrinterPickerController) -> UIViewController? { nil }
    public func printerPickerController(_ printerPickerController: UIPrinterPickerController, shouldShow printer: UIPrinter) -> Bool { false }
    public func printerPickerControllerWillPresent(_ printerPickerController: UIPrinterPickerController) {}
    public func printerPickerControllerDidPresent(_ printerPickerController: UIPrinterPickerController) {}
    public func printerPickerControllerWillDismiss(_ printerPickerController: UIPrinterPickerController) {}
    public func printerPickerControllerDidDismiss(_ printerPickerController: UIPrinterPickerController) {}
    public func printerPickerControllerDidSelectPrinter(_ printerPickerController: UIPrinterPickerController) {}
}

@preconcurrency @MainActor
open class UIPrinterPickerController: NSObject {
    public typealias CompletionHandler = (UIPrinterPickerController, Bool, Error?) -> Void

    public private(set) var selectedPrinter: UIPrinter?
    public weak var delegate: UIPrinterPickerControllerDelegate?

    public class func printerPickerController(initiallySelectedPrinter printer: UIPrinter?) -> UIPrinterPickerController {
        UIPrinterPickerController(printer: printer)
    }

    public convenience init(initiallySelectedPrinter printer: UIPrinter?) {
        self.init(printer: printer)
    }

    public init(printer: UIPrinter?) {
        self.selectedPrinter = printer
        super.init()
    }

    public func present(animated: Bool, completionHandler completion: CompletionHandler?) -> Bool {
        completion?(self, false, nil)
        return false
    }

    public func present(from rect: CGRect, in view: UIView, animated: Bool,
                         completionHandler completion: CompletionHandler?) -> Bool {
        _ = rect
        _ = view
        completion?(self, false, nil)
        return false
    }

    public func present(from item: UIBarButtonItem, animated: Bool,
                         completionHandler completion: CompletionHandler?) -> Bool {
        _ = item
        completion?(self, false, nil)
        return false
    }

    public func dismiss(animated: Bool) {}
}
