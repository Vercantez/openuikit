import Foundation
import ShazamKit

func testSHSignatureType() {
    let signature = try! SHSignature(dataRepresentation: Data([0x10]))
    precondition(type(of: signature) == SHSignature.self)
}

func testSHSignatureInitData() {
    let data = Data([0x11, 0x12, 0x13])
    let signature = try! SHSignature(dataRepresentation: data)
    precondition(signature.dataRepresentation == data)
}

func testSHSignatureEmptyData() {
    do {
        _ = try SHSignature(dataRepresentation: Data())
        preconditionFailure("empty signature must fail closed")
    } catch {
        precondition(SHError.Code.signatureInvalid ~= error, "expected signatureInvalid, got \(error)")
        return
    }
}

func testSHSignatureDataRepresentation() {
    let data = Data([0x21, 0x22])
    precondition(try! SHSignature(dataRepresentation: data).dataRepresentation == data)
}

func testSHSignatureDuration() {
    precondition(try! SHSignature(dataRepresentation: Data([0x30])).duration == 0)
}

func testSHSignatureInitCoder() {
    precondition(SHSignature(coder: NSCoder()) == nil)
}

func testSHSignatureSlicesEmpty() {
    let signature = try! SHSignature(dataRepresentation: Data([0x40]))
    let slices = try! signature.slices(from: 0, duration: 0)
    precondition(type(of: slices) == SHSignature.Slices.self)
}

func testSHSignatureSlicesInvalid() {
    let signature = try! SHSignature(dataRepresentation: Data([0x41]))
    do {
        _ = try signature.slices(from: 0, duration: 1, stride: 0.5)
        preconditionFailure("opaque signature windows must fail closed")
    } catch {
        precondition(SHError.Code.signatureDurationInvalid ~= error, "expected signatureDurationInvalid, got \(error)")
        return
    }
}

func testSHSignatureSlicesType() {
    _ = SHSignature.Slices.self
}

func testSHSignatureSlicesElement() {
    precondition(SHSignature.Slices.Element.self == SHSignature.self)
}

func testSHSignatureSlicesAsyncIterator() {
    precondition(SHSignature.Slices.AsyncIterator.self == SHSignature.Slices.Iterator.self)
}

func testSHSignatureSlicesMakeAsyncIterator() {
    let slices = try! SHSignature(dataRepresentation: Data([0x42])).slices(from: 0, duration: 0)
    _ = slices.makeAsyncIterator()
}

func testSHSignatureSlicesIteratorType() {
    let iterator = try! SHSignature(dataRepresentation: Data([0x43])).slices(from: 0, duration: 0).makeAsyncIterator()
    precondition(type(of: iterator) == SHSignature.Slices.Iterator.self)
}

func testSHSignatureSlicesIteratorElement() {
    precondition(SHSignature.Slices.Iterator.Element.self == SHSignature.self)
}

func testSHSignatureGeneratorType() {
    precondition(type(of: SHSignatureGenerator()) == SHSignatureGenerator.self)
}

func testSHSignatureGeneratorSignature() {
    let generated = SHSignatureGenerator().signature()
    precondition(generated.dataRepresentation.isEmpty)
    precondition(generated.duration == 0)
}
