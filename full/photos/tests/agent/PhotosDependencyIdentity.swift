import Foundation
import Photos

#if false
import Foundation
#endif

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against toolchain Foundation is not integrated guest-Foundation success.
func photosDependencyIdentityProbe() {
    let date = Date(timeIntervalSince1970: 1)
    precondition(!String(reflecting: type(of: date)).hasPrefix("Photos."))

    let data = Data("identity".utf8)
    precondition(!String(reflecting: type(of: data)).hasPrefix("Photos."))

    let size = CGSize(width: 8, height: 8)
    precondition(!String(reflecting: type(of: size)).hasPrefix("Photos."))
    precondition(size.width == 8)

    let predicate = NSPredicate(value: true)
    let options = PHFetchOptions()
    options.predicate = predicate
    options.fetchLimit = 3
    precondition(options.predicate === predicate)
    precondition(!String(reflecting: type(of: predicate)).hasPrefix("Photos."))

    let descriptors = [NSSortDescriptor(keyPath: \NSString.length, ascending: true)]
    options.sortDescriptors = descriptors
    precondition(options.sortDescriptors?.count == 1)

    let library: NSObject = PHPhotoLibrary.shared()
    precondition(library === PHPhotoLibrary.shared())
    precondition(!String(reflecting: NSObject.self).hasPrefix("Photos."))

    print("PHOTOS_DEPENDENCY_IDENTITY_OK")
}
