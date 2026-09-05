import Foundation

/// Assistant schema families with the required parameter names from the
/// pinned 26.1 graph. Linux stores the catalog in-process; there is no
/// Apple Intelligence runtime to validate a live schema extract.
public enum AssistantSchemas: Sendable {
    public protocol Model {}
    public protocol Enum: Model {}
    public protocol Entity: Model {}
    public protocol Intent: Model {}
    public protocol CameraEnum: Model {}
    public protocol CameraIntent: Model {}
    public protocol MailEntity: Model {}
    public protocol MailIntent: Model {}
    public protocol PhotosEnum: Model {}
    public protocol PhotosEntity: Model {}
    public protocol PhotosIntent: Model {}
    public protocol ReaderEnum: Model {}
    public protocol ReaderEntity: Model {}
    public protocol ReaderIntent: Model {}
    public protocol BooksEnum: Model {}
    public protocol BooksEntity: Model {}
    public protocol BooksIntent: Model {}
    public protocol BrowserEnum: Model {}
    public protocol BrowserEntity: Model {}
    public protocol BrowserIntent: Model {}
    public protocol FilesEntity: Model {}
    public protocol FilesIntent: Model {}
    public protocol JournalEntity: Model {}
    public protocol JournalIntent: Model {}
    public protocol WhiteboardEnum: Model {}
    public protocol WhiteboardEntity: Model {}
    public protocol WhiteboardIntent: Model {}
    public protocol SpreadsheetEntity: Model {}
    public protocol SpreadsheetIntent: Model {}
    public protocol PresentationEntity: Model {}
    public protocol PresentationIntent: Model {}
    public protocol WordProcessorEntity: Model {}
    public protocol WordProcessorIntent: Model {}
    public protocol VisualIntelligenceIntent: Model {}
    public protocol SystemIntent: Model {}

    public struct EnumSchema: Enum, Sendable {
        public let name: String
        public init(_ name: String = "") { self.name = name }
        public init() { self.name = "" }
        public var captureMode: EnumSchema { .init("captureMode") }
        public var captureDevice: EnumSchema { .init("captureDevice") }
        public var captureDuration: EnumSchema { .init("captureDuration") }
        public var filterType: EnumSchema { .init("filterType") }
        public var rotationDirection: EnumSchema { .init("rotationDirection") }
        public var albumType: EnumSchema { .init("albumType") }
        public var assetType: EnumSchema { .init("assetType") }
        public var documentKind: EnumSchema { .init("documentKind") }
        public var contentType: EnumSchema { .init("contentType") }
        public var relativeFontChange: EnumSchema { .init("relativeFontChange") }
        public var navigationDirection: EnumSchema { .init("navigationDirection") }
        public var pageNavigationSetting: EnumSchema { .init("pageNavigationSetting") }
        public var relativeLineSpacingChange: EnumSchema { .init("relativeLineSpacingChange") }
        public var relativeWordSpacingChange: EnumSchema { .init("relativeWordSpacingChange") }
        public var relativeCharacterSpacingChange: EnumSchema { .init("relativeCharacterSpacingChange") }
        public var font: EnumSchema { .init("font") }
        public var theme: EnumSchema { .init("theme") }
        public var fontSize: EnumSchema { .init("fontSize") }
        public var clearHistoryTimeFrame: EnumSchema { .init("clearHistoryTimeFrame") }
        public var color: EnumSchema { .init("color") }
        public var itemType: EnumSchema { .init("itemType") }
    }

    public struct EntitySchema: Entity, Sendable {
        public let name: String
        public init(_ name: String = "") { self.name = name }
        public init() { self.name = "" }
        public var draft: EntitySchema { .init("draft") }
        public var account: EntitySchema { .init("account") }
        public var mailbox: EntitySchema { .init("mailbox") }
        public var message: EntitySchema { .init("message") }
        public var recognizedPerson: EntitySchema { .init("recognizedPerson") }
        public var album: EntitySchema { .init("album") }
        public var asset: EntitySchema { .init("asset") }
        public var page: EntitySchema { .init("page") }
        public var document: EntitySchema { .init("document") }
        public var book: EntitySchema { .init("book") }
        public var settings: EntitySchema { .init("settings") }
        public var audiobook: EntitySchema { .init("audiobook") }
        public var tab: EntitySchema { .init("tab") }
        public var window: EntitySchema { .init("window") }
        public var bookmark: EntitySchema { .init("bookmark") }
        public var file: EntitySchema { .init("file") }
        public var entry: EntitySchema { .init("entry") }
        public var item: EntitySchema { .init("item") }
        public var board: EntitySchema { .init("board") }
        public var sheet: EntitySchema { .init("sheet") }
        public var template: EntitySchema { .init("template") }
        public var slide: EntitySchema { .init("slide") }
    }

    public struct IntentSchema: Intent, Sendable {
        public let name: String
        public init(_ name: String = "") { self.name = name }
        public init() { self.name = "" }
        public var stopCapture: IntentSchema { .init("stopCapture") }
        public var startCapture: IntentSchema { .init("startCapture") }
        public var switchDevice: IntentSchema { .init("switchDevice") }
        public var openInCaptureMode: IntentSchema { .init("openInCaptureMode") }
        public var setDevice: IntentSchema { .init("setDevice") }
        public var replyMail: IntentSchema { .init("replyMail") }
        public var deleteMail: IntentSchema { .init("deleteMail") }
        public var updateMail: IntentSchema { .init("updateMail") }
        public var archiveMail: IntentSchema { .init("archiveMail") }
        public var forwardMail: IntentSchema { .init("forwardMail") }
        public var createDraft: IntentSchema { .init("createDraft") }
        public var deleteDraft: IntentSchema { .init("deleteDraft") }
        public var updateDraft: IntentSchema { .init("updateDraft") }
        public var saveDraft: IntentSchema { .init("saveDraft") }
        public var sendDraft: IntentSchema { .init("sendDraft") }
        public var pasteEdits: IntentSchema { .init("pasteEdits") }
        public var straighten: IntentSchema { .init("straighten") }
        public var createAlbum: IntentSchema { .init("createAlbum") }
        public var deleteAlbum: IntentSchema { .init("deleteAlbum") }
        public var setExposure: IntentSchema { .init("setExposure") }
        public var setRotation: IntentSchema { .init("setRotation") }
        public var toggleDepth: IntentSchema { .init("toggleDepth") }
        public var updateAlbum: IntentSchema { .init("updateAlbum") }
        public var updateAsset: IntentSchema { .init("updateAsset") }
        public var cleanupPhoto: IntentSchema { .init("cleanupPhoto") }
        public var createAssets: IntentSchema { .init("createAssets") }
        public var deleteAssets: IntentSchema { .init("deleteAssets") }
        public var setSaturation: IntentSchema { .init("setSaturation") }
        public var duplicateAssets: IntentSchema { .init("duplicateAssets") }
        public var addAssetsToAlbum: IntentSchema { .init("addAssetsToAlbum") }
        public var postToSharedAlbum: IntentSchema { .init("postToSharedAlbum") }
        public var toggleSuggestedEdits: IntentSchema { .init("toggleSuggestedEdits") }
        public var removeAssetsFromAlbum: IntentSchema { .init("removeAssetsFromAlbum") }
        public var updateRecognizedPerson: IntentSchema { .init("updateRecognizedPerson") }
        public var crop: IntentSchema { .init("crop") }
        public var search: IntentSchema { .init("search") }
        public var setDepth: IntentSchema { .init("setDepth") }
        public var copyEdits: IntentSchema { .init("copyEdits") }
        public var openAlbum: IntentSchema { .init("openAlbum") }
        public var openAsset: IntentSchema { .init("openAsset") }
        public var setFilter: IntentSchema { .init("setFilter") }
        public var setWarmth: IntentSchema { .init("setWarmth") }
        public var deletePages: IntentSchema { .init("deletePages") }
        public var insertPages: IntentSchema { .init("insertPages") }
        public var rotatePages: IntentSchema { .init("rotatePages") }
        public var openDocument: IntentSchema { .init("openDocument") }
        public var resizeDocuments: IntentSchema { .init("resizeDocuments") }
        public var rotateDocuments: IntentSchema { .init("rotateDocuments") }
        public var searchDocuments: IntentSchema { .init("searchDocuments") }
        public var enhanceDocuments: IntentSchema { .init("enhanceDocuments") }
        public var openPage: IntentSchema { .init("openPage") }
        public var navigatePage: IntentSchema { .init("navigatePage") }
        public var playAudiobook: IntentSchema { .init("playAudiobook") }
        public var updateFontSize: IntentSchema { .init("updateFontSize") }
        public var updateSettings: IntentSchema { .init("updateSettings") }
        public var updateLineSpacing: IntentSchema { .init("updateLineSpacing") }
        public var updateWordSpacing: IntentSchema { .init("updateWordSpacing") }
        public var updateCharacterSpacing: IntentSchema { .init("updateCharacterSpacing") }
        public var openBook: IntentSchema { .init("openBook") }
        public var findOnPage: IntentSchema { .init("findOnPage") }
        public var bookmarkTab: IntentSchema { .init("bookmarkTab") }
        public var bookmarkURL: IntentSchema { .init("bookmarkURL") }
        public var clearHistory: IntentSchema { .init("clearHistory") }
        public var closeWindows: IntentSchema { .init("closeWindows") }
        public var createWindow: IntentSchema { .init("createWindow") }
        public var openBookmark: IntentSchema { .init("openBookmark") }
        public var openURLInTab: IntentSchema { .init("openURLInTab") }
        public var deleteBookmarks: IntentSchema { .init("deleteBookmarks") }
        public var closeTabs: IntentSchema { .init("closeTabs") }
        public var createTab: IntentSchema { .init("createTab") }
        public var switchTab: IntentSchema { .init("switchTab") }
        public var moveFiles: IntentSchema { .init("moveFiles") }
        public var deleteFiles: IntentSchema { .init("deleteFiles") }
        public var renameFile: IntentSchema { .init("renameFile") }
        public var createFolder: IntentSchema { .init("createFolder") }
        public var openFile: IntentSchema { .init("openFile") }
        public var createEntry: IntentSchema { .init("createEntry") }
        public var deleteEntry: IntentSchema { .init("deleteEntry") }
        public var updateEntry: IntentSchema { .init("updateEntry") }
        public var createAudioEntry: IntentSchema { .init("createAudioEntry") }
        public var createItem: IntentSchema { .init("createItem") }
        public var deleteItem: IntentSchema { .init("deleteItem") }
        public var updateItem: IntentSchema { .init("updateItem") }
        public var createBoard: IntentSchema { .init("createBoard") }
        public var deleteBoard: IntentSchema { .init("deleteBoard") }
        public var updateBoard: IntentSchema { .init("updateBoard") }
        public var openBoard: IntentSchema { .init("openBoard") }
        public var createSheet: IntentSchema { .init("createSheet") }
        public var deleteSheet: IntentSchema { .init("deleteSheet") }
        public var updateSheet: IntentSchema { .init("updateSheet") }
        public var addAudioToSheet: IntentSchema { .init("addAudioToSheet") }
        public var addImageToSheet: IntentSchema { .init("addImageToSheet") }
        public var addVideoToSheet: IntentSchema { .init("addVideoToSheet") }
        public var addCommentToSheet: IntentSchema { .init("addCommentToSheet") }
        public var addTextBoxToSheet: IntentSchema { .init("addTextBoxToSheet") }
        public var addWebVideoToSheet: IntentSchema { .init("addWebVideoToSheet") }
        public var `open`: IntentSchema { .init("open") }
        public var create: IntentSchema { .init("create") }
        public var delete: IntentSchema { .init("delete") }
        public var update: IntentSchema { .init("update") }
        public var openSheet: IntentSchema { .init("openSheet") }
        public var createSlide: IntentSchema { .init("createSlide") }
        public var deleteSlide: IntentSchema { .init("deleteSlide") }
        public var stopPlayback: IntentSchema { .init("stopPlayback") }
        public var setSlideTitle: IntentSchema { .init("setSlideTitle") }
        public var startPlayback: IntentSchema { .init("startPlayback") }
        public var addAudioToSlide: IntentSchema { .init("addAudioToSlide") }
        public var addImageToSlide: IntentSchema { .init("addImageToSlide") }
        public var addVideoToSlide: IntentSchema { .init("addVideoToSlide") }
        public var addCommentToSlide: IntentSchema { .init("addCommentToSlide") }
        public var addTextBoxToSlide: IntentSchema { .init("addTextBoxToSlide") }
        public var addWebVideoToSlide: IntentSchema { .init("addWebVideoToSlide") }
        public var openSlide: IntentSchema { .init("openSlide") }
        public var createPage: IntentSchema { .init("createPage") }
        public var addAudioToPage: IntentSchema { .init("addAudioToPage") }
        public var addImageToPage: IntentSchema { .init("addImageToPage") }
        public var addVideoToPage: IntentSchema { .init("addVideoToPage") }
        public var addTextBoxToPage: IntentSchema { .init("addTextBoxToPage") }
        public var addWebVideoToPage: IntentSchema { .init("addWebVideoToPage") }
        public var semanticContentSearch: IntentSchema { .init("semanticContentSearch") }
    }
}

extension AssistantSchemas.Enum where Self == AssistantSchemas.EnumSchema {
    public static var whiteboard: AssistantSchemas.EnumSchema { .init("whiteboard") }
    public static var books: AssistantSchemas.EnumSchema { .init("books") }
    public static var camera: AssistantSchemas.EnumSchema { .init("camera") }
    public static var photos: AssistantSchemas.EnumSchema { .init("photos") }
    public static var reader: AssistantSchemas.EnumSchema { .init("reader") }
    public static var browser: AssistantSchemas.EnumSchema { .init("browser") }
}

extension AssistantSchemas.Entity where Self == AssistantSchemas.EntitySchema {
    public static var whiteboard: AssistantSchemas.EntitySchema { .init("whiteboard") }
    public static var spreadsheet: AssistantSchemas.EntitySchema { .init("spreadsheet") }
    public static var presentation: AssistantSchemas.EntitySchema { .init("presentation") }
    public static var wordProcessor: AssistantSchemas.EntitySchema { .init("wordProcessor") }
    public static var mail: AssistantSchemas.EntitySchema { .init("mail") }
    public static var books: AssistantSchemas.EntitySchema { .init("books") }
    public static var files: AssistantSchemas.EntitySchema { .init("files") }
    public static var photos: AssistantSchemas.EntitySchema { .init("photos") }
    public static var reader: AssistantSchemas.EntitySchema { .init("reader") }
    public static var browser: AssistantSchemas.EntitySchema { .init("browser") }
    public static var journal: AssistantSchemas.EntitySchema { .init("journal") }
}

extension AssistantSchemas.Intent where Self == AssistantSchemas.IntentSchema {
    public static var whiteboard: AssistantSchemas.IntentSchema { .init("whiteboard") }
    public static var spreadsheet: AssistantSchemas.IntentSchema { .init("spreadsheet") }
    public static var presentation: AssistantSchemas.IntentSchema { .init("presentation") }
    public static var wordProcessor: AssistantSchemas.IntentSchema { .init("wordProcessor") }
    public static var visualIntelligence: AssistantSchemas.IntentSchema { .init("visualIntelligence") }
    public static var mail: AssistantSchemas.IntentSchema { .init("mail") }
    public static var books: AssistantSchemas.IntentSchema { .init("books") }
    public static var files: AssistantSchemas.IntentSchema { .init("files") }
    public static var camera: AssistantSchemas.IntentSchema { .init("camera") }
    public static var photos: AssistantSchemas.IntentSchema { .init("photos") }
    public static var reader: AssistantSchemas.IntentSchema { .init("reader") }
    public static var system: AssistantSchemas.IntentSchema { .init("system") }
    public static var browser: AssistantSchemas.IntentSchema { .init("browser") }
    public static var journal: AssistantSchemas.IntentSchema { .init("journal") }
}

public struct AssistantSchema: Sendable {
    public init() {}
    public init(_ schema: some AssistantSchemas.Enum) { _ = schema }
    public init(_ schema: some AssistantSchemas.Entity) { _ = schema }
    public init(_ schema: some AssistantSchemas.Intent) { _ = schema }
    public struct EnumSchema: Sendable {
        public init() {}
        public var captureMode: AssistantSchemas.EnumSchema { .init("captureMode") }
        public var captureDevice: AssistantSchemas.EnumSchema { .init("captureDevice") }
        public var captureDuration: AssistantSchemas.EnumSchema { .init("captureDuration") }
    }
    public struct EntitySchema: Sendable {
        public init() {}
        public var draft: AssistantSchemas.EntitySchema { .init("draft") }
        public var account: AssistantSchemas.EntitySchema { .init("account") }
        public var mailbox: AssistantSchemas.EntitySchema { .init("mailbox") }
        public var message: AssistantSchemas.EntitySchema { .init("message") }
    }
    public struct IntentSchema: Sendable {
        public init() {}
        public var search: AssistantSchemas.IntentSchema { .init("search") }
    }
}

public enum AssistantSchemaParameterCatalog: Sendable {
    public static let requiredParameterSets: [(family: String, parameters: [String])] = [
        ("CameraEnum", ["captureMode", "captureDevice", "captureDuration"]),
        ("CameraIntent", ["stopCapture", "startCapture", "switchDevice", "openInCaptureMode", "setDevice"]),
        ("MailEntity", ["draft", "account", "mailbox", "message"]),
        ("MailIntent", ["replyMail", "deleteMail", "updateMail", "archiveMail", "forwardMail", "createDraft", "deleteDraft", "updateDraft", "saveDraft", "sendDraft"]),
        ("PhotosEnum", ["filterType", "rotationDirection", "albumType", "assetType"]),
        ("PhotosEntity", ["recognizedPerson", "album", "asset"]),
        ("PhotosIntent", ["pasteEdits", "straighten", "createAlbum", "deleteAlbum", "setExposure", "setRotation", "toggleDepth", "updateAlbum", "updateAsset", "cleanupPhoto", "createAssets", "deleteAssets", "setSaturation", "duplicateAssets", "addAssetsToAlbum", "postToSharedAlbum", "toggleSuggestedEdits", "removeAssetsFromAlbum", "updateRecognizedPerson", "crop", "search", "setDepth", "copyEdits", "openAlbum", "openAsset", "setFilter", "setWarmth"]),
        ("ReaderEnum", ["documentKind"]),
        ("ReaderEntity", ["page", "document"]),
        ("ReaderIntent", ["deletePages", "insertPages", "rotatePages", "openDocument", "resizeDocuments", "rotateDocuments", "searchDocuments", "enhanceDocuments", "openPage"]),
        ("BooksEnum", ["contentType", "relativeFontChange", "navigationDirection", "pageNavigationSetting", "relativeLineSpacingChange", "relativeWordSpacingChange", "relativeCharacterSpacingChange", "font", "theme", "fontSize"]),
        ("BooksEntity", ["book", "settings", "audiobook"]),
        ("BooksIntent", ["navigatePage", "playAudiobook", "updateFontSize", "updateSettings", "updateLineSpacing", "updateWordSpacing", "updateCharacterSpacing", "search", "openBook"]),
        ("BrowserEnum", ["clearHistoryTimeFrame"]),
        ("BrowserEntity", ["tab", "window", "bookmark"]),
        ("BrowserIntent", ["findOnPage", "bookmarkTab", "bookmarkURL", "clearHistory", "closeWindows", "createWindow", "openBookmark", "openURLInTab", "deleteBookmarks", "search", "closeTabs", "createTab", "switchTab"]),
        ("FilesEntity", ["file"]),
        ("FilesIntent", ["moveFiles", "deleteFiles", "renameFile", "createFolder", "openFile"]),
        ("JournalEntity", ["entry"]),
        ("JournalIntent", ["createEntry", "deleteEntry", "updateEntry", "createAudioEntry", "search"]),
        ("WhiteboardEnum", ["color", "itemType"]),
        ("WhiteboardEntity", ["item", "board"]),
        ("WhiteboardIntent", ["createItem", "deleteItem", "updateItem", "createBoard", "deleteBoard", "updateBoard", "openBoard"]),
        ("SpreadsheetEntity", ["sheet", "document", "template"]),
        ("SpreadsheetIntent", ["createSheet", "deleteSheet", "updateSheet", "addAudioToSheet", "addImageToSheet", "addVideoToSheet", "addCommentToSheet", "addTextBoxToSheet", "addWebVideoToSheet", "open", "create", "delete", "update", "openSheet"]),
        ("PresentationEntity", ["slide", "document", "template"]),
        ("PresentationIntent", ["createSlide", "deleteSlide", "stopPlayback", "setSlideTitle", "startPlayback", "addAudioToSlide", "addImageToSlide", "addVideoToSlide", "addCommentToSlide", "addTextBoxToSlide", "addWebVideoToSlide", "open", "create", "update", "openSlide"]),
        ("WordProcessorEntity", ["page", "document", "template"]),
        ("WordProcessorIntent", ["createPage", "addAudioToPage", "addImageToPage", "addVideoToPage", "addTextBoxToPage", "addWebVideoToPage", "open", "create", "openPage"]),
        ("VisualIntelligenceIntent", ["semanticContentSearch"]),
        ("SystemIntent", ["search"]),
    ]

    public static func parameters(for family: String) -> [String] {
        requiredParameterSets.first(where: { $0.family == family })?.parameters ?? []
    }

    public static func token(family: String, parameter: String) -> String {
        guard parameters(for: family).contains(parameter) else { return "" }
        return parameter
    }
}
