// Foundation reexports the canonical CoreFoundation guest module just as
// Apple's umbrella does. CoreFoundation must be built first from
// corefoundation_guest_sources.txt; defining these types again in Foundation
// would break module-qualified identity checks such as CoreFoundation.CFUUID.

@_exported import CoreFoundation
