import Foundation
import Assignables

func testAsyncIdentityScope() {
    let identity = AnyUserIdentity(StringUserIdentity(value: "async-scope"))
    let value = try! assignablesAwait {
        try await identity.scope { () async throws -> String in identity.stringRepresentation }
    }.get()
    assignablesExpect(value == "async-scope", "async identity scope")

    let generic = try! assignablesAwait {
        try await StringUserIdentity(value: "generic-scope").scope {
            () async throws -> String in "generic"
        }
    }.get()
    assignablesExpect(generic == "generic", "generic async scope")
}

func testAssignableAsyncInitialization() {
    let document = try! assignablesAwait {
        try await AssignableDocument(id: "async-init", partData: [:])
    }.get()
    assignablesExpect(document.id == "async-init", "async init id")
    assignablesExpect(document.pages.count == 1, "async init page")
}

func testAssignableAsyncMerge() {
    let changed = try! assignablesAwait {
        var document = assignablesMakeDocument("async-merge")
        var other = assignablesMakeDocument("async-merge")
        other.authors = [AnyUserIdentity(StringUserIdentity(value: "author"))]
        return try await document.merge(other)
    }.get()
    assignablesExpect(changed, "async document merge")
}

func testAssignableAsyncPartMerge() {
    let changed = try! assignablesAwait {
        var document = assignablesMakeDocument("async-part-merge")
        return try await document.merge(
            partData: .data(Data("[]".utf8)),
            into: AssignableDocument.PartIDs.authors
        )
    }.get()
    assignablesExpect(changed, "async part merge")
}

func testAssignableAsyncExports() {
    let counts = try! assignablesAwait {
        let document = assignablesMakeDocument("async-export")
        let ids = [AssignableDocument.PartIDs.authors, AssignableDocument.PartIDs.questionBoxes]
        let parts = try await document.exportParts(identifiedBy: ids)
        let files = try await document.export(partIDs: ids)
        return [parts.count, files.count]
    }.get()
    assignablesExpect(counts == [2, 2], "async exports")
}

func testAssignableFailClosedRendering() {
    let values = try! assignablesAwait {
        let document = assignablesMakeDocument("render")
        let pdf = await document.exportToPDF(visibleParts: [AssignableDocument.PartIDs.base])
        let base = await document.exportBaseAsPDF()
        let pages = await document.pageThumbnails(visibleParts: [AssignableDocument.PartIDs.base])
        let questions = await document.questionThumbnails(visibleParts: [AssignableDocument.PartIDs.base])
        return [pdf.pageCount, base.pageCount, pages.count, questions.count]
    }.get()
    assignablesExpect(values == [0, 0, 0, 0], "rendering must fail closed")
}

func testWorkAsyncInitialization() {
    let work = try! assignablesAwait {
        try await AssignedWorkDocument(
            id: "async-work", assignableDocument: assignablesMakeDocument("source"), partData: [:]
        )
    }.get()
    assignablesExpect(work.id == "async-work", "async work init")
}

func testWorkAsyncMerge() {
    let changed = try! assignablesAwait {
        var work = try assignablesMakeDocument("work-source").makeAssignedWorkDocument(id: "work")
        var other = try assignablesMakeDocument("work-source").makeAssignedWorkDocument(id: "work")
        other.scorers = [AnyUserIdentity(AnonymousUserIdentity())]
        return try await work.merge(other)
    }.get()
    assignablesExpect(changed, "async work merge")
}

func testWorkAsyncPartMerge() {
    let changed = try! assignablesAwait {
        var work = try assignablesMakeDocument().makeAssignedWorkDocument(id: "async-work-part")
        return try await work.merge(
            partData: .data(Data("[]".utf8)), into: AssignedWorkDocument.PartIDs.scorers
        )
    }.get()
    assignablesExpect(changed, "async work part merge")
}

func testWorkAsyncExports() {
    let counts = try! assignablesAwait {
        let work = try assignablesMakeDocument().makeAssignedWorkDocument(id: "work-export")
        let ids = [AssignedWorkDocument.PartIDs.assignees, AssignedWorkDocument.PartIDs.scorers]
        let parts = try await work.exportParts(identifiedBy: ids)
        let files = try await work.export(partIDs: ids)
        return [parts.count, files.count]
    }.get()
    assignablesExpect(counts == [2, 2], "work exports")
}

func testWorkFailClosedRendering() {
    let values = try! assignablesAwait {
        let work = try assignablesMakeDocument().makeAssignedWorkDocument(id: "work-render")
        let ids = [AssignedWorkDocument.PartIDs.takerMarkup]
        let pdf = await work.exportToPDF(visibleParts: ids)
        let pages = await work.pageThumbnails(visibleParts: ids)
        let questions = await work.questionThumbnails(visibleParts: ids)
        return [pdf.pageCount, pages.count, questions.count]
    }.get()
    assignablesExpect(values == [0, 0, 0], "work rendering must fail closed")
}
