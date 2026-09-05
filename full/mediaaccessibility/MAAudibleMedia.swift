import CoreFoundation
import Foundation

/// Descriptive audio preferences. Linux has no system audible-media
/// setting, so the preferred-characteristic list is empty.
public func MAAudibleMediaCopyPreferredCharacteristics() -> Unmanaged<CFArray> {
    _maPassArray([])
}
