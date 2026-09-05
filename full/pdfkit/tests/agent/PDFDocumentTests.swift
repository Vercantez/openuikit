@_spi(PDFKitTesting) import PDFKit
import Foundation

func testDocumentAttributesAndPermissions() {
    let empty = PDFDocument()
    pdfkitExpect(empty.pageCount == 0, "empty document has no pages")
    pdfkitExpect(empty.allowsCopying, "unlocked document allows copying")
    pdfkitExpect(empty.accessPermissions.contains(.allowsCommenting), "accessPermissions bits")
    pdfkitExpect(empty.allowsPrinting, "unlocked document allows printing")
    pdfkitExpect(empty.allowsCommenting, "commenting")
    pdfkitExpect(empty.allowsContentAccessibility, "a11y")
    pdfkitExpect(empty.allowsDocumentAssembly, "assembly")
    pdfkitExpect(empty.allowsDocumentChanges, "changes")
    pdfkitExpect(empty.allowsFormFieldEntry, "form")
    pdfkitExpect(empty.permissionsStatus == .owner, "new document is owner-permissioned")
    pdfkitExpect(empty.majorVersion == 1 && empty.minorVersion == 4, "default version")
    pdfkitExpect(empty.unlock(withPassword: "secret") == false, "empty unlock fail-closed")
    pdfkitExpect(empty.documentURL == nil, "no url")
    pdfkitExpect(empty.isEncrypted == false, "not encrypted")
    pdfkitExpect(empty.isLocked == false, "not locked")
    pdfkitExpect(empty.isFinding == false, "not finding")
    _ = empty.delegate
    _ = empty.pageClass
    empty.documentAttributes = [
        PDFDocumentAttribute.titleAttribute: "In-memory",
        PDFDocumentAttribute.authorAttribute: "Agent",
        PDFDocumentAttribute.keywordsAttribute: ["pdf", "kit"]
    ]
    pdfkitExpect(empty.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "In-memory", "title")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    pdfkitExpect(sample?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "Runtime Probe", "info title")
    pdfkitExpect(sample?.documentAttributes?[PDFDocumentAttribute.producerAttribute] as? String == "OpenUIKit PDFKit", "producer")
}

func testDocumentPageTreeMutations() {
    let empty = PDFDocument()
    let page = PDFPage()
    pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "default media box width")
    page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
    page.setBounds(CGRect(x: 10, y: 10, width: 380, height: 480), for: .cropBox)
    empty.insert(page, at: 0)
    pdfkitExpect(empty.pageCount == 1, "inserted page")
    pdfkitExpect(empty.page(at: 0) === page, "page(at:) identity")
    pdfkitExpect(empty.index(for: page) == 0, "index(for:)")
    pdfkitExpect(page.label == "1", "page label")
    pdfkitExpect(page.document === empty, "page.document")
    pdfkitExpect(page.bounds(for: .cropBox).width == 380, "crop box")

    let second = PDFPage()
    empty.insert(second, at: 1)
    pdfkitExpect(empty.pageCount == 2, "second page")
    empty.exchangePage(at: 0, withPageAt: 1)
    pdfkitExpect(empty.page(at: 0) === second, "exchange")
    empty.removePage(at: 0)
    pdfkitExpect(empty.pageCount == 1, "remove page")
    pdfkitExpect(empty.page(at: 0) === page, "remaining page")
    pdfkitExpect(empty.page(at: 9) == nil, "out of range")
}

func testDocumentPageTreeInheritance() {
    let inheritBuilder = PDFFixtureBuilder()
    let (inheritStream, _) = pdfkitHelloStream()
    pdfkitStandardPageTree(builder: inheritBuilder, contents: inheritStream, inheritBoxes: true)
    let inherited = PDFDocument(data: inheritBuilder.finish(root: 2, info: 1))
    pdfkitExpect(inherited?.page(at: 0)?.bounds(for: .mediaBox).width == 200, "inherited MediaBox")
    pdfkitExpect(inherited?.page(at: 0)?.rotation == 90, "inherited Rotate")
    pdfkitExpect(PDFKitTesting.resourceKeyCount(for: inherited!.page(at: 0)!) >= 1, "inherited Resources")
    pdfkitExpect(inherited?.string?.contains("Hello PDFKit") == true, "inherited resources still extract")

    let fixture = pdfkitRequireCommittedFixture("inherited-boxes.pdf")
    let fromFixture = PDFDocument(data: fixture)
    pdfkitExpect(fromFixture?.page(at: 0)?.bounds(for: .mediaBox).width == 200, "fixture inherited MediaBox")
    pdfkitExpect(fromFixture?.page(at: 0)?.rotation == 90, "fixture inherited Rotate")
}

func testDocumentWriteRoundTripAndOptions() {
    let empty = PDFDocument()
    let page = PDFPage()
    empty.insert(page, at: 0)
    empty.documentAttributes = [PDFDocumentAttribute.titleAttribute: "In-memory"]
    let serialized = empty.dataRepresentation()
    pdfkitExpect(serialized != nil, "serialize in-memory document")
    pdfkitExpect(String(data: serialized!, encoding: .isoLatin1)?.hasPrefix("%PDF-") == true, "serialized header")
    pdfkitExpect(PDFKitTesting.parseStatus(serialized!) == "ok", "writer xref parses")
    let writerAgain = PDFDocument(data: serialized!)?.dataRepresentation()
    pdfkitExpect(serialized == writerAgain, "writer re-read byte identity")
    pdfkitExpect(empty.dataRepresentation(options: [:]) != nil, "empty options")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let tempRoot = pdfkitMakeTempRoot()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let tempURL = tempRoot.appendingPathComponent("roundtrip.pdf")
    pdfkitExpect(sample?.write(to: tempURL) == true, "write(to:)")
    pdfkitExpect(sample?.write(toFile: tempURL.path) == true, "write(toFile:)")
    let fromURL = PDFDocument(url: tempURL)
    pdfkitExpect(fromURL?.pageCount == 1, "init(url:) page count")
    pdfkitExpect(fromURL?.documentURL == tempURL, "documentURL")
    pdfkitExpect(fromURL?.string?.contains("Hello PDFKit") == true, "url reload text")
    let fromURLAlias = PDFDocument(URL: tempURL)
    pdfkitExpect(fromURLAlias?.pageCount == 1, "init(URL:) alias")
    pdfkitExpect(fromURL?.write(to: tempURL, withOptions: [.ownerPasswordOption: "x"]) == false, "password write refused")
    pdfkitExpect(fromURL?.write(toFile: tempURL.path, withOptions: [.userPasswordOption: "x"]) == false, "file password refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.userPasswordOption: "x"]) == nil, "password data refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: true]) == nil, "burn-in refused")
    pdfkitExpect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.saveTextFromOCROption: true]) == nil, "ocr refused")

    let fixtureData = pdfkitRequireCommittedFixture("minimal.pdf")
    let fixtureDoc = PDFDocument(data: fixtureData)
    pdfkitExpect(fixtureDoc?.dataRepresentation() == fixtureData, "committed fixture unmutated round-trip")
}

func testDocumentEncryptionTrailerAndStandardHandler() {
    let encryptBuilder = PDFFixtureBuilder()
    encryptBuilder.add(1, "<< /Title (Locked) >>")
    encryptBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    encryptBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    encryptBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] >>")
    encryptBuilder.add(9, "<< /Filter /Standard /V 1 /R 2 /P -4 >>")
    let encryptData = encryptBuilder.finish(root: 2, info: 1, extraTrailer: "/Encrypt 9 0 R")
    pdfkitExpect(PDFKitTesting.parseStatus(encryptData) == "encrypted", "trailer Encrypt")
    let locked = PDFDocument(data: encryptData)
    pdfkitExpect(locked?.isEncrypted == true, "encrypt flag")
    pdfkitExpect(locked?.isLocked == true, "locked flag")
    pdfkitExpect(locked?.unlock(withPassword: "secret") == false, "wrong password stays locked")
    pdfkitExpect(locked?.pageCount == 0, "encrypted content withheld until unlock")
    pdfkitExpect(locked?.dataRepresentation() == nil, "locked document does not write")
    let tempRoot = pdfkitMakeTempRoot()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    pdfkitExpect(locked?.write(to: tempRoot.appendingPathComponent("locked.pdf")) == false, "locked write fails")

    let catalogEncrypt = PDFFixtureBuilder()
    let (catalogStream, _) = pdfkitHelloStream()
    catalogEncrypt.add(1, "<< /Title (Not Encrypted) >>")
    catalogEncrypt.add(2, "<< /Type /Catalog /Pages 3 0 R /Encrypt 9 0 R >>")
    catalogEncrypt.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    catalogEncrypt.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    catalogEncrypt.add(5, catalogStream)
    pdfkitExpect(
        PDFKitTesting.parseStatus(catalogEncrypt.finish(root: 2, info: 1)) == "ok",
        "Encrypt only in catalog is not trailer encryption"
    )

    let encryptInStream = PDFFixtureBuilder()
    let (encryptInStreamBody, _) = pdfkitHelloStream(extraInStream: "\n/Encrypt")
    pdfkitStandardPageTree(builder: encryptInStream, contents: encryptInStreamBody)
    pdfkitExpect(
        PDFKitTesting.parseStatus(encryptInStream.finish(root: 2, info: 1)) == "ok",
        "/Encrypt bytes outside the trailer dictionary are not encryption"
    )

    let encryptedData = PDFKitTesting.standardEncryptedHello(userPassword: "user")
    pdfkitExpect(PDFKitTesting.parseStatus(encryptedData) == "encrypted", "standard handler locked")
    let encryptedDoc = PDFDocument(data: encryptedData)
    pdfkitExpect(encryptedDoc?.isEncrypted == true, "standard encrypted")
    pdfkitExpect(encryptedDoc?.isLocked == true, "standard locked")
    pdfkitExpect(encryptedDoc?.unlock(withPassword: "wrong") == false, "wrong user password")
    pdfkitExpect(encryptedDoc?.unlock(withPassword: "user") == true, "user password Algorithm 6")
    pdfkitExpect(encryptedDoc?.isLocked == false, "unlocked")
    pdfkitExpect(encryptedDoc?.pageCount == 1, "pages after unlock")
    pdfkitExpect(encryptedDoc?.string?.contains("Hello PDFKit") == true, "decrypted text")
}

func testDocumentFindAndDelegate() {
    final class FindSpy: NSObject, PDFDocumentDelegate {
        var began = 0
        var ended = 0
        var matches = 0
        var unlocked = 0
        func didMatchString(_ instance: PDFSelection) {
            _ = instance
            matches += 1
        }
        func documentDidBeginDocumentFind(_ notification: Notification) {
            _ = notification
            began += 1
        }
        func documentDidEndDocumentFind(_ notification: Notification) {
            _ = notification
            ended += 1
        }
        func documentDidUnlock(_ notification: Notification) {
            _ = notification
            unlocked += 1
        }
    }

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    pdfkitExpect(sample != nil, "sample")
    let spy = FindSpy()
    sample?.delegate = spy
    let matches = sample?.findString("PDFKit", withOptions: []) ?? []
    pdfkitExpect(matches.count == 1, "findString count")
    pdfkitExpect(matches.first?.string?.contains("PDFKit") == true, "findString text")
    let nextFromMatch = sample?.findString("PDFKit", fromSelection: matches.first, withOptions: [])
    pdfkitExpect(nextFromMatch == nil, "no later PDFKit match")
    let ellMatches = sample?.findString("l", withOptions: []) ?? []
    pdfkitExpect(ellMatches.count >= 2, "multiple letter matches")
    let laterEll = sample?.findString("l", fromSelection: ellMatches.first, withOptions: [])
    pdfkitExpect(laterEll != nil, "find next on same page")
    pdfkitExpect(laterEll?.string == "l", "next match text")

    sample?.beginFindString("Hello", withOptions: [])
    pdfkitExpect(sample?.isFinding == false, "synchronous find finished")
    pdfkitExpect(spy.began == 1, "delegate begin")
    pdfkitExpect(spy.ended == 1, "delegate end")
    pdfkitExpect(spy.matches >= 1, "delegate match")
    sample?.beginFindStrings(["Hello"], withOptions: [])
    sample?.cancelFindString()
    pdfkitExpect(sample?.isFinding == false, "cancel")
    _ = spy.classForPage()
    _ = spy.class(forAnnotationType: "Highlight")
    spy.documentDidBeginPageFind(Notification(name: .PDFDocumentDidBeginPageFind))
    spy.documentDidEndPageFind(Notification(name: .PDFDocumentDidEndPageFind))
    spy.documentDidFindMatch(Notification(name: .PDFDocumentDidFindMatch))
}
