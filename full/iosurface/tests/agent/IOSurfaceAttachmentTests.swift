import Foundation
import IOSurface

func testAttachments() {
    let surface = iosurfaceMakeBGRA(2, 2)
    precondition(surface.allAttachments() == nil)
    surface.setAttachment("hello", forKey: "label")
    precondition((surface.attachment(forKey: "label") as? String) == "hello")
    let all = surface.allAttachments()
    precondition(all?["label"] as? String == "hello")
    surface.removeAttachment(forKey: "label")
    precondition(surface.attachment(forKey: "label") == nil)
}

func testCValueAPI() {
    let surface = iosurfaceMakeBGRA(2, 1)
    IOSurfaceSetValue(surface, kIOSurfaceName, "layer" as NSString)
    let copied = IOSurfaceCopyValue(surface, kIOSurfaceName)
    precondition((copied as? NSString) as String? == "layer")
    let all = IOSurfaceCopyAllValues(surface)
    precondition((all?[kIOSurfaceName] as? NSString) as String? == "layer")
    IOSurfaceRemoveValue(surface, kIOSurfaceName)
    precondition(IOSurfaceCopyValue(surface, kIOSurfaceName) == nil)
}

func testRemoveAll() {
    let surface = iosurfaceMakeBGRA(2, 1)
    surface.setAllAttachments(["a": 1, "b": 2])
    precondition(surface.allAttachments()?.count == 2)
    surface.removeAllAttachments()
    precondition(surface.allAttachments() == nil)
    IOSurfaceSetValues(surface, [kIOSurfaceName: "x"] as NSDictionary)
    precondition(IOSurfaceCopyAllValues(surface) != nil)
    IOSurfaceRemoveAllValues(surface)
    precondition(IOSurfaceCopyAllValues(surface) == nil)
}
