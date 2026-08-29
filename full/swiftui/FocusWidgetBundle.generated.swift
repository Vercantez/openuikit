// Generated build support for Focus's SwiftPM `Bundle.module` spelling.
//
// This is deliberately NOT application source.  The Foundation-hidden Mach-O
// path has OpenUIKit's identity-only Bundle, so resource bytes are supplied by
// the host through OpenUIKitRuntime.imageSearchPaths.  Keeping this accessor in
// its own file makes that build-system responsibility auditable while the two
// Focus sources compile directly from their pinned checkout, unchanged.

import SwiftUI

extension Bundle {
    static var module: Bundle { .main }
}
