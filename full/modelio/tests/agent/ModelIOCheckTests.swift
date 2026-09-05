import Foundation
import ModelIO

func mdlCheck(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func mdlNear(_ a: Float, _ b: Float, eps: Float = 1e-4) -> Bool {
    abs(a - b) < eps
}

func mdlVec3Near(_ a: SIMD3<Float>, _ b: SIMD3<Float>, eps: Float = 1e-3) -> Bool {
    mdlNear(a.x, b.x, eps: eps) && mdlNear(a.y, b.y, eps: eps) && mdlNear(a.z, b.z, eps: eps)
}

func mdlTempDir() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("modelio-tests-\(UUID().uuidString)", isDirectory: true)
}

func mdlHashAndRaw<T: Hashable & RawRepresentable>(_ value: T, expected: T.RawValue, label: String)
where T.RawValue: Equatable {
    mdlCheck(value.rawValue == expected, "\(label) rawValue")
    mdlCheck(T(rawValue: expected) == value, "\(label) init(rawValue:)")
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = value.hashValue
}
