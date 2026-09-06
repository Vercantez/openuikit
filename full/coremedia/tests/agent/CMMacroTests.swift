import CoreMedia

func testCMCoreMediaMacroConstants() {
    precondition(CMITEMCOUNT_MAX == Int.max)
    precondition(COREMEDIA_TRUE == true)
    precondition(COREMEDIA_FALSE == false)
    precondition(COREMEDIA_DECLARE_BRIDGED_TYPES == true)
    precondition(COREMEDIA_DECLARE_NULLABILITY == true)
    precondition(COREMEDIA_DECLARE_NULLABILITY_BEGIN_END == true)
    precondition(COREMEDIA_DECLARE_RELEASES_ARGUMENT == true)
    precondition(COREMEDIA_DECLARE_RETURNS_NOT_RETAINED_ON_PARAMETERS == true)
    precondition(COREMEDIA_DECLARE_RETURNS_RETAINED == true)
    precondition(COREMEDIA_DECLARE_RETURNS_RETAINED_BLOCK == true)
    precondition(COREMEDIA_DECLARE_RETURNS_RETAINED_ON_PARAMETERS == true)
    precondition(COREMEDIA_USE_DERIVED_ENUMS_FOR_CONSTANTS == true)
    precondition(COREMEDIA_CMBASECLASS_VERSION_IS_POINTER_ALIGNED == true)
    precondition(COREMEDIA_USE_ALIGNED_CMBASECLASS_VERSION == true)
    precondition(COREMEDIA_EXPORTS_USE_EXPLICIT_VISIBILITY == 0)
    precondition(CMTIMEBASE_USE_SOURCE_TERMINOLOGY == 0)
}
