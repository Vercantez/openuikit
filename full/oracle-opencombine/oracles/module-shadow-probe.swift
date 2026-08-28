#if canImport(Combine)
#error("isolated inputs unexpectedly expose Combine")
#endif

#if canImport(OpenCombine)
#error("isolated inputs unexpectedly expose OpenCombine")
#endif

struct ModuleShadowProbe {}
