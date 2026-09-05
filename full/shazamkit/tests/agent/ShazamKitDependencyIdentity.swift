import Foundation
import ShazamKit

func shazamKitDependencyIdentityProbe() {
    let payload = Data([0x4F, 0x4B, 0x31])
    let signature = try! SHSignature(dataRepresentation: payload)
    precondition(signature.dataRepresentation == payload)
    let item = SHMediaItem(properties: [
        .title: "Foundation",
        .creationDate: Date(timeIntervalSince1970: 0),
        .webURL: URL(string: "https://example.com")!,
    ])
    precondition(item.title == "Foundation")
    precondition(item.creationDate == Date(timeIntervalSince1970: 0))
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(signature, representing: [item])
    precondition(!catalog.dataRepresentation.isEmpty)
}
