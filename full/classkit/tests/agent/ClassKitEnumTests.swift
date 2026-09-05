import Foundation
import ClassKit

func testEnumRawValues() {
    classKitExpect(CLSBinaryValueType.trueFalse.rawValue == 0, "trueFalse")
    classKitExpect(CLSBinaryValueType.passFail.rawValue == 1, "passFail")
    classKitExpect(CLSBinaryValueType.yesNo.rawValue == 2, "yesNo")
    classKitExpect(CLSBinaryValueType.correctIncorrect.rawValue == 3, "correctIncorrect")
    classKitExpect(CLSBinaryValueType(rawValue: 1) == .passFail, "binary init")
    classKitExpect(CLSBinaryValueType(rawValue: 99) == nil, "binary invalid")
    classKitExpect(CLSBinaryValueType.trueFalse != .yesNo, "binary !=")
    _ = CLSBinaryValueType.passFail.hashValue
    var binaryHasher = Hasher()
    CLSBinaryValueType.yesNo.hash(into: &binaryHasher)
    _ = binaryHasher.finalize()

    let contextCases: [(CLSContextType, Int)] = [
        (.none, 0), (.app, 1), (.chapter, 2), (.section, 3), (.level, 4),
        (.page, 5), (.task, 6), (.challenge, 7), (.quiz, 8), (.exercise, 9),
        (.lesson, 10), (.book, 11), (.game, 12), (.document, 13), (.audio, 14),
        (.video, 15), (.course, 16), (.custom, 17),
    ]
    for (value, raw) in contextCases {
        classKitExpect(value.rawValue == raw, "context \(raw)")
        classKitExpect(CLSContextType(rawValue: raw) == value, "context init \(raw)")
    }
    classKitExpect(CLSContextType(rawValue: 99) == nil, "context invalid")
    classKitExpect(CLSContextType.app != .quiz, "context !=")
    _ = CLSContextType.lesson.hashValue
    var contextHasher = Hasher()
    CLSContextType.course.hash(into: &contextHasher)
    _ = contextHasher.finalize()

    let errorCases: [(CLSError.Code, Int)] = [
        (.none, 0), (.classKitUnavailable, 1), (.invalidArgument, 2),
        (.invalidModification, 3), (.authorizationDenied, 4),
        (.databaseInaccessible, 5), (.limits, 6), (.invalidCreate, 7),
        (.invalidUpdate, 8), (.partialFailure, 9), (.invalidAccountCredentials, 10),
    ]
    for (value, raw) in errorCases {
        classKitExpect(value.rawValue == raw, "error \(raw)")
        classKitExpect(CLSError.Code(rawValue: raw) == value, "error init \(raw)")
    }
    classKitExpect(CLSError.Code(rawValue: 99) == nil, "error invalid")
    _ = CLSError.Code.limits.hashValue
    var codeHasher = Hasher()
    CLSError.Code.partialFailure.hash(into: &codeHasher)
    _ = codeHasher.finalize()

    let kindCases: [(CLSProgressReportingCapability.Kind, Int)] = [
        (.duration, 0), (.percent, 1), (.binary, 2), (.quantity, 3), (.score, 4),
    ]
    for (value, raw) in kindCases {
        classKitExpect(value.rawValue == raw, "kind \(raw)")
        classKitExpect(CLSProgressReportingCapability.Kind(rawValue: raw) == value, "kind init \(raw)")
    }
    classKitExpect(CLSProgressReportingCapability.Kind(rawValue: 99) == nil, "kind invalid")
    classKitExpect(CLSProgressReportingCapability.Kind.duration != .score, "kind !=")
    _ = CLSProgressReportingCapability.Kind.percent.hashValue
    var kindHasher = Hasher()
    CLSProgressReportingCapability.Kind.quantity.hash(into: &kindHasher)
    _ = kindHasher.finalize()
}
