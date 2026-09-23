// The guest's Objective-C Foundation: macros, scalar types and runtime
// helpers, spelled as in the iOS 26.1 SDK's <Foundation/NSObjCRuntime.h>.
//
// ONE FOUNDATION. Every class these headers declare is a class of the Swift
// Foundation facade (full/foundation, module Foundation) or of its ObjC
// companion module FoundationObjCBridge (full/objcfoundation/bridge). Each
// @interface carries OF_SWIFT_CLASS(runtime name, Swift module): Objective-C
// code references the Swift class object itself, and Swift code importing an
// Objective-C module resolves the declaration back to the Swift class
// (external_source_symbol), bridging through the facade's own
// _ObjectiveCBridgeable conformances (swift_bridge). No second NSString exists.
#ifndef OF_FOUNDATION_NSOBJCRUNTIME_H
#define OF_FOUNDATION_NSOBJCRUNTIME_H

#include <objc/NSObjCRuntime.h>
#include <objc/objc.h>
#include <stdarg.h>
#include <stdint.h>
#include <limits.h>
#include <float.h>
#include <Availability.h>
#include <TargetConditionals.h>
#include <MacTypes.h>

#if defined(__cplusplus)
#define FOUNDATION_EXTERN extern "C"
#else
#define FOUNDATION_EXTERN extern
#endif
#define FOUNDATION_EXPORT FOUNDATION_EXTERN __attribute__((visibility("default")))
#define FOUNDATION_IMPORT FOUNDATION_EXTERN
#define NS_INLINE static __inline__ __attribute__((always_inline))
#define FOUNDATION_STATIC_INLINE static __inline__

#define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define NS_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#define NS_FORMAT_FUNCTION(F, A) __attribute__((format(__NSString__, F, A)))
#define NS_FORMAT_ARGUMENT(A) __attribute__((format_arg(A)))
#define NS_REQUIRES_NIL_TERMINATION __attribute__((sentinel(0, 1)))
#define NS_RETURNS_RETAINED __attribute__((ns_returns_retained))
#define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
#define NS_RETURNS_INNER_POINTER __attribute__((objc_returns_inner_pointer))
#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#endif
#define NS_NO_TAIL_CALL __attribute__((not_tail_called))
#define NS_UNAVAILABLE __attribute__((unavailable))
#define NS_NOESCAPE __attribute__((noescape))
#define NS_REQUIRES_SUPER __attribute__((objc_requires_super))
#define NS_SWIFT_NAME(N) __attribute__((swift_name(#N)))
#define NS_SWIFT_UNAVAILABLE(M) __attribute__((availability(swift, unavailable, message = M)))
#define NS_REFINED_FOR_SWIFT __attribute__((swift_private))
#define NS_SWIFT_SENDABLE __attribute__((swift_attr("@Sendable")))
// enum_extensibility / flag_enum are what Swift's ClangImporter reads to
// import these as Swift enums and OptionSets (CF_ENUM / CF_OPTIONS in the SDK).
#define NS_ENUM(T, N) enum __attribute__((enum_extensibility(open))) N : T N; enum N : T
#define NS_CLOSED_ENUM(T, N) enum __attribute__((enum_extensibility(closed))) N : T N; enum N : T
#define NS_OPTIONS(T, N) enum __attribute__((flag_enum, enum_extensibility(open))) N : T N; enum N : T
#define NS_ERROR_ENUM(T, N, D) enum __attribute__((ns_error_domain(D), enum_extensibility(open))) N : T N; enum N : T
#define NS_TYPED_ENUM __attribute__((swift_wrapper(enum)))
#define NS_TYPED_EXTENSIBLE_ENUM __attribute__((swift_wrapper(struct)))
#define NS_STRING_ENUM NS_TYPED_ENUM
#define NS_EXTENSIBLE_STRING_ENUM NS_TYPED_EXTENSIBLE_ENUM
#define NS_ROOT_CLASS __attribute__((objc_root_class))
#define NS_AUTOMATED_REFCOUNT_UNAVAILABLE
#define NS_VALID_UNTIL_END_OF_SCOPE __attribute__((objc_precise_lifetime))
#define NS_NONATOMIC_IOSONLY nonatomic
#define API_TO_BE_DEPRECATED 100000
#ifndef NS_AVAILABLE
#define NS_AVAILABLE(M, I)
#endif
#ifndef NS_DEPRECATED
#define NS_DEPRECATED(A, B, C, D, ...)
#endif

// The runtime and Swift module every facade class lives in.
#define OF_SWIFT_CLASS(RUNTIME_NAME, MODULE) \
    __attribute__((objc_runtime_name(RUNTIME_NAME))) \
    __attribute__((external_source_symbol(language = "Swift", defined_in = MODULE, generated_declaration)))

typedef double NSTimeInterval;
#define NSTimeIntervalSince1970 978307200.0

typedef NS_ENUM(NSInteger, NSComparisonResult) {
    NSOrderedAscending = -1L,
    NSOrderedSame,
    NSOrderedDescending
};

typedef NSComparisonResult (^NSComparator)(id obj1, id obj2);

typedef NS_OPTIONS(NSUInteger, NSEnumerationOptions) {
    NSEnumerationConcurrent = (1UL << 0),
    NSEnumerationReverse = (1UL << 1),
};

typedef NS_OPTIONS(NSUInteger, NSSortOptions) {
    NSSortConcurrent = (1UL << 0),
    NSSortStable = (1UL << 4),
};

@class NSString, Protocol;

// Swift sees the facade's own spellings of these (Foundation.NSNotFound, ...),
// so the Clang declarations are Objective-C/C only: importing both would make
// every Swift use ambiguous. __swift__ is defined by Swift's ClangImporter.
#if !defined(__swift__)
static const NSInteger NSNotFound = NSIntegerMax;

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *NSStringFromSelector(SEL aSelector);
FOUNDATION_EXPORT SEL NSSelectorFromString(NSString *aSelectorName);
FOUNDATION_EXPORT NSString *NSStringFromClass(Class aClass);
FOUNDATION_EXPORT Class _Nullable NSClassFromString(NSString *aClassName);
FOUNDATION_EXPORT NSString *NSStringFromProtocol(Protocol *proto);
FOUNDATION_EXPORT Protocol * _Nullable NSProtocolFromString(NSString *namestr);
FOUNDATION_EXPORT void NSLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2) NS_NO_TAIL_CALL;
FOUNDATION_EXPORT void NSLogv(NSString *format, va_list args) NS_FORMAT_FUNCTION(1, 0) NS_NO_TAIL_CALL;
NS_ASSUME_NONNULL_END
#endif

#endif
