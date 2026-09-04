import CoreImage
import Foundation

/// Integration-build probe: import CoreImage and Foundation and pass genuine
/// Foundation values through public CoreImage APIs. The isolated host gate
/// does not compile this file.
func coreImageDependencyIdentityProbe() {
    let payload = Data([0x10, 0x20, 0x30, 0x40])
    precondition(type(of: payload) == Data.self)
    let color = CIColor(string: "1 0 0 1")
    _ = color.stringRepresentation
    let url = URL(fileURLWithPath: "/tmp/coreimage-identity.dng")
    precondition(CIRAWFilter(imageURL: url) == nil)
    precondition(CIImage(data: payload) == nil)
    let vector = CIVector(x: CGFloat(1), y: CGFloat(2))
    precondition(vector.count == 2)
}
