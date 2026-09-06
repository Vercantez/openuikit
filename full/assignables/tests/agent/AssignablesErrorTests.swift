import Foundation
import Assignables

func testAnyUserIdentityCannotDecode() {
    assignablesExpect(
        AnyUserIdentity.Error.cannotDecode == AnyUserIdentity.Error.cannotDecode,
        "eq"
    )
    _ = AnyUserIdentity.Error.cannotDecode.hashValue
    var hasher = Hasher()
    AnyUserIdentity.Error.cannotDecode.hash(into: &hasher)
    _ = hasher.finalize()
    let payload = Data(#"{"typeID":"unknown.example","stringRepresentation":"x"}"#.utf8)
    do {
        _ = try JSONDecoder().decode(AnyUserIdentity.self, from: payload)
        assignablesExpect(false, "should throw")
    } catch AnyUserIdentity.Error.cannotDecode {
        assignablesExpect(true, "cannotDecode")
    } catch {
        assignablesExpect(false, "wrong error \(error)")
    }
    assignablesExpect(
        AnyUserIdentity.Error.cannotDecode.localizedDescription.isEmpty == false,
        "localized"
    )
}

func testAssignableDocumentErrors() {
    do {
        _ = try AssignableDocument(pdfURL: URL(fileURLWithPath: "/tmp/missing.pdf"), id: "x")
        assignablesExpect(false, "pdf init should fail")
    } catch AssignableDocument.Error.invalidURL {
        assignablesExpect(true, "invalidURL")
    } catch {
        assignablesExpect(false, "wrong \(error)")
    }

    do {
        _ = try AssignableDocument(
            pdfURL: URL(fileURLWithPath: "/tmp/missing.pdf"),
            authors: [AnonymousUserIdentity()],
            id: nil
        )
        assignablesExpect(false, "pdf authors init should fail")
    } catch AssignableDocument.Error.invalidURL {
        assignablesExpect(true, "invalidURL authors")
    } catch {
        assignablesExpect(false, "wrong authors \(error)")
    }

    var doc = assignablesMakeDocument("a")
    let other = assignablesMakeDocument("b")
    do {
        _ = try doc.merge(other: other)
        assignablesExpect(false, "merge variant")
    } catch AssignableDocument.Error.otherDocumentIsNotAVariant {
        assignablesExpect(true, "not a variant")
    } catch {
        assignablesExpect(false, "wrong merge \(error)")
    }

    let failed = AssignableDocument.Error.exportFailed(partIDs: [AssignableDocument.PartIDs.base])
    if case .exportFailed(let ids) = failed {
        assignablesExpect(ids == [AssignableDocument.PartIDs.base], "export ids")
    } else {
        assignablesExpect(false, "export case")
    }
    assignablesExpect(AssignableDocument.Error.invalidURL.localizedDescription.isEmpty == false, "loc")
    assignablesExpect(
        AssignableDocument.Error.invalidURL != .otherDocumentIsNotAVariant,
        "neq"
    )
}

func testAssignedWorkDocumentErrors() {
    var work = try! assignablesMakeDocument("w").makeAssignedWorkDocument(id: "work-1")
    let other = try! assignablesMakeDocument("w2").makeAssignedWorkDocument(id: "work-2")
    do {
        _ = try work.merge(other: other)
        assignablesExpect(false, "work variant")
    } catch AssignedWorkDocument.Error.otherDocumentIsNotAVariant {
        assignablesExpect(true, "not a variant")
    } catch {
        assignablesExpect(false, "wrong \(error)")
    }
    let failed = AssignedWorkDocument.Error.exportFailed(
        partIDs: [AssignedWorkDocument.PartIDs.takerMarkup]
    )
    if case .exportFailed(let ids) = failed {
        assignablesExpect(ids.first == AssignedWorkDocument.PartIDs.takerMarkup, "ids")
    } else {
        assignablesExpect(false, "case")
    }
    assignablesExpect(
        AssignedWorkDocument.Error.otherDocumentIsNotAVariant.localizedDescription.isEmpty == false,
        "loc"
    )
}
