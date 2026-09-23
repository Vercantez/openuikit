/* ios_availability.c -- `#available(iOS x, *)` for executables built for an
 * iOS-simulator TARGET (docs/agent_reports/ios-target-route.md).
 *
 * Linked by full/scripts/build_full.sh into every executable when
 * LINK_PLATFORM=ios-simulator; a strong local definition, so the
 * executable's own availability checks resolve here instead of binding to
 * libswiftcompat.dylib, whose `__isPlatformVersionAtLeast` answers yes to
 * everything ("we emulate a full deployment target", swiftcore-macho
 * sdk/compat/swiftcompat.c). That policy is right for the macOS-triple guest,
 * which never claims an OS version; on the iOS triple it made
 * `if #available(iOS 27.0, *)` true.
 *
 * MEASURED (full/iostarget/oracle-ios26.1.txt, iPhone 16 / iOS 26.1
 * simulator): 26.0 yes, 26.1 yes, 26.2 no, 27.0 no. Before this file the
 * guest printed yes for all four. The guest presents the OS the goldens are
 * captured on, iOS 26.1.0, which is also the SDK version every iOS-triple
 * guest carries in LC_BUILD_VERSION.
 *
 * Platforms: clang passes 2 (iOS) for ios and ios-simulator targets; 7
 * (iOS simulator) is accepted too. Any other platform keeps the old answer.
 * Dylibs other than the executable still bind libswiftcompat (open).
 */
#include <stdint.h>

#define MR_PLATFORM_IOS 2u
#define MR_PLATFORM_IOSSIMULATOR 7u
#define MR_IOS_MAJOR 26u
#define MR_IOS_MINOR 1u
#define MR_IOS_SUBMINOR 0u

int32_t __isPlatformVersionAtLeast(uint32_t platform, uint32_t major,
                                   uint32_t minor, uint32_t subminor);

int32_t __isPlatformVersionAtLeast(uint32_t platform, uint32_t major,
                                   uint32_t minor, uint32_t subminor)
{
    if (platform != MR_PLATFORM_IOS && platform != MR_PLATFORM_IOSSIMULATOR)
        return 1;
    if (major != MR_IOS_MAJOR) return major < MR_IOS_MAJOR;
    if (minor != MR_IOS_MINOR) return minor < MR_IOS_MINOR;
    return subminor <= MR_IOS_SUBMINOR;
}
