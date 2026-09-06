import Foundation
import AppIntents

private func assistantEnumToken(_ value: some AssistantSchemas.Enum) -> String {
    (value as? AssistantSchemas.EnumSchema)?.name ?? ""
}
private func assistantEntityToken(_ value: some AssistantSchemas.Entity) -> String {
    (value as? AssistantSchemas.EntitySchema)?.name ?? ""
}
private func assistantIntentToken(_ value: some AssistantSchemas.Intent) -> String {
    (value as? AssistantSchemas.IntentSchema)?.name ?? ""
}

private struct CameraEnumProbe: AssistantSchemas.CameraEnum {}
private struct CameraIntentProbe: AssistantSchemas.CameraIntent {}
private struct MailEntityProbe: AssistantSchemas.MailEntity {}
private struct MailIntentProbe: AssistantSchemas.MailIntent {}
private struct PhotosEnumProbe: AssistantSchemas.PhotosEnum {}
private struct PhotosEntityProbe: AssistantSchemas.PhotosEntity {}
private struct PhotosIntentProbe: AssistantSchemas.PhotosIntent {}
private struct ReaderEnumProbe: AssistantSchemas.ReaderEnum {}
private struct ReaderEntityProbe: AssistantSchemas.ReaderEntity {}
private struct ReaderIntentProbe: AssistantSchemas.ReaderIntent {}
private struct BooksEnumProbe: AssistantSchemas.BooksEnum {}
private struct BooksEntityProbe: AssistantSchemas.BooksEntity {}
private struct BooksIntentProbe: AssistantSchemas.BooksIntent {}
private struct BrowserEnumProbe: AssistantSchemas.BrowserEnum {}
private struct BrowserEntityProbe: AssistantSchemas.BrowserEntity {}
private struct BrowserIntentProbe: AssistantSchemas.BrowserIntent {}
private struct FilesEntityProbe: AssistantSchemas.FilesEntity {}
private struct FilesIntentProbe: AssistantSchemas.FilesIntent {}
private struct JournalEntityProbe: AssistantSchemas.JournalEntity {}
private struct JournalIntentProbe: AssistantSchemas.JournalIntent {}
private struct WhiteboardEnumProbe: AssistantSchemas.WhiteboardEnum {}
private struct WhiteboardEntityProbe: AssistantSchemas.WhiteboardEntity {}
private struct WhiteboardIntentProbe: AssistantSchemas.WhiteboardIntent {}
private struct SpreadsheetEntityProbe: AssistantSchemas.SpreadsheetEntity {}
private struct SpreadsheetIntentProbe: AssistantSchemas.SpreadsheetIntent {}
private struct PresentationEntityProbe: AssistantSchemas.PresentationEntity {}
private struct PresentationIntentProbe: AssistantSchemas.PresentationIntent {}
private struct WordProcessorEntityProbe: AssistantSchemas.WordProcessorEntity {}
private struct WordProcessorIntentProbe: AssistantSchemas.WordProcessorIntent {}
private struct VisualIntelligenceIntentProbe: AssistantSchemas.VisualIntelligenceIntent {}
private struct SystemIntentProbe: AssistantSchemas.SystemIntent {}

func testAssistantSchemasCameraEnumRequiredParameters() {
    let probe = CameraEnumProbe()
    precondition(assistantEnumToken(probe.captureMode) == "captureMode")
    precondition(assistantEnumToken(probe.captureDevice) == "captureDevice")
    precondition(assistantEnumToken(probe.captureDuration) == "captureDuration")
}

func testAssistantSchemasCameraIntentRequiredParameters() {
    let probe = CameraIntentProbe()
    precondition(assistantIntentToken(probe.stopCapture) == "stopCapture")
    precondition(assistantIntentToken(probe.startCapture) == "startCapture")
    precondition(assistantIntentToken(probe.switchDevice) == "switchDevice")
    precondition(assistantIntentToken(probe.openInCaptureMode) == "openInCaptureMode")
    precondition(assistantIntentToken(probe.setDevice) == "setDevice")
}

func testAssistantSchemasMailEntityRequiredParameters() {
    let probe = MailEntityProbe()
    precondition(assistantEntityToken(probe.draft) == "draft")
    precondition(assistantEntityToken(probe.account) == "account")
    precondition(assistantEntityToken(probe.mailbox) == "mailbox")
    precondition(assistantEntityToken(probe.message) == "message")
}

func testAssistantSchemasMailIntentRequiredParameters() {
    let probe = MailIntentProbe()
    precondition(assistantIntentToken(probe.replyMail) == "replyMail")
    precondition(assistantIntentToken(probe.deleteMail) == "deleteMail")
    precondition(assistantIntentToken(probe.updateMail) == "updateMail")
    precondition(assistantIntentToken(probe.archiveMail) == "archiveMail")
    precondition(assistantIntentToken(probe.forwardMail) == "forwardMail")
    precondition(assistantIntentToken(probe.createDraft) == "createDraft")
    precondition(assistantIntentToken(probe.deleteDraft) == "deleteDraft")
    precondition(assistantIntentToken(probe.updateDraft) == "updateDraft")
    precondition(assistantIntentToken(probe.saveDraft) == "saveDraft")
    precondition(assistantIntentToken(probe.sendDraft) == "sendDraft")
}

func testAssistantSchemasPhotosEnumRequiredParameters() {
    let probe = PhotosEnumProbe()
    precondition(assistantEnumToken(probe.filterType) == "filterType")
    precondition(assistantEnumToken(probe.rotationDirection) == "rotationDirection")
    precondition(assistantEnumToken(probe.albumType) == "albumType")
    precondition(assistantEnumToken(probe.assetType) == "assetType")
}

func testAssistantSchemasPhotosEntityRequiredParameters() {
    let probe = PhotosEntityProbe()
    precondition(assistantEntityToken(probe.recognizedPerson) == "recognizedPerson")
    precondition(assistantEntityToken(probe.album) == "album")
    precondition(assistantEntityToken(probe.asset) == "asset")
}

func testAssistantSchemasPhotosIntentRequiredParameters() {
    let probe = PhotosIntentProbe()
    precondition(assistantIntentToken(probe.pasteEdits) == "pasteEdits")
    precondition(assistantIntentToken(probe.straighten) == "straighten")
    precondition(assistantIntentToken(probe.createAlbum) == "createAlbum")
    precondition(assistantIntentToken(probe.deleteAlbum) == "deleteAlbum")
    precondition(assistantIntentToken(probe.setExposure) == "setExposure")
    precondition(assistantIntentToken(probe.setRotation) == "setRotation")
    precondition(assistantIntentToken(probe.toggleDepth) == "toggleDepth")
    precondition(assistantIntentToken(probe.updateAlbum) == "updateAlbum")
    precondition(assistantIntentToken(probe.updateAsset) == "updateAsset")
    precondition(assistantIntentToken(probe.cleanupPhoto) == "cleanupPhoto")
    precondition(assistantIntentToken(probe.createAssets) == "createAssets")
    precondition(assistantIntentToken(probe.deleteAssets) == "deleteAssets")
    precondition(assistantIntentToken(probe.setSaturation) == "setSaturation")
    precondition(assistantIntentToken(probe.duplicateAssets) == "duplicateAssets")
    precondition(assistantIntentToken(probe.addAssetsToAlbum) == "addAssetsToAlbum")
    precondition(assistantIntentToken(probe.postToSharedAlbum) == "postToSharedAlbum")
    precondition(assistantIntentToken(probe.toggleSuggestedEdits) == "toggleSuggestedEdits")
    precondition(assistantIntentToken(probe.removeAssetsFromAlbum) == "removeAssetsFromAlbum")
    precondition(assistantIntentToken(probe.updateRecognizedPerson) == "updateRecognizedPerson")
    precondition(assistantIntentToken(probe.crop) == "crop")
    precondition(assistantIntentToken(probe.search) == "search")
    precondition(assistantIntentToken(probe.setDepth) == "setDepth")
    precondition(assistantIntentToken(probe.copyEdits) == "copyEdits")
    precondition(assistantIntentToken(probe.openAlbum) == "openAlbum")
    precondition(assistantIntentToken(probe.openAsset) == "openAsset")
    precondition(assistantIntentToken(probe.setFilter) == "setFilter")
    precondition(assistantIntentToken(probe.setWarmth) == "setWarmth")
}

func testAssistantSchemasReaderEnumRequiredParameters() {
    let probe = ReaderEnumProbe()
    precondition(assistantEnumToken(probe.documentKind) == "documentKind")
}

func testAssistantSchemasReaderEntityRequiredParameters() {
    let probe = ReaderEntityProbe()
    precondition(assistantEntityToken(probe.page) == "page")
    precondition(assistantEntityToken(probe.document) == "document")
}

func testAssistantSchemasReaderIntentRequiredParameters() {
    let probe = ReaderIntentProbe()
    precondition(assistantIntentToken(probe.deletePages) == "deletePages")
    precondition(assistantIntentToken(probe.insertPages) == "insertPages")
    precondition(assistantIntentToken(probe.rotatePages) == "rotatePages")
    precondition(assistantIntentToken(probe.openDocument) == "openDocument")
    precondition(assistantIntentToken(probe.resizeDocuments) == "resizeDocuments")
    precondition(assistantIntentToken(probe.rotateDocuments) == "rotateDocuments")
    precondition(assistantIntentToken(probe.searchDocuments) == "searchDocuments")
    precondition(assistantIntentToken(probe.enhanceDocuments) == "enhanceDocuments")
    precondition(assistantIntentToken(probe.openPage) == "openPage")
}

func testAssistantSchemasBooksEnumRequiredParameters() {
    let probe = BooksEnumProbe()
    precondition(assistantEnumToken(probe.contentType) == "contentType")
    precondition(assistantEnumToken(probe.relativeFontChange) == "relativeFontChange")
    precondition(assistantEnumToken(probe.navigationDirection) == "navigationDirection")
    precondition(assistantEnumToken(probe.pageNavigationSetting) == "pageNavigationSetting")
    precondition(assistantEnumToken(probe.relativeLineSpacingChange) == "relativeLineSpacingChange")
    precondition(assistantEnumToken(probe.relativeWordSpacingChange) == "relativeWordSpacingChange")
    precondition(assistantEnumToken(probe.relativeCharacterSpacingChange) == "relativeCharacterSpacingChange")
    precondition(assistantEnumToken(probe.font) == "font")
    precondition(assistantEnumToken(probe.theme) == "theme")
    precondition(assistantEnumToken(probe.fontSize) == "fontSize")
}

func testAssistantSchemasBooksEntityRequiredParameters() {
    let probe = BooksEntityProbe()
    precondition(assistantEntityToken(probe.book) == "book")
    precondition(assistantEntityToken(probe.settings) == "settings")
    precondition(assistantEntityToken(probe.audiobook) == "audiobook")
}

func testAssistantSchemasBooksIntentRequiredParameters() {
    let probe = BooksIntentProbe()
    precondition(assistantIntentToken(probe.navigatePage) == "navigatePage")
    precondition(assistantIntentToken(probe.playAudiobook) == "playAudiobook")
    precondition(assistantIntentToken(probe.updateFontSize) == "updateFontSize")
    precondition(assistantIntentToken(probe.updateSettings) == "updateSettings")
    precondition(assistantIntentToken(probe.updateLineSpacing) == "updateLineSpacing")
    precondition(assistantIntentToken(probe.updateWordSpacing) == "updateWordSpacing")
    precondition(assistantIntentToken(probe.updateCharacterSpacing) == "updateCharacterSpacing")
    precondition(assistantIntentToken(probe.search) == "search")
    precondition(assistantIntentToken(probe.openBook) == "openBook")
}

func testAssistantSchemasBrowserEnumRequiredParameters() {
    let probe = BrowserEnumProbe()
    precondition(assistantEnumToken(probe.clearHistoryTimeFrame) == "clearHistoryTimeFrame")
}

func testAssistantSchemasBrowserEntityRequiredParameters() {
    let probe = BrowserEntityProbe()
    precondition(assistantEntityToken(probe.tab) == "tab")
    precondition(assistantEntityToken(probe.window) == "window")
    precondition(assistantEntityToken(probe.bookmark) == "bookmark")
}

func testAssistantSchemasBrowserIntentRequiredParameters() {
    let probe = BrowserIntentProbe()
    precondition(assistantIntentToken(probe.findOnPage) == "findOnPage")
    precondition(assistantIntentToken(probe.bookmarkTab) == "bookmarkTab")
    precondition(assistantIntentToken(probe.bookmarkURL) == "bookmarkURL")
    precondition(assistantIntentToken(probe.clearHistory) == "clearHistory")
    precondition(assistantIntentToken(probe.closeWindows) == "closeWindows")
    precondition(assistantIntentToken(probe.createWindow) == "createWindow")
    precondition(assistantIntentToken(probe.openBookmark) == "openBookmark")
    precondition(assistantIntentToken(probe.openURLInTab) == "openURLInTab")
    precondition(assistantIntentToken(probe.deleteBookmarks) == "deleteBookmarks")
    precondition(assistantIntentToken(probe.search) == "search")
    precondition(assistantIntentToken(probe.closeTabs) == "closeTabs")
    precondition(assistantIntentToken(probe.createTab) == "createTab")
    precondition(assistantIntentToken(probe.switchTab) == "switchTab")
}

func testAssistantSchemasFilesEntityRequiredParameters() {
    let probe = FilesEntityProbe()
    precondition(assistantEntityToken(probe.file) == "file")
}

func testAssistantSchemasFilesIntentRequiredParameters() {
    let probe = FilesIntentProbe()
    precondition(assistantIntentToken(probe.moveFiles) == "moveFiles")
    precondition(assistantIntentToken(probe.deleteFiles) == "deleteFiles")
    precondition(assistantIntentToken(probe.renameFile) == "renameFile")
    precondition(assistantIntentToken(probe.createFolder) == "createFolder")
    precondition(assistantIntentToken(probe.openFile) == "openFile")
}

func testAssistantSchemasJournalEntityRequiredParameters() {
    let probe = JournalEntityProbe()
    precondition(assistantEntityToken(probe.entry) == "entry")
}

func testAssistantSchemasJournalIntentRequiredParameters() {
    let probe = JournalIntentProbe()
    precondition(assistantIntentToken(probe.createEntry) == "createEntry")
    precondition(assistantIntentToken(probe.deleteEntry) == "deleteEntry")
    precondition(assistantIntentToken(probe.updateEntry) == "updateEntry")
    precondition(assistantIntentToken(probe.createAudioEntry) == "createAudioEntry")
    precondition(assistantIntentToken(probe.search) == "search")
}

func testAssistantSchemasWhiteboardEnumRequiredParameters() {
    let probe = WhiteboardEnumProbe()
    precondition(assistantEnumToken(probe.color) == "color")
    precondition(assistantEnumToken(probe.itemType) == "itemType")
}

func testAssistantSchemasWhiteboardEntityRequiredParameters() {
    let probe = WhiteboardEntityProbe()
    precondition(assistantEntityToken(probe.item) == "item")
    precondition(assistantEntityToken(probe.board) == "board")
}

func testAssistantSchemasWhiteboardIntentRequiredParameters() {
    let probe = WhiteboardIntentProbe()
    precondition(assistantIntentToken(probe.createItem) == "createItem")
    precondition(assistantIntentToken(probe.deleteItem) == "deleteItem")
    precondition(assistantIntentToken(probe.updateItem) == "updateItem")
    precondition(assistantIntentToken(probe.createBoard) == "createBoard")
    precondition(assistantIntentToken(probe.deleteBoard) == "deleteBoard")
    precondition(assistantIntentToken(probe.updateBoard) == "updateBoard")
    precondition(assistantIntentToken(probe.openBoard) == "openBoard")
}

func testAssistantSchemasSpreadsheetEntityRequiredParameters() {
    let probe = SpreadsheetEntityProbe()
    precondition(assistantEntityToken(probe.sheet) == "sheet")
    precondition(assistantEntityToken(probe.document) == "document")
    precondition(assistantEntityToken(probe.template) == "template")
}

func testAssistantSchemasSpreadsheetIntentRequiredParameters() {
    let probe = SpreadsheetIntentProbe()
    precondition(assistantIntentToken(probe.createSheet) == "createSheet")
    precondition(assistantIntentToken(probe.deleteSheet) == "deleteSheet")
    precondition(assistantIntentToken(probe.updateSheet) == "updateSheet")
    precondition(assistantIntentToken(probe.addAudioToSheet) == "addAudioToSheet")
    precondition(assistantIntentToken(probe.addImageToSheet) == "addImageToSheet")
    precondition(assistantIntentToken(probe.addVideoToSheet) == "addVideoToSheet")
    precondition(assistantIntentToken(probe.addCommentToSheet) == "addCommentToSheet")
    precondition(assistantIntentToken(probe.addTextBoxToSheet) == "addTextBoxToSheet")
    precondition(assistantIntentToken(probe.addWebVideoToSheet) == "addWebVideoToSheet")
    precondition(assistantIntentToken(probe.`open`) == "open")
    precondition(assistantIntentToken(probe.create) == "create")
    precondition(assistantIntentToken(probe.delete) == "delete")
    precondition(assistantIntentToken(probe.update) == "update")
    precondition(assistantIntentToken(probe.openSheet) == "openSheet")
}

func testAssistantSchemasPresentationEntityRequiredParameters() {
    let probe = PresentationEntityProbe()
    precondition(assistantEntityToken(probe.slide) == "slide")
    precondition(assistantEntityToken(probe.document) == "document")
    precondition(assistantEntityToken(probe.template) == "template")
}

func testAssistantSchemasPresentationIntentRequiredParameters() {
    let probe = PresentationIntentProbe()
    precondition(assistantIntentToken(probe.createSlide) == "createSlide")
    precondition(assistantIntentToken(probe.deleteSlide) == "deleteSlide")
    precondition(assistantIntentToken(probe.stopPlayback) == "stopPlayback")
    precondition(assistantIntentToken(probe.setSlideTitle) == "setSlideTitle")
    precondition(assistantIntentToken(probe.startPlayback) == "startPlayback")
    precondition(assistantIntentToken(probe.addAudioToSlide) == "addAudioToSlide")
    precondition(assistantIntentToken(probe.addImageToSlide) == "addImageToSlide")
    precondition(assistantIntentToken(probe.addVideoToSlide) == "addVideoToSlide")
    precondition(assistantIntentToken(probe.addCommentToSlide) == "addCommentToSlide")
    precondition(assistantIntentToken(probe.addTextBoxToSlide) == "addTextBoxToSlide")
    precondition(assistantIntentToken(probe.addWebVideoToSlide) == "addWebVideoToSlide")
    precondition(assistantIntentToken(probe.`open`) == "open")
    precondition(assistantIntentToken(probe.create) == "create")
    precondition(assistantIntentToken(probe.update) == "update")
    precondition(assistantIntentToken(probe.openSlide) == "openSlide")
}

func testAssistantSchemasWordProcessorEntityRequiredParameters() {
    let probe = WordProcessorEntityProbe()
    precondition(assistantEntityToken(probe.page) == "page")
    precondition(assistantEntityToken(probe.document) == "document")
    precondition(assistantEntityToken(probe.template) == "template")
}

func testAssistantSchemasWordProcessorIntentRequiredParameters() {
    let probe = WordProcessorIntentProbe()
    precondition(assistantIntentToken(probe.createPage) == "createPage")
    precondition(assistantIntentToken(probe.addAudioToPage) == "addAudioToPage")
    precondition(assistantIntentToken(probe.addImageToPage) == "addImageToPage")
    precondition(assistantIntentToken(probe.addVideoToPage) == "addVideoToPage")
    precondition(assistantIntentToken(probe.addTextBoxToPage) == "addTextBoxToPage")
    precondition(assistantIntentToken(probe.addWebVideoToPage) == "addWebVideoToPage")
    precondition(assistantIntentToken(probe.`open`) == "open")
    precondition(assistantIntentToken(probe.create) == "create")
    precondition(assistantIntentToken(probe.openPage) == "openPage")
}

func testAssistantSchemasVisualIntelligenceRequiredParameters() {
    let probe = VisualIntelligenceIntentProbe()
    precondition(assistantIntentToken(probe.semanticContentSearch) == "semanticContentSearch")
}

func testAssistantSchemasSystemIntentRequiredParameters() {
    let probe = SystemIntentProbe()
    precondition(assistantIntentToken(probe.search) == "search")
}

