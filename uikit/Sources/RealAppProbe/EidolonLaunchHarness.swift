// Launch boundary for artsy/eidolon 44486ed, not a substitute first screen.
// The app's stored-property initializer constructs its network provider before
// didFinishLaunching. Run this preflight before constructing any app object.
#if canImport(EidolonLaunchCompat)
import EidolonLaunchCompat
#endif

public enum EidolonLaunchHarnessError: Error, CustomStringConvertible {
    case appModuleUnavailable
    public var description: String {
        "Eidolon first screen unavailable: the unchanged app module and its guest dependencies have not compiled. Score N/A."
    }
}

public enum EidolonLaunchHarness {
    /// Refuses before delegate/provider construction. Once the measured build
    /// and transport walls are closed, the real delegate belongs in this closure.
    public static func withLaunchPreflight<Application>(
        _ createApplication: () throws -> Application
    ) throws -> Application {
        #if canImport(EidolonLaunchCompat)
        return try EidolonLaunchCompat.withLaunchPreflight(createApplication)
        #else
        // full/scripts/build_full.sh does not compile these new targets. Native
        // corelibs success must never be passed off as a Mach-O guest launch.
        throw EidolonLaunchHarnessError.appModuleUnavailable
        #endif
    }
}
