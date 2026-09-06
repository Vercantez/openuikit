/* Clang umbrella for the OpenUIKit `os` overlay.
 * Submodules `os.log` and `os.signpost` exist so `import os.log` resolves
 * (MEASURED focus-e2e: SwiftPM target named "os.log" compiles as os_log;
 * NimbusWrapper.swift:5 `import os.log` still failed). Types live in the
 * Swift overlay (Logger.swift / OSLog.swift / Signpost.swift). */
#ifndef OPENUIKIT_OS_H
#define OPENUIKIT_OS_H
#include "log.h"
#include "signpost.h"
#endif
