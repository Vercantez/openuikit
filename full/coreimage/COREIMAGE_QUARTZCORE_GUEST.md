# CoreImage and QuartzCore guest boundaries

The package builds independent ARM64 Mach-O `libCoreImage.dylib` and
`libQuartzCore.dylib` artifacts.  CoreImage is a Swift overlay over a tracked
Clang module map whose explicit `CIFilterBuiltins` submodule makes unchanged
`import CoreImage.CIFilterBuiltins` source resolve.  A pure Swift module cannot
represent that dotted submodule.

The first CoreImage slice implements generated linear gradients and renders
them deterministically into `OpenCoreGraphics.Bitmap`, exported as the first
`CGImage` compatibility identity.  QuartzCore aliases the Core Animation
declarations OpenUIKit already owns.  The aliases preserve identity across
`import UIKit` and `import QuartzCore`; they do not create wrapper layers.

The package compile response includes the CoreImage module map and header
search root.  Removing either input makes the dotted import fail closed.  The
package ledger attests both headers, the module map, both Swift module
families, and both dylibs.
