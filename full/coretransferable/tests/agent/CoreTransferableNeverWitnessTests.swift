import Foundation
@_spi(OpenUIKitHost) import CoreTransferable

// Witness references for the three Transferable/TransferRepresentation
// members synthesized onto Never. Never is uninhabited, so no Never value
// can be produced without a trapping call: invoking withExportedFile would
// trap in the Never.transferRepresentation getter, and the suggestedFileName
// wrappers need a Never item to forward. These tests pin each overload by
// forming a typed reference through a helper whose parameter types select
// exactly one overload, matching the existing testNeverProtocolWitnessesExist
// standard used by the other Never witness rows.

private func swallowNeverWitness<T>(_ value: T) {
    _ = String(describing: type(of: value))
}

private func neverConstantName(_ base: Never, _ name: String) -> Any {
    base.suggestedFileName(name)
}

private func neverClosureName(
    _ base: Never,
    _ provider: @escaping @Sendable (Never) -> String?
) -> Any {
    base.suggestedFileName(provider)
}

func testNeverSuggestedFileNameStringWitness() {
    swallowNeverWitness(neverConstantName(_:_:))
}

func testNeverSuggestedFileNameClosureWitness() {
    swallowNeverWitness(neverClosureName(_:_:))
}

func testNeverWithExportedFileWitness() {
    let witness: (Never) -> (UTType?, (URL) async throws -> Data) async throws -> Data =
        Never.withExportedFile(contentType:fileHandler:)
    swallowNeverWitness(witness)
}
