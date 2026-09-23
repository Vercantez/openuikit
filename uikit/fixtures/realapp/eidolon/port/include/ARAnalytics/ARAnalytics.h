// Kiosk's PodsBridgingHeader.h does `#import <ARAnalytics/ARAnalytics.h>`,
// and six Swift files `import ARAnalytics`. On the port the ARAnalytics API
// is the Swift fail-closed shim (Sources/EidolonServiceShims/ARAnalytics,
// THIRD_PARTY_LICENSES/EidolonServiceInterfaces.md), which Swift imports as
// a module; an Objective-C declaration of the same class here would make
// every `ARAnalytics.event(...)` ambiguous. This header therefore declares
// nothing: it only lets the unmodified bridging header resolve its import.
// (The golden build links the real ARAnalytics 5.0.1 pod with the "-"
// Segment key; ARAnalytics draws no UI.)
#import <Foundation/Foundation.h>
