#ifndef OPEN_FOUNDATION_CFERROR_H
#define OPEN_FOUNDATION_CFERROR_H

/*
 * The portable Foundation facade needs the canonical Clang-imported
 * CFErrorRef identity in order to publish Swift's Foundation-owned Error
 * conformance.  Keep this substrate intentionally opaque: the current
 * portable CoreFoundation runtime does not implement the CFError C accessor
 * family, and Foundation's toll-free NSError bridge must not acquire eager
 * references to those absent functions.
 */
typedef struct __CFError *CFErrorRef;

#endif /* OPEN_FOUNDATION_CFERROR_H */
