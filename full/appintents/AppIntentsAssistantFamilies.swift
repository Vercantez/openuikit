import Foundation

// Default implementations for AssistantSchemas family protocols.
// Linux stores tokens in-process; there is no Apple Intelligence extract.

extension AssistantSchemas.CameraEnum {
    public var captureMode: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("captureMode")
    }
    public var captureDevice: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("captureDevice")
    }
    public var captureDuration: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("captureDuration")
    }
}

extension AssistantSchemas.CameraIntent {
    public var stopCapture: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("stopCapture")
    }
    public var startCapture: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("startCapture")
    }
    public var switchDevice: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("switchDevice")
    }
    public var openInCaptureMode: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openInCaptureMode")
    }
    public var setDevice: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setDevice")
    }
}

extension AssistantSchemas.MailEntity {
    public var draft: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("draft")
    }
    public var account: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("account")
    }
    public var mailbox: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("mailbox")
    }
    public var message: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("message")
    }
}

extension AssistantSchemas.MailIntent {
    public var replyMail: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("replyMail")
    }
    public var deleteMail: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteMail")
    }
    public var updateMail: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateMail")
    }
    public var archiveMail: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("archiveMail")
    }
    public var forwardMail: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("forwardMail")
    }
    public var createDraft: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createDraft")
    }
    public var deleteDraft: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteDraft")
    }
    public var updateDraft: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateDraft")
    }
    public var saveDraft: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("saveDraft")
    }
    public var sendDraft: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("sendDraft")
    }
}

extension AssistantSchemas.PhotosEnum {
    public var filterType: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("filterType")
    }
    public var rotationDirection: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("rotationDirection")
    }
    public var albumType: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("albumType")
    }
    public var assetType: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("assetType")
    }
}

extension AssistantSchemas.PhotosEntity {
    public var recognizedPerson: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("recognizedPerson")
    }
    public var album: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("album")
    }
    public var asset: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("asset")
    }
}

extension AssistantSchemas.PhotosIntent {
    public var pasteEdits: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("pasteEdits")
    }
    public var straighten: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("straighten")
    }
    public var createAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createAlbum")
    }
    public var deleteAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteAlbum")
    }
    public var setExposure: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setExposure")
    }
    public var setRotation: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setRotation")
    }
    public var toggleDepth: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("toggleDepth")
    }
    public var updateAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateAlbum")
    }
    public var updateAsset: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateAsset")
    }
    public var cleanupPhoto: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("cleanupPhoto")
    }
    public var createAssets: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createAssets")
    }
    public var deleteAssets: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteAssets")
    }
    public var setSaturation: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setSaturation")
    }
    public var duplicateAssets: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("duplicateAssets")
    }
    public var addAssetsToAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addAssetsToAlbum")
    }
    public var postToSharedAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("postToSharedAlbum")
    }
    public var toggleSuggestedEdits: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("toggleSuggestedEdits")
    }
    public var removeAssetsFromAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("removeAssetsFromAlbum")
    }
    public var updateRecognizedPerson: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateRecognizedPerson")
    }
    public var crop: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("crop")
    }
    public var search: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("search")
    }
    public var setDepth: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setDepth")
    }
    public var copyEdits: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("copyEdits")
    }
    public var openAlbum: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openAlbum")
    }
    public var openAsset: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openAsset")
    }
    public var setFilter: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setFilter")
    }
    public var setWarmth: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setWarmth")
    }
}

extension AssistantSchemas.ReaderEnum {
    public var documentKind: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("documentKind")
    }
}

extension AssistantSchemas.ReaderEntity {
    public var page: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("page")
    }
    public var document: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("document")
    }
}

extension AssistantSchemas.ReaderIntent {
    public var deletePages: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deletePages")
    }
    public var insertPages: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("insertPages")
    }
    public var rotatePages: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("rotatePages")
    }
    public var openDocument: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openDocument")
    }
    public var resizeDocuments: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("resizeDocuments")
    }
    public var rotateDocuments: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("rotateDocuments")
    }
    public var searchDocuments: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("searchDocuments")
    }
    public var enhanceDocuments: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("enhanceDocuments")
    }
    public var openPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openPage")
    }
}

extension AssistantSchemas.BooksEnum {
    public var contentType: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("contentType")
    }
    public var relativeFontChange: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("relativeFontChange")
    }
    public var navigationDirection: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("navigationDirection")
    }
    public var pageNavigationSetting: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("pageNavigationSetting")
    }
    public var relativeLineSpacingChange: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("relativeLineSpacingChange")
    }
    public var relativeWordSpacingChange: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("relativeWordSpacingChange")
    }
    public var relativeCharacterSpacingChange: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("relativeCharacterSpacingChange")
    }
    public var font: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("font")
    }
    public var theme: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("theme")
    }
    public var fontSize: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("fontSize")
    }
}

extension AssistantSchemas.BooksEntity {
    public var book: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("book")
    }
    public var settings: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("settings")
    }
    public var audiobook: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("audiobook")
    }
}

extension AssistantSchemas.BooksIntent {
    public var navigatePage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("navigatePage")
    }
    public var playAudiobook: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("playAudiobook")
    }
    public var updateFontSize: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateFontSize")
    }
    public var updateSettings: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateSettings")
    }
    public var updateLineSpacing: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateLineSpacing")
    }
    public var updateWordSpacing: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateWordSpacing")
    }
    public var updateCharacterSpacing: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateCharacterSpacing")
    }
    public var search: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("search")
    }
    public var openBook: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openBook")
    }
}

extension AssistantSchemas.BrowserEnum {
    public var clearHistoryTimeFrame: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("clearHistoryTimeFrame")
    }
}

extension AssistantSchemas.BrowserEntity {
    public var tab: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("tab")
    }
    public var window: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("window")
    }
    public var bookmark: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("bookmark")
    }
}

extension AssistantSchemas.BrowserIntent {
    public var findOnPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("findOnPage")
    }
    public var bookmarkTab: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("bookmarkTab")
    }
    public var bookmarkURL: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("bookmarkURL")
    }
    public var clearHistory: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("clearHistory")
    }
    public var closeWindows: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("closeWindows")
    }
    public var createWindow: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createWindow")
    }
    public var openBookmark: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openBookmark")
    }
    public var openURLInTab: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openURLInTab")
    }
    public var deleteBookmarks: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteBookmarks")
    }
    public var search: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("search")
    }
    public var closeTabs: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("closeTabs")
    }
    public var createTab: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createTab")
    }
    public var switchTab: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("switchTab")
    }
}

extension AssistantSchemas.FilesEntity {
    public var file: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("file")
    }
}

extension AssistantSchemas.FilesIntent {
    public var moveFiles: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("moveFiles")
    }
    public var deleteFiles: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteFiles")
    }
    public var renameFile: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("renameFile")
    }
    public var createFolder: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createFolder")
    }
    public var openFile: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openFile")
    }
}

extension AssistantSchemas.JournalEntity {
    public var entry: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("entry")
    }
}

extension AssistantSchemas.JournalIntent {
    public var createEntry: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createEntry")
    }
    public var deleteEntry: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteEntry")
    }
    public var updateEntry: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateEntry")
    }
    public var createAudioEntry: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createAudioEntry")
    }
    public var search: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("search")
    }
}

extension AssistantSchemas.WhiteboardEnum {
    public var color: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("color")
    }
    public var itemType: some AssistantSchemas.Enum {
        AssistantSchemas.EnumSchema("itemType")
    }
}

extension AssistantSchemas.WhiteboardEntity {
    public var item: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("item")
    }
    public var board: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("board")
    }
}

extension AssistantSchemas.WhiteboardIntent {
    public var createItem: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createItem")
    }
    public var deleteItem: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteItem")
    }
    public var updateItem: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateItem")
    }
    public var createBoard: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createBoard")
    }
    public var deleteBoard: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteBoard")
    }
    public var updateBoard: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateBoard")
    }
    public var openBoard: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openBoard")
    }
}

extension AssistantSchemas.SpreadsheetEntity {
    public var sheet: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("sheet")
    }
    public var document: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("document")
    }
    public var template: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("template")
    }
}

extension AssistantSchemas.SpreadsheetIntent {
    public var createSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createSheet")
    }
    public var deleteSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteSheet")
    }
    public var updateSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("updateSheet")
    }
    public var addAudioToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addAudioToSheet")
    }
    public var addImageToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addImageToSheet")
    }
    public var addVideoToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addVideoToSheet")
    }
    public var addCommentToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addCommentToSheet")
    }
    public var addTextBoxToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addTextBoxToSheet")
    }
    public var addWebVideoToSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addWebVideoToSheet")
    }
    public var `open`: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("open")
    }
    public var create: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("create")
    }
    public var delete: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("delete")
    }
    public var update: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("update")
    }
    public var openSheet: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openSheet")
    }
}

extension AssistantSchemas.PresentationEntity {
    public var slide: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("slide")
    }
    public var document: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("document")
    }
    public var template: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("template")
    }
}

extension AssistantSchemas.PresentationIntent {
    public var createSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createSlide")
    }
    public var deleteSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("deleteSlide")
    }
    public var stopPlayback: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("stopPlayback")
    }
    public var setSlideTitle: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("setSlideTitle")
    }
    public var startPlayback: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("startPlayback")
    }
    public var addAudioToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addAudioToSlide")
    }
    public var addImageToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addImageToSlide")
    }
    public var addVideoToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addVideoToSlide")
    }
    public var addCommentToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addCommentToSlide")
    }
    public var addTextBoxToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addTextBoxToSlide")
    }
    public var addWebVideoToSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addWebVideoToSlide")
    }
    public var `open`: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("open")
    }
    public var create: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("create")
    }
    public var update: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("update")
    }
    public var openSlide: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openSlide")
    }
}

extension AssistantSchemas.WordProcessorEntity {
    public var page: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("page")
    }
    public var document: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("document")
    }
    public var template: some AssistantSchemas.Entity {
        AssistantSchemas.EntitySchema("template")
    }
}

extension AssistantSchemas.WordProcessorIntent {
    public var createPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("createPage")
    }
    public var addAudioToPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addAudioToPage")
    }
    public var addImageToPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addImageToPage")
    }
    public var addVideoToPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addVideoToPage")
    }
    public var addTextBoxToPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addTextBoxToPage")
    }
    public var addWebVideoToPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("addWebVideoToPage")
    }
    public var `open`: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("open")
    }
    public var create: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("create")
    }
    public var openPage: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("openPage")
    }
}

extension AssistantSchemas.VisualIntelligenceIntent {
    public var semanticContentSearch: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("semanticContentSearch")
    }
}

extension AssistantSchemas.SystemIntent {
    public var search: some AssistantSchemas.Intent {
        AssistantSchemas.IntentSchema("search")
    }
}

