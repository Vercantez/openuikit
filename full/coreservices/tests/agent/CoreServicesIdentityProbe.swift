import CoreServices
import Foundation

// Staged Foundation aliases CFString to String. These assignments are the
// exact representable public queries. They are not a CoreFoundation lookalike
// and they do not stand in for Unmanaged Copy/Create.
let equal: (String, String) -> Bool = UTTypeEqual
let conforms: (String, String) -> Bool = UTTypeConformsTo
let isDeclared: (String) -> Bool = UTTypeIsDeclared
let isDynamic: (String) -> Bool = UTTypeIsDynamic

precondition(equal(kUTTypePNG, "public.png"))
precondition(conforms(kUTTypePNG, kUTTypeImage))
precondition(isDeclared(kUTTypePNG))
precondition(!isDynamic(kUTTypePNG))
precondition(isDynamic("dyn.example"))
precondition(kUTTypePNG == "public.png")
precondition(kUTTagClassFilenameExtension == "public.filename-extension")

print("CORESERVICES_CF_IDENTITY_OK")
print("CORESERVICES_UNMANAGED_SURFACE_BLOCKED")
