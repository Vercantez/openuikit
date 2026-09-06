import Foundation
import Assignables

func assignablesExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("Assignables test failed: \(message)")
    }
}

func assignablesMakeDocument(_ id: String = "doc-1") -> AssignableDocument {
    try! AssignableDocument(id: id, partData: [:])
}

func assignablesPageID(_ raw: String) -> AssignableDocument.Page.ID {
    try! JSONDecoder().decode(AssignableDocument.Page.ID.self, from: Data("\"\(raw)\"".utf8))
}

func assignablesWorkPageID(_ raw: String) -> AssignedWorkDocument.Page.ID {
    try! JSONDecoder().decode(AssignedWorkDocument.Page.ID.self, from: Data("\"\(raw)\"".utf8))
}
