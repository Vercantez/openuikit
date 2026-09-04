import Foundation

// Numeric raw values follow the public iPhoneOS 26.1 PDFKit C enumerations
// (`NS_ENUM` / `NS_OPTIONS`) as recorded by the pinned symbol graph names.
// Typed-string raw values follow the public PDF dictionary keys those
// overlays represent. Exact Apple runtime constants that are not in the
// graph are listed in `oracle-questions.tsv`.

public struct PDFAccessPermissions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let allowsLowQualityPrinting = PDFAccessPermissions(rawValue: 1 << 0)
    public static let allowsHighQualityPrinting = PDFAccessPermissions(rawValue: 1 << 1)
    public static let allowsDocumentChanges = PDFAccessPermissions(rawValue: 1 << 2)
    public static let allowsDocumentAssembly = PDFAccessPermissions(rawValue: 1 << 3)
    public static let allowsContentCopying = PDFAccessPermissions(rawValue: 1 << 4)
    public static let allowsContentAccessibility = PDFAccessPermissions(rawValue: 1 << 5)
    public static let allowsCommenting = PDFAccessPermissions(rawValue: 1 << 6)
    public static let allowsFormFieldEntry = PDFAccessPermissions(rawValue: 1 << 7)
}

public enum PDFActionNamedName: Int, Hashable, Sendable {
    case none = 0
    case nextPage = 1
    case previousPage = 2
    case firstPage = 3
    case lastPage = 4
    case goBack = 5
    case goForward = 6
    case goToPage = 7
    case find = 8
    case print = 9
    case zoomIn = 10
    case zoomOut = 11
}

public struct PDFAreaOfInterest: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let pageArea = PDFAreaOfInterest(rawValue: 1 << 0)
    public static let textArea = PDFAreaOfInterest(rawValue: 1 << 1)
    public static let annotationArea = PDFAreaOfInterest(rawValue: 1 << 2)
    public static let linkArea = PDFAreaOfInterest(rawValue: 1 << 3)
    public static let controlArea = PDFAreaOfInterest(rawValue: 1 << 4)
    public static let textFieldArea = PDFAreaOfInterest(rawValue: 1 << 5)
    public static let iconArea = PDFAreaOfInterest(rawValue: 1 << 6)
    public static let popupArea = PDFAreaOfInterest(rawValue: 1 << 7)
    public static let imageArea = PDFAreaOfInterest(rawValue: 1 << 8)
    public static let anyArea = PDFAreaOfInterest(rawValue: Int.max)
}

public enum PDFBorderStyle: Int, Hashable, Sendable {
    case solid = 0
    case dashed = 1
    case beveled = 2
    case inset = 3
    case underline = 4
}

public enum PDFDisplayBox: Int, Hashable, Sendable {
    case mediaBox = 0
    case cropBox = 1
    case bleedBox = 2
    case trimBox = 3
    case artBox = 4
}

public enum PDFDisplayDirection: Int, Hashable, Sendable {
    case vertical = 0
    case horizontal = 1
}

public enum PDFDisplayMode: Int, Hashable, Sendable {
    case singlePage = 0
    case singlePageContinuous = 1
    case twoUp = 2
    case twoUpContinuous = 3
}

public enum PDFDocumentPermissions: Int, Hashable, Sendable {
    case none = 0
    case user = 1
    case owner = 2
}

public enum PDFInterpolationQuality: Int, Hashable, Sendable {
    case none = 0
    case low = 1
    case high = 2
}

public enum PDFLineStyle: Int, Hashable, Sendable {
    case none = 0
    case square = 1
    case circle = 2
    case diamond = 3
    case openArrow = 4
    case closedArrow = 5
}

public enum PDFMarkupType: Int, Hashable, Sendable {
    case highlight = 0
    case strikeOut = 1
    case underline = 2
    case redact = 3
}

public enum PDFSelectionGranularity: UInt, Hashable, Sendable {
    case character = 0
    case word = 1
    case line = 2
}

public enum PDFTextAnnotationIconType: Int, Hashable, Sendable {
    case comment = 0
    case key = 1
    case note = 2
    case help = 3
    case newParagraph = 4
    case paragraph = 5
    case insert = 6
}

public enum PDFThumbnailLayoutMode: Int, Hashable, Sendable {
    case vertical = 0
    case horizontal = 1
}

public enum PDFWidgetCellState: Int, Hashable, Sendable {
    case mixedState = -1
    case offState = 0
    case onState = 1
}

public enum PDFWidgetControlType: Int, Hashable, Sendable {
    case unknownControl = -1
    case pushButtonControl = 0
    case radioButtonControl = 1
    case checkBoxControl = 2
}

public struct PDFAnnotationHighlightingMode: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let none = PDFAnnotationHighlightingMode(rawValue: "N")
    public static let invert = PDFAnnotationHighlightingMode(rawValue: "I")
    public static let outline = PDFAnnotationHighlightingMode(rawValue: "O")
    public static let push = PDFAnnotationHighlightingMode(rawValue: "P")
}

public struct PDFAnnotationKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let appearanceDictionary = PDFAnnotationKey(rawValue: "/AP")
    public static let appearanceState = PDFAnnotationKey(rawValue: "/AS")
    public static let border = PDFAnnotationKey(rawValue: "/Border")
    public static let color = PDFAnnotationKey(rawValue: "/C")
    public static let contents = PDFAnnotationKey(rawValue: "/Contents")
    public static let flags = PDFAnnotationKey(rawValue: "/F")
    public static let date = PDFAnnotationKey(rawValue: "/M")
    public static let name = PDFAnnotationKey(rawValue: "/NM")
    public static let page = PDFAnnotationKey(rawValue: "/P")
    public static let rect = PDFAnnotationKey(rawValue: "/Rect")
    public static let subtype = PDFAnnotationKey(rawValue: "/Subtype")
    public static let action = PDFAnnotationKey(rawValue: "/A")
    public static let additionalActions = PDFAnnotationKey(rawValue: "/AA")
    public static let borderStyle = PDFAnnotationKey(rawValue: "/BS")
    public static let defaultAppearance = PDFAnnotationKey(rawValue: "/DA")
    public static let destination = PDFAnnotationKey(rawValue: "/Dest")
    public static let highlightingMode = PDFAnnotationKey(rawValue: "/H")
    public static let inklist = PDFAnnotationKey(rawValue: "/InkList")
    public static let interiorColor = PDFAnnotationKey(rawValue: "/IC")
    public static let linePoints = PDFAnnotationKey(rawValue: "/L")
    public static let lineEndingStyles = PDFAnnotationKey(rawValue: "/LE")
    public static let iconName = PDFAnnotationKey(rawValue: "/Name")
    public static let open = PDFAnnotationKey(rawValue: "/Open")
    public static let parent = PDFAnnotationKey(rawValue: "/Parent")
    public static let popup = PDFAnnotationKey(rawValue: "/Popup")
    public static let quadding = PDFAnnotationKey(rawValue: "/Q")
    public static let quadPoints = PDFAnnotationKey(rawValue: "/QuadPoints")
    public static let textLabel = PDFAnnotationKey(rawValue: "/T")
    public static let widgetDownCaption = PDFAnnotationKey(rawValue: "/AC")
    public static let widgetBorderColor = PDFAnnotationKey(rawValue: "/BC")
    public static let widgetBackgroundColor = PDFAnnotationKey(rawValue: "/BG")
    public static let widgetCaption = PDFAnnotationKey(rawValue: "/CA")
    public static let widgetDefaultValue = PDFAnnotationKey(rawValue: "/DV")
    public static let widgetFieldFlags = PDFAnnotationKey(rawValue: "/Ff")
    public static let widgetFieldType = PDFAnnotationKey(rawValue: "/FT")
    public static let widgetAppearanceDictionary = PDFAnnotationKey(rawValue: "/MK")
    public static let widgetMaxLen = PDFAnnotationKey(rawValue: "/MaxLen")
    public static let widgetOptions = PDFAnnotationKey(rawValue: "/Opt")
    public static let widgetRotation = PDFAnnotationKey(rawValue: "/R")
    public static let widgetRolloverCaption = PDFAnnotationKey(rawValue: "/RC")
    public static let widgetTextLabelUI = PDFAnnotationKey(rawValue: "/TU")
    public static let widgetValue = PDFAnnotationKey(rawValue: "/V")
}

public struct PDFAnnotationLineEndingStyle: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let none = PDFAnnotationLineEndingStyle(rawValue: "None")
    public static let square = PDFAnnotationLineEndingStyle(rawValue: "Square")
    public static let circle = PDFAnnotationLineEndingStyle(rawValue: "Circle")
    public static let diamond = PDFAnnotationLineEndingStyle(rawValue: "Diamond")
    public static let openArrow = PDFAnnotationLineEndingStyle(rawValue: "OpenArrow")
    public static let closedArrow = PDFAnnotationLineEndingStyle(rawValue: "ClosedArrow")
}

public struct PDFAnnotationSubtype: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let text = PDFAnnotationSubtype(rawValue: "/Text")
    public static let link = PDFAnnotationSubtype(rawValue: "/Link")
    public static let freeText = PDFAnnotationSubtype(rawValue: "/FreeText")
    public static let line = PDFAnnotationSubtype(rawValue: "/Line")
    public static let square = PDFAnnotationSubtype(rawValue: "/Square")
    public static let circle = PDFAnnotationSubtype(rawValue: "/Circle")
    public static let highlight = PDFAnnotationSubtype(rawValue: "/Highlight")
    public static let underline = PDFAnnotationSubtype(rawValue: "/Underline")
    public static let strikeOut = PDFAnnotationSubtype(rawValue: "/StrikeOut")
    public static let ink = PDFAnnotationSubtype(rawValue: "/Ink")
    public static let stamp = PDFAnnotationSubtype(rawValue: "/Stamp")
    public static let popup = PDFAnnotationSubtype(rawValue: "/Popup")
    public static let widget = PDFAnnotationSubtype(rawValue: "/Widget")
}

public struct PDFAnnotationTextIconType: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let comment = PDFAnnotationTextIconType(rawValue: "Comment")
    public static let key = PDFAnnotationTextIconType(rawValue: "Key")
    public static let note = PDFAnnotationTextIconType(rawValue: "Note")
    public static let help = PDFAnnotationTextIconType(rawValue: "Help")
    public static let newParagraph = PDFAnnotationTextIconType(rawValue: "NewParagraph")
    public static let paragraph = PDFAnnotationTextIconType(rawValue: "Paragraph")
    public static let insert = PDFAnnotationTextIconType(rawValue: "Insert")
}

public struct PDFAnnotationWidgetSubtype: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let button = PDFAnnotationWidgetSubtype(rawValue: "/Btn")
    public static let choice = PDFAnnotationWidgetSubtype(rawValue: "/Ch")
    public static let signature = PDFAnnotationWidgetSubtype(rawValue: "/Sig")
    public static let text = PDFAnnotationWidgetSubtype(rawValue: "/Tx")
}

public struct PDFAppearanceCharacteristicsKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let backgroundColor = PDFAppearanceCharacteristicsKey(rawValue: "/BG")
    public static let borderColor = PDFAppearanceCharacteristicsKey(rawValue: "/BC")
    public static let rotation = PDFAppearanceCharacteristicsKey(rawValue: "/R")
    public static let caption = PDFAppearanceCharacteristicsKey(rawValue: "/CA")
    public static let rolloverCaption = PDFAppearanceCharacteristicsKey(rawValue: "/RC")
    public static let downCaption = PDFAppearanceCharacteristicsKey(rawValue: "/AC")
}

public struct PDFBorderKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let lineWidth = PDFBorderKey(rawValue: "/W")
    public static let style = PDFBorderKey(rawValue: "/S")
    public static let dashPattern = PDFBorderKey(rawValue: "/D")
}

public struct PDFDocumentAttribute: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let titleAttribute = PDFDocumentAttribute(rawValue: "Title")
    public static let authorAttribute = PDFDocumentAttribute(rawValue: "Author")
    public static let subjectAttribute = PDFDocumentAttribute(rawValue: "Subject")
    public static let creatorAttribute = PDFDocumentAttribute(rawValue: "Creator")
    public static let producerAttribute = PDFDocumentAttribute(rawValue: "Producer")
    public static let creationDateAttribute = PDFDocumentAttribute(rawValue: "CreationDate")
    public static let modificationDateAttribute = PDFDocumentAttribute(rawValue: "ModDate")
    public static let keywordsAttribute = PDFDocumentAttribute(rawValue: "Keywords")
}

public struct PDFDocumentWriteOption: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ownerPasswordOption = PDFDocumentWriteOption(rawValue: "PDFDocumentOwnerPassword")
    public static let userPasswordOption = PDFDocumentWriteOption(rawValue: "PDFDocumentUserPassword")
    public static let accessPermissionsOption = PDFDocumentWriteOption(rawValue: "PDFDocumentAccessPermissions")
    public static let burnInAnnotationsOption = PDFDocumentWriteOption(rawValue: "PDFDocumentBurnInAnnotations")
    public static let saveTextFromOCROption = PDFDocumentWriteOption(rawValue: "PDFDocumentSaveTextFromOCR")
    public static let saveImagesAsJPEGOption = PDFDocumentWriteOption(rawValue: "PDFDocumentSaveImagesAsJPEG")
    public static let optimizeImagesForScreenOption = PDFDocumentWriteOption(rawValue: "PDFDocumentOptimizeImagesForScreen")
}
