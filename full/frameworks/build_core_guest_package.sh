#!/usr/bin/env bash
# Build a cold, relocatable ARM64 Mach-O core-framework package for unchanged
# application sources. Run inside the pinned Linux/arm64 production image with
# fresh build/cache/root paths. The production host wrapper gates publication
# on exact pre/post content manifests for every other replay input.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

W=${W:-/w}
MACHORUN=${MACHORUN:-/machorun}
TARGET=arm64-apple-macos15.0
MIN_OS=15.0
SYS=$W/scratch/sysroot_fe4
FULL=$W/build/full
WORK=$W/build/core-guest-work
MRROOT=$W/scratch/mrroot_full
BUILD_FULL_CACHE=$W/scratch/modcache_full
BUILD_FE_CACHE=$W/scratch/modcache_fe4
SWIFT_FOUNDATION=$W/scratch/swift-foundation
SWIFT_FOUNDATION_ICU=$W/scratch/swift-foundation-icu
SWIFT_COLLECTIONS=$W/scratch/swift-collections
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_SOURCE=$OPENCOMBINE_ROOT/source
OPENCOMBINE_ARTIFACTS=$OPENCOMBINE_ROOT/export/artifacts
OPENCOMBINE_HELPERS=$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers
MANIFEST_TOOL=$W/full/frameworks/core_package_manifest.py
FOUNDATION_SOURCES_MANIFEST=$W/full/foundation/foundation_guest_sources.txt
COPEN_FOUNDATION_CORE_INCLUDE=$W/full/foundation/include/COpenFoundationCore
FOUNDATION_CACHE_ORACLE=$W/full/foundation/tests/FoundationCacheOracle.swift
FOUNDATION_CACHE_GOLDEN=$W/full/foundation/tests/foundation-cache-apple-2026-08-31.txt
FOUNDATION_BYTE_COUNT_ORACLE=$W/full/foundation/tests/FoundationByteCountFormatterOracle.swift
FOUNDATION_BYTE_COUNT_GOLDEN=$W/full/foundation/tests/foundation-byte-count-apple-2026-08-31.txt
OBSERVATION_SOURCES_MANIFEST=$W/full/observation/observation_guest_sources.txt
FOUNDATION_INTERNATIONALIZATION_BUILDER=$W/full/foundationinternationalization/build_foundation_internationalization.sh
INTENTS_SOURCES_MANIFEST=$W/full/intents/intents_guest_sources.txt
INTENTSUI_SOURCES_MANIFEST=$W/full/intentsui/intentsui_guest_sources.txt
WEBKIT_SOURCES_MANIFEST=$W/full/webkit/webkit_guest_sources.txt
HACKERS_WEBKIT_SURFACE=$W/full/webkit/tests/HackersWebKitSurface.swift
COREIMAGE_SOURCES_MANIFEST=$W/full/coreimage/coreimage_guest_sources.txt
QUARTZCORE_SOURCES_MANIFEST=$W/full/quartzcore/quartzcore_guest_sources.txt
SWIFTDATA_SOURCES_MANIFEST=$W/full/swiftdata/swiftdata_guest_sources.txt
QUICKLOOK_SWIFTUI_SOURCES_MANIFEST=$W/full/quicklook/quicklook_swiftui_guest_sources.txt
PHOTOSUI_SWIFTUI_SOURCES_MANIFEST=$W/full/photosui/photosui_swiftui_guest_sources.txt
AUTHENTICATIONSERVICES_SWIFTUI_SOURCES_MANIFEST=$W/full/authenticationservices/authenticationservices_swiftui_guest_sources.txt
WEBKIT_PROVENANCE_TOOL=$W/full/webkit/webkit_provenance.py
WEBKIT_PROVENANCE_POLICY=$W/full/webkit/webkit-provenance.json
ACCELERATE_ORACLE=$W/full/accelerate/tests/AccelerateBoxConvolveOracle.c
ACCELERATE_GOLDEN=$W/full/accelerate/tests/accelerate-box-convolve-apple-2026-09-01.txt
COMPRESSION_HOST_TEST=$W/full/compression/tests/OpenCompressionHostTests.c
CORETEXT_ORACLE=$W/full/coretext/tests/CoreTextFontManagerOracle.swift
CORETEXT_GOLDEN=$W/full/coretext/tests/coretext-font-manager-apple-2026-09-01.txt
ADSERVICES_ORACLE=$W/full/adservices/tests/AdServicesInterfaceOracle.swift
ADSERVICES_GOLDEN=$W/full/adservices/tests/adservices-interface-apple-2026-09-01.txt
ZLIB_ORACLE=$W/full/zlib/tests/ZlibGzipOracle.swift
ZLIB_GOLDEN=$W/full/zlib/tests/zlib-gzip-apple-2026-09-01.txt
ZLIB_HOST_TEST=$W/full/zlib/tests/OpenZlibHostTests.c
IOKIT_ORACLE=$W/full/iokit/tests/IOKitInterfaceOracle.swift
IOKIT_GOLDEN=$W/full/iokit/tests/iokit-interface-apple-2026-09-01.txt
IOKIT_PORTABLE_GOLDEN=$W/full/iokit/tests/iokit-interface-portable-2026-09-01.txt
IOKIT_HOST_TEST=$W/full/iokit/tests/IOKitHostTests.c
SWIFT_IOKIT_EXPORTS=$W/full/iokit/tests/libswiftIOKit-apple-2026-09-01.exports
SWIFT_IOKIT_HOST_TEST=$W/full/iokit/tests/OpenSwiftIOKitHostTests.c
APPKIT_SOURCES_MANIFEST=$W/full/appkit/appkit_guest_sources.txt
SWIFTUI_APPKIT_SOURCES_MANIFEST=$W/full/appkit/swiftui_appkit_guest_sources.txt
APPKIT_ORACLE=$W/full/appkit/tests/AppKitInterfaceOracle.swift
APPKIT_GOLDEN=$W/full/appkit/tests/appkit-interface-apple-xcode-26.1.txt
APPKIT_LOAD_IDENTITIES=$W/full/appkit/tests/appkit-load-identities.txt
FIRST_PARTY_PROVENANCE_TOOL=$W/full/first-party-frameworks/first_party_provenance.py
FIRST_PARTY_PROVENANCE_POLICY=$W/full/first-party-frameworks/first-party-provenance.json
SDK_DANGLING_EXCLUSIONS=$W/full/frameworks/sdk_dangling_symlink_exclusions.tsv
OUTPUT_ROOT=''
EXPECTED_SUPPORT_COMMIT=''
EXPECTED_SUPPORT_TREE=''
UIKIT=''
EXPECTED_UIKIT_COMMIT=''
EXPECTED_UIKIT_TREE=''
EXPECTED_MACHORUN_SWIFT_CORE_SHA256=''
EXPECTED_MACHORUN_OBJC_SHA256=''
DEVELOPER_TOOLS_SUPPORT_MODULE=''
DEVELOPER_TOOLS_SUPPORT_OBJECT=''
PREVIEW_MACRO_PLUGIN=''

FIRST_PARTY_FRAMEWORKS=(
    LocalAuthentication
    SafariServices
    Network
    StoreKit
    AudioToolbox
    CoreHaptics
    PassKit
    CoreGraphics
    ImageIO
    LinkPresentation
    MessageUI
    MobileCoreServices
    Security
    CryptoKit
    CommonCrypto
    AppIntents
    WidgetKit
    OSLog
    UniformTypeIdentifiers
    SwiftData
    UserNotifications
    BackgroundTasks
    CoreSpotlight
    QuickLook
    CoreMedia
    AVFoundation
    AVKit
    Charts
    CoreTransferable
    Photos
    PhotosUI
    Accelerate
    Compression
    CoreText
    AdServices
    NaturalLanguage
    AuthenticationServices
    FoundationModels
)
FIRST_PARTY_SOURCE_DIRS=(
    localauthentication
    safariservices
    network
    storekit
    audiotoolbox
    corehaptics
    passkit
    coregraphics
    imageio
    linkpresentation
    messageui
    mobilecoreservices
    security
    cryptokit
    commoncrypto
    appintents
    widgetkit
    oslog
    uniformtypeidentifiers
    swiftdata
    usernotifications
    backgroundtasks
    corespotlight
    quicklook
    coremedia
    avfoundation
    avkit
    charts
    coretransferable
    photos
    photosui
    accelerate
    compression
    coretext
    adservices
    naturallanguage
    authenticationservices
    foundationmodels
)
FRONTIER_FRAMEWORKS=(
    CoreGraphics
    ImageIO
    LinkPresentation
    MessageUI
    MobileCoreServices
    Security
    CryptoKit
    CommonCrypto
    AppIntents
    WidgetKit
    OSLog
    UniformTypeIdentifiers
    SwiftData
    UserNotifications
    BackgroundTasks
    CoreSpotlight
    QuickLook
    CoreMedia
    AVFoundation
    AVKit
    Charts
    CoreTransferable
    Photos
    PhotosUI
    Accelerate
    Compression
    CoreText
    AdServices
    NaturalLanguage
    AuthenticationServices
    FoundationModels
)
FRONTIER_SOURCE_DIRS=(
    coregraphics
    imageio
    linkpresentation
    messageui
    mobilecoreservices
    security
    cryptokit
    commoncrypto
    appintents
    widgetkit
    oslog
    uniformtypeidentifiers
    swiftdata
    usernotifications
    backgroundtasks
    corespotlight
    quicklook
    coremedia
    avfoundation
    avkit
    charts
    coretransferable
    photos
    photosui
    accelerate
    compression
    coretext
    adservices
    naturallanguage
    authenticationservices
    foundationmodels
)

EXPECTED_SUPPORT_BASE=af37dd231dd5a31866c0c94a04a85679b0821eff
EXPECTED_UIKIT_SWIFT_COUNT=105
EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT=12
EXPECTED_SYMBOLS_SWIFT_COUNT=1
EXPECTED_SWIFTUI_SWIFT_COUNT=11
EXPECTED_DEVELOPER_TOOLS_SUPPORT_SWIFT_COUNT=1
EXPECTED_OPENUIKIT_PREVIEW_MACROS_SWIFT_COUNT=2
EXPECTED_OPENSWIFTUI_MACROS_SWIFT_COUNT=2
EXPECTED_CQUARTZ_CPP_COUNT=37
EXPECTED_FOUNDATION_SOURCE_COUNT=33
EXPECTED_OBSERVATION_SOURCE_COUNT=6
EXPECTED_INTENTS_SOURCE_COUNT=1
EXPECTED_INTENTSUI_SOURCE_COUNT=1
EXPECTED_WEBKIT_SOURCE_COUNT=5
EXPECTED_HACKERS_WEBKIT_SURFACE_SHA256=fa5ac0e8d8a72453d604cc5a8f24a8a8e9a771249115f569b2cd5b31422f194c
EXPECTED_COREIMAGE_SOURCE_COUNT=1
EXPECTED_QUARTZCORE_SOURCE_COUNT=1
EXPECTED_SWIFTDATA_SOURCE_COUNT=2
EXPECTED_QUICKLOOK_SWIFTUI_SOURCE_COUNT=1
EXPECTED_PHOTOSUI_SWIFTUI_SOURCE_COUNT=1
EXPECTED_AUTHENTICATIONSERVICES_SWIFTUI_SOURCE_COUNT=1
EXPECTED_COREMEDIA_SOURCE_COUNT=1
EXPECTED_AVFOUNDATION_SOURCE_COUNT=1
EXPECTED_AVKIT_SOURCE_COUNT=1
EXPECTED_CHARTS_SOURCE_COUNT=1
EXPECTED_WIDGETKIT_SOURCE_COUNT=1
EXPECTED_CORETRANSFERABLE_SOURCE_COUNT=1
EXPECTED_PHOTOS_SOURCE_COUNT=1
EXPECTED_PHOTOSUI_SOURCE_COUNT=1
EXPECTED_NATURALLANGUAGE_SOURCE_COUNT=1
EXPECTED_AUTHENTICATIONSERVICES_SOURCE_COUNT=1
EXPECTED_APPKIT_SOURCE_COUNT=1
EXPECTED_SWIFTUI_APPKIT_SOURCE_COUNT=1
EXPECTED_APPKIT_EXPORT_COUNT=198
EXPECTED_APPKIT_EXPORT_SHA=dd9b850d2dcf4deb398752a950248a229b4374c40fa948727fa13ef9f50a2b15
EXPECTED_APPKIT_IMPORT_SHA=58c8c02cadac24ec680699924a8e4bcc7701562519242e74316b752b048195a4
EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS=19
EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS=2
EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS=0
EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS=2
EXPECTED_FOUNDATION_COMMIT=c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc
EXPECTED_FOUNDATION_TREE=4651798679b98e27383ca3626434fb128f191486
EXPECTED_FOUNDATION_ICU_COMMIT=87dbab99780e277b6a4c2a397ab1a894f877b39a
EXPECTED_FOUNDATION_ICU_TREE=823a4a2a13f60a0fd2715db85a754dda11d5fd39
EXPECTED_FOUNDATION_INTL_SWIFT_COUNT=61
EXPECTED_FOUNDATION_ICU_CPP_COUNT=474
EXPECTED_FOUNDATION_ICU_HEADER_COUNT=205
EXPECTED_COLLECTIONS_COMMIT=9bf03ff58ce34478e66aaee630e491823326fd06
EXPECTED_COLLECTIONS_TREE=5e4de96f40ccf147dab967f38cb7988ecd933c27
EXPECTED_OPENCOMBINE_COMMIT=1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b
EXPECTED_OPENCOMBINE_TREE=66a9d91efc910c7577e40b2dec166a2de427594a
EXPECTED_MACHORUN_COMMIT=98551893760e553c14d5dbb2c28138e014290918
EXPECTED_MACHORUN_TREE=d4448ff9f8a89c5cefad8b74f16db5d8d6ccff15
EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA=0d8680f13e023c9f002fad78f1f0382c975f479595cd8cf3fa8eb6da3c42d29b
SWIFT_CORE_REQUIRED_AVAILABILITY_SYMBOL='_$ss042_stdlib_isOSVersionAtLeastOrVariantVersiondE0yBi1_Bw_BwBwBwBwBwtF'
EXPECTED_MACHORUN_GROUP_FIXTURE_SHA=d90194ae586e14f652435e4764d4b13d338be53b95da10cf73df4d1955895624
EXPECTED_MACHORUN_GROUP_GOLDEN_SHA=671c6a3487332fa71c9fa398de9015b37f38f97978a0ebcdd66fdce69f5562d4
EXPECTED_MACHORUN_GROUP_SOURCE_SHA=940c48317d4d782aaf61193f54b1a1ac216a7fa2ef718b0f3957f55889c661c3
EXPECTED_MACHORUN_XATTR_FIXTURE_SHA=08505e9ba4da6dc21a6eea360a8583b3fa2460020e6ed881a7ffefe6f8527ed7
EXPECTED_MACHORUN_XATTR_GOLDEN_SHA=5e9d15742e594d5cf2b8bb767629a6e0a5acaae33bdb0fa591c9b535dd3f734f
EXPECTED_MACHORUN_XATTR_SOURCE_SHA=9603c5296d343769fbe3b0889623511d69a59498700483d3bc523404919f5c00
EXPECTED_MACHORUN_FTS_FIXTURE_SHA=dfdfb829fc3030367bec2be71c36e7524f49a0cc19dca67dfb6add54be24e2fb
EXPECTED_MACHORUN_FTS_GOLDEN_SHA=4450fd565645e269e1aadbebb0932fc97415360ba867668e143890d418119756
EXPECTED_MACHORUN_FTS_STDERR_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_MACHORUN_FTS_EXIT_SHA=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
EXPECTED_MACHORUN_FTS_SOURCE_SHA=dcd6ce46373dcbbf3fd9b6b413ce4f1bd2ee561bd9cb6c1d20065a62b86d7f05
EXPECTED_MACHORUN_FTS_SUMMARY_SHA=87a60c1363f50ecaf9ba08108fd6ab0a03cde70c14449ad8c7f7c44edb677670
EXPECTED_MACHORUN_FTS_LIBSYSTEM_SOURCE_SHA=$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA
EXPECTED_MACHORUN_STATFS_FIXTURE_SHA=723da2ef92cc06456c909b947950427420f1ce51ba61d71a5c5815555699970a
EXPECTED_MACHORUN_STATFS_GOLDEN_SHA=a60e1cc80da7e784a05268a1e8a5e8a895a0b89f1d6d728a8674b13b74a1871f
EXPECTED_MACHORUN_STATFS_STDERR_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_MACHORUN_STATFS_EXIT_SHA=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
EXPECTED_MACHORUN_STATFS_SOURCE_SHA=86a32bb57849992c8b2ef51a3b493d834fab988c119fdc9c4fcbd61c8ef038b9
EXPECTED_MACHORUN_STATFS_SUMMARY_SHA=452aac764d0c73cfdb5fa3974dac358447a00a6d4dcea703bf0e6dc629705db6
EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA=$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA
EXPECTED_MACHORUN_COPYFILE_FIXTURE_SHA=d1c2bce67013ba40f389907580c7cc87a86203e651c813e2bc068f369c4e9d2a
EXPECTED_MACHORUN_COPYFILE_GOLDEN_SHA=d467e161e746a4bebd07f0b8bba12fa68914e59b5ef345fed6fa808bdaf6bd86
EXPECTED_MACHORUN_COPYFILE_STDERR_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_MACHORUN_COPYFILE_EXIT_SHA=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
EXPECTED_MACHORUN_COPYFILE_SOURCE_SHA=e8407a7753a447c89c2f93513f3ce06282020fff820169011f8dc643314b1c2b
EXPECTED_MACHORUN_COPYFILE_SUMMARY_SHA=ced87f863ec09d0793d89641867a26e46219dbded8251e99dd824fa823e4efda
EXPECTED_MACHORUN_COPYFILE_LIBSYSTEM_SOURCE_SHA=$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA
EXPECTED_MACHORUN_COPYFILE_XATTR_GATE_SHA=23cf9bf53f83196fcb17515fe42bbd2654df5354cc24573d22a87cc712b3a7ca
EXPECTED_MACHORUN_QUOTA_FIXTURE_SHA=8275f9be13889cd44bf96f6442f61fb742ca8756061b0bfc285ff75d782f4d8d
EXPECTED_MACHORUN_QUOTA_GOLDEN_SHA=13ee8b893730f6f8e9bff25be80562359006648b167d0c94c6bb9eb6ee7d2a18
EXPECTED_MACHORUN_QUOTA_SOURCE_SHA=2707bdd1692fb8623328bb7d663ccc83573a314168ccd39b1787b412cc839070
EXPECTED_MACHORUN_UNAME_FIXTURE_SHA=a5f6ea4ca57c74ac1cbcf1205f36ea82eeada909b903bb66ffbf547e6281357b
EXPECTED_MACHORUN_UNAME_GOLDEN_SHA=45a2dc5584efcb12c0f28d3ebbdd080f233453302b91177208e014a5b21163a4
EXPECTED_MACHORUN_UNAME_SOURCE_SHA=e552d0b9959a639c09501fecfab90d70a568f8672d930481a44dcf51cafe5578
EXPECTED_PREVIEW_SWIFTSYNTAX_REVISION=4799286537280063c85a32f09884cfbca301b1a1
PREVIEW_EXECUTABLE_EXPORT_SYMBOL='_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC'
EXPECTED_OBSERVATION_UPSTREAM_COMMIT=ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b
OBSERVATION_MACRO_PLUGIN=/usr/lib/swift/host/plugins/libObservationMacros.so
EXPECTED_OBSERVATION_PLUGIN_SHA=ea6510afdd0a9e4808229c52441e9a67ca24e8ce186fccfd082547a5ee1c1229
FOUNDATION_MACRO_PLUGIN=/usr/lib/swift/host/plugins/libFoundationMacros.so
EXPECTED_FOUNDATION_PLUGIN_SHA=babded9fc050d13aed1d1716e668a6fae7748fea13f49ec0b1087b0fb7f65fd4

OBSERVATION_SOURCE_HASHES=(
    a679f8ccd75265030d6cd28b81cb49e810bc97e8d9c42c78626cce7c3ea66b2d
    6668a4dc827c6b7019fd650383999ffe113f0f40807e7bfa0093d25eb4e64406
    bf533652129e87ad16918ba05c27a63ef4ceb3c84ca5f69ccc2d6745811e389b
    20b28faff988b6195598f90990d0ca9b5f6a38054f9ea213d266d11c3d3ba898
    e14626b87d2b1c305333e916f998f5a9d587789336bf7d98235e94b29f4baea4
    f597674fe55b4ddc3d22a6cab27e25baffb06c7fbe403cd686af74be615a5757
)
OBSERVATION_PLUGIN_HOST_LIBS=(
    libSwiftSyntaxMacros.so
    libSwiftSyntaxBuilder.so
    libSwiftParserDiagnostics.so
    libSwiftBasicFormat.so
    libSwiftParser.so
    libSwiftDiagnostics.so
    libSwiftSyntax.so
)
OBSERVATION_PLUGIN_HOST_HASHES=(
    bd32b50e01ae49aefbb8a4cb73c0f53284f6e38d8f5b5e9cf5704ea928de4435
    06a02fa8a9af26796c6238396ba73412bbb08f799238a7ea144a5d68c2eda971
    3109239e809fa5e81bd2c9d5e216948bb31f655b8ea05d32dc319f0da30bc077
    c652ba5f52686d740452389a8f5ab13dca808d898aea83927351ef00548eab0d
    ddbadfc8edb5a94fd2edc23cf3d560b97ad2ced6cbcefec8fcdf3add1dad8390
    f350546755ba25a725e89f8e993d1ca2edb83629de2a2a4b5268f83b5d0485b6
    d4aee0018bfb7103e09c281d3e3c5eead335f4a01581fb62063b3994e51ac440
)
OBSERVATION_PLUGIN_LINUX_LIBS=(
    libswiftCore.so
    libswift_Concurrency.so
    libswiftGlibc.so
    libdispatch.so
    libswift_Builtin_float.so
    libBlocksRuntime.so
    libswiftSwiftOnoneSupport.so
    libswift_StringProcessing.so
    libswift_RegexParser.so
)
OBSERVATION_PLUGIN_LINUX_HASHES=(
    8fdbbfbf6cda36870e97fe46af2bf21eff39253d97e878aaae003f5be0127f92
    42a70f4bef727842b6a949feceb260996adb1c6ee3b7c2d424dfa0419f4b949e
    003f47955f3744ba1277704add2431f1c58b82ab07b9d91b5809bec1b877857e
    39e502b3a8b016073947574a932172c1dafff8c41abd15b9b9f11bef7aaf1b6b
    62e2a42b1a98c56af695b154cbd01892d5c64acda3ee376950d960057d7c68af
    47a4f774ed1f4c094f8510c50d0006fde89a837ae785236e2ed669b8db9d002d
    f0cb31b7c80b93bb0e848cbb631a07ba0997d70c908c9bff2f90b1d64592dee7
    5a0365eda46c207fa588e08e8c863d6c34ad6d988e261e5539781a93dc2d9541
    6cfdce2d756f761b11df923e6458a8095ad3dd9909bb7cc74381e930be1e12c9
)

EXPECTED_OPENCOMBINE_RESULT=c6fe4fa173f27fad0e30d1931c5ffead0aa267d55730a5885c1142bc7502b104
EXPECTED_OPENCOMBINE_OBJECT=96558e7d31c10c4bc769e9774977b74c58dc6ee83cfbd4fca8bf17229424a914
EXPECTED_OPENCOMBINE_MODULE=674d4d049d09b074b303822a88fcdc2c1d12c1e3cca9c9414ca30a74ee2c9de0
EXPECTED_OPENCOMBINE_DOC=a5a2757d33ccb621d26aea0f8ca417cf8ba748660faf1cf37eba53c5833975bc
EXPECTED_OPENCOMBINE_HELPER=73dbadeff3f6cebb9f5c57e09380e3166b65e68f0b0427d97d6a8ffdce693693
EXPECTED_OPENCOMBINE_HEADER=eb2afa8d9b46891a47ac39e43a4f94d727120acdbc0644934296c4c4ca62e935
EXPECTED_OPENCOMBINE_MODULEMAP=d34fdd050111a8cbf5ced89a129088fcfeb2964eea76ad518fafe044966572d1
EXPECTED_OPENCOMBINE_PATCH=875cd931e95c5442775e1042a412517ab7475be0489b1a81f824a54f6872c79b
EXPECTED_OPENCOMBINE_PATCHED_HELPER=d9fbefcdba66d892d9064c46b21b6084af217ddec1d604bcaf27b160de66083b
EXPECTED_COMBINE_SHIM=828b05c3a47296fb7b0b9ed5a6ca1a45a5da46e245441c21028335f60511799f
SYSTEM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
BOLD_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
EXPECTED_SYSTEM_FONT=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
EXPECTED_BOLD_FONT=5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895
HOST_DISPATCH_SOURCE=/usr/lib/swift/linux/libdispatch.so
HOST_BLOCKS_RUNTIME_SOURCE=/usr/lib/swift/linux/libBlocksRuntime.so
EXPECTED_HOST_DISPATCH_SHA256=39e502b3a8b016073947574a932172c1dafff8c41abd15b9b9f11bef7aaf1b6b
EXPECTED_HOST_BLOCKS_RUNTIME_SHA256=47a4f774ed1f4c094f8510c50d0006fde89a837ae785236e2ed669b8db9d002d
EXPECTED_FOUNDATION_CACHE_ORACLE_SHA256=9a3479d559d4ba6c979868e6f34254547b13158c087319d78b72f177f88749a3
EXPECTED_FOUNDATION_CACHE_GOLDEN_SHA256=0dd1fab4b09c76dfe6ab6fc07ac93d9350cf3bb19d31c7d8524c2df8e59e441c
EXPECTED_FOUNDATION_BYTE_COUNT_ORACLE_SHA256=c5565bd04a7451f3ef828e3cc928718ce095fa5d2bdf2b41d8c40541e15f4616
EXPECTED_FOUNDATION_BYTE_COUNT_GOLDEN_SHA256=1390be735b11d92409e81bb9e04115502bed76bd830daa440fde7377cb4773c0

usage() {
    cat <<'EOF'
usage: build_core_guest_package.sh --output-root /w/build/NEW_NAME \
    --expected-support-commit COMMIT --expected-support-tree TREE \
    --uikit-checkout PATH --expected-uikit-commit COMMIT \
    --expected-uikit-tree TREE [options]

Required:
  --output-root PATH
  --expected-support-commit 40_HEX
  --expected-support-tree 40_HEX
  --uikit-checkout PATH
  --expected-uikit-commit 40_HEX
  --expected-uikit-tree 40_HEX
  --expected-machorun-swift-core-sha256 64_HEX
  --expected-machorun-objc-sha256 64_HEX

Foundation source contract:
  --foundation-sources-manifest PATH
      Defaults to /w/full/foundation/foundation_guest_sources.txt.

Optional Preview contract (all three or none):
  --developer-tools-support-module PATH
  --developer-tools-support-object PATH
  --preview-macro-plugin PATH

The output must not exist. It must be a direct child of /w/build. The final
package never contains the host macro plugin; it records its hash/ELF/toolchain
identity and publishes an external-plugin load specification instead.
EOF
}

die() {
    echo "core_guest_package: REFUSING -- $*" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --output-root)
            [ "$#" -ge 2 ] || die '--output-root requires a value'
            OUTPUT_ROOT=$2; shift 2 ;;
        --expected-support-commit)
            [ "$#" -ge 2 ] || die '--expected-support-commit requires a value'
            EXPECTED_SUPPORT_COMMIT=$2; shift 2 ;;
        --expected-support-tree)
            [ "$#" -ge 2 ] || die '--expected-support-tree requires a value'
            EXPECTED_SUPPORT_TREE=$2; shift 2 ;;
        --uikit-checkout)
            [ "$#" -ge 2 ] || die '--uikit-checkout requires a value'
            UIKIT=$2; shift 2 ;;
        --expected-uikit-commit)
            [ "$#" -ge 2 ] || die '--expected-uikit-commit requires a value'
            EXPECTED_UIKIT_COMMIT=$2; shift 2 ;;
        --expected-uikit-tree)
            [ "$#" -ge 2 ] || die '--expected-uikit-tree requires a value'
            EXPECTED_UIKIT_TREE=$2; shift 2 ;;
        --expected-machorun-swift-core-sha256)
            [ "$#" -ge 2 ] \
                || die '--expected-machorun-swift-core-sha256 requires a value'
            EXPECTED_MACHORUN_SWIFT_CORE_SHA256=$2; shift 2 ;;
        --expected-machorun-objc-sha256)
            [ "$#" -ge 2 ] \
                || die '--expected-machorun-objc-sha256 requires a value'
            EXPECTED_MACHORUN_OBJC_SHA256=$2; shift 2 ;;
        --foundation-sources-manifest)
            [ "$#" -ge 2 ] || die '--foundation-sources-manifest requires a value'
            FOUNDATION_SOURCES_MANIFEST=$2; shift 2 ;;
        --developer-tools-support-module)
            [ "$#" -ge 2 ] || die '--developer-tools-support-module requires a value'
            DEVELOPER_TOOLS_SUPPORT_MODULE=$2; shift 2 ;;
        --developer-tools-support-object)
            [ "$#" -ge 2 ] || die '--developer-tools-support-object requires a value'
            DEVELOPER_TOOLS_SUPPORT_OBJECT=$2; shift 2 ;;
        --preview-macro-plugin)
            [ "$#" -ge 2 ] || die '--preview-macro-plugin requires a value'
            PREVIEW_MACRO_PLUGIN=$2; shift 2 ;;
        --help|-h)
            usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[ -n "$OUTPUT_ROOT" ] || die '--output-root is required'
[ -n "$EXPECTED_SUPPORT_COMMIT" ] || die '--expected-support-commit is required'
[ -n "$EXPECTED_SUPPORT_TREE" ] || die '--expected-support-tree is required'
[ -n "$UIKIT" ] || die '--uikit-checkout is required'
[ -n "$EXPECTED_UIKIT_COMMIT" ] || die '--expected-uikit-commit is required'
[ -n "$EXPECTED_UIKIT_TREE" ] || die '--expected-uikit-tree is required'
[ -n "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256" ] \
    || die '--expected-machorun-swift-core-sha256 is required'
[ -n "$EXPECTED_MACHORUN_OBJC_SHA256" ] \
    || die '--expected-machorun-objc-sha256 is required'
case "$UIKIT" in /*) ;; *) die '--uikit-checkout must be absolute' ;; esac
for expected_git_id in "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" \
    "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE"; do
    [ "${#expected_git_id}" -eq 40 ] \
        || die 'expected UIKit commit/tree must each be lowercase 40-hex'
    case "$expected_git_id" in
        *[!0-9a-f]*) die 'expected UIKit commit/tree must each be lowercase 40-hex' ;;
    esac
done
[ "${#EXPECTED_MACHORUN_SWIFT_CORE_SHA256}" -eq 64 ] \
    || die 'expected machorun Swift core SHA-256 must be lowercase 64-hex'
case "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256" in
    *[!0-9a-f]*) \
        die 'expected machorun Swift core SHA-256 must be lowercase 64-hex' ;;
esac
[ "${#EXPECTED_MACHORUN_OBJC_SHA256}" -eq 64 ] \
    || die 'expected machorun Objective-C runtime SHA-256 must be lowercase 64-hex'
case "$EXPECTED_MACHORUN_OBJC_SHA256" in
    *[!0-9a-f]*) \
        die 'expected machorun Objective-C runtime SHA-256 must be lowercase 64-hex' ;;
esac
case "$OUTPUT_ROOT" in
    /*) ;;
    *) die '--output-root must be absolute' ;;
esac
[ "$(dirname "$OUTPUT_ROOT")" = "$W/build" ] \
    || die '--output-root must be a direct child of /w/build'
case "$OUTPUT_ROOT" in
    *'/../'*|*'/./'*|*'//'*) die '--output-root is not normalized' ;;
esac
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output root already exists: $OUTPUT_ROOT"

preview_count=0
[ -n "$DEVELOPER_TOOLS_SUPPORT_MODULE" ] && preview_count=$((preview_count + 1))
[ -n "$DEVELOPER_TOOLS_SUPPORT_OBJECT" ] && preview_count=$((preview_count + 1))
[ -n "$PREVIEW_MACRO_PLUGIN" ] && preview_count=$((preview_count + 1))
[ "$preview_count" -eq 0 ] || [ "$preview_count" -eq 3 ] \
    || die 'Preview inputs are all-or-none'
PREVIEW_ENABLED=0
[ "$preview_count" -eq 3 ] && PREVIEW_ENABLED=1

for tool in git swiftc clang-18 clang++-18 ld64.lld-18 llvm-otool-18 \
    llvm-nm-18 perl python3 patch sha256sum cmp file readelf ldd curl-config \
    pkg-config find sort; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[ -x "$MANIFEST_TOOL" ] || die "manifest tool is missing or not executable: $MANIFEST_TOOL"
[ -x "$WEBKIT_PROVENANCE_TOOL" ] \
    || die "WebKit provenance tool is missing or not executable: $WEBKIT_PROVENANCE_TOOL"
[ -f "$WEBKIT_PROVENANCE_POLICY" ] && [ ! -L "$WEBKIT_PROVENANCE_POLICY" ] \
    || die "WebKit provenance policy is missing or linked: $WEBKIT_PROVENANCE_POLICY"
[ -x "$FIRST_PARTY_PROVENANCE_TOOL" ] \
    || die "first-party provenance tool is missing or not executable: $FIRST_PARTY_PROVENANCE_TOOL"
[ -f "$FIRST_PARTY_PROVENANCE_POLICY" ] && [ ! -L "$FIRST_PARTY_PROVENANCE_POLICY" ] \
    || die "first-party provenance policy is missing or linked: $FIRST_PARTY_PROVENANCE_POLICY"
[ -x "$MACHORUN/build/machorun" ] || die 'current machorun input is missing'
[ -d "$SYS/usr/include" ] || die "SDK is missing: $SYS"
[ -f "$COPEN_FOUNDATION_CORE_INCLUDE/OpenFoundationCFError.h" ] \
    && [ ! -L "$COPEN_FOUNDATION_CORE_INCLUDE/OpenFoundationCFError.h" ] \
    || die 'COpenFoundationCore CFError header is missing'
[ -f "$COPEN_FOUNDATION_CORE_INCLUDE/module.modulemap" ] \
    && [ ! -L "$COPEN_FOUNDATION_CORE_INCLUDE/module.modulemap" ] \
    || die 'COpenFoundationCore module map is missing'
[ -d "$W/build" ] && [ ! -L "$W/build" ] || die '/w/build must be a real directory'
[ ! -e "$FULL" ] && [ ! -L "$FULL" ] || die "stale build_full output exists: $FULL"
[ ! -e "$WORK" ] && [ ! -L "$WORK" ] || die "stale core work root exists: $WORK"
for fresh in "$MRROOT" "$BUILD_FULL_CACHE" "$BUILD_FE_CACHE"; do
    if [ -e "$fresh" ] || [ -L "$fresh" ]; then
        [ -d "$fresh" ] && [ ! -L "$fresh" ] || die "fresh root is not a real directory: $fresh"
        [ -z "$(find "$fresh" -mindepth 1 -maxdepth 1 -print -quit)" ] \
            || die "fresh root is not empty: $fresh"
    fi
done

mkdir -p "$WORK"
STAGE=$(mktemp -d "$W/build/.core-guest-package.INCOMPLETE.XXXXXX")
SUCCESS=0
quarantine_on_exit() {
    local status=$?
    trap - EXIT
    if [ "$SUCCESS" -ne 1 ]; then
        local partial=''
        if [ -d "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ]; then
            partial=$OUTPUT_ROOT
        elif [ -d "$STAGE" ] && [ ! -L "$STAGE" ]; then
            partial=$STAGE
        fi
        if [ -n "$partial" ]; then
            local invalid=${OUTPUT_ROOT}.INVALID-DO-NOT-USE
            [ ! -e "$invalid" ] || invalid=${invalid}.$(date -u +%Y%m%dT%H%M%SZ)
            mv -- "$partial" "$invalid"
            echo "core_guest_package: quarantined partial package at $invalid" >&2
        fi
        [ ! -d "$MRROOT" ] || touch "$MRROOT/.INVALID-DO-NOT-USE"
        [ ! -d "$BUILD_FULL_CACHE" ] || touch "$BUILD_FULL_CACHE/.INVALID-DO-NOT-USE"
        [ ! -d "$BUILD_FE_CACHE" ] || touch "$BUILD_FE_CACHE/.INVALID-DO-NOT-USE"
    fi
    exit "$status"
}
trap quarantine_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

hash_file() { sha256sum "$1" | awk '{print $1}'; }

nm_symbol_count() {
    local mode=$1 path=$2 symbol=$3
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }'
}

nm_developer_tools_support_count() {
    local mode=$1 path=$2
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk 'index($0, "DeveloperToolsSupport") { count++ } END { print count + 0 }'
}

require_hash() {
    local path=$1 expected=$2 label=$3 actual
    [ -f "$path" ] && [ ! -L "$path" ] || die "missing regular $label: $path"
    actual=$(hash_file "$path")
    [ "$actual" = "$expected" ] || die "$label hash $actual, expected $expected"
}

assert_clean_commit() {
    local repo=$1 expected_commit=$2 expected_tree=$3 label=$4
    local actual_commit actual_tree status
    [ -d "$repo/.git" ] || die "$label is not a Git checkout: $repo"
    actual_commit=$(git -C "$repo" rev-parse --verify HEAD^{commit})
    actual_tree=$(git -C "$repo" rev-parse --verify HEAD^{tree})
    status=$(git -C "$repo" status --porcelain=v1 --untracked-files=all)
    [ "$actual_commit" = "$expected_commit" ] \
        || die "$label commit $actual_commit, expected $expected_commit"
    [ "$actual_tree" = "$expected_tree" ] \
        || die "$label tree $actual_tree, expected $expected_tree"
    [ -z "$status" ] || die "$label checkout is dirty: $status"
}

assert_exact_swift_set() {
    local repo=$1 relative=$2 expected_count=$3 label=$4 prefix=$5
    local tracked=$WORK/$prefix.tracked physical=$WORK/$prefix.physical count
    git -C "$repo" ls-files -z -- "$relative" \
        | while IFS= read -r -d '' path; do
            case "$path" in *.swift) printf '%s\0' "$path" ;; esac
          done | LC_ALL=C sort -z > "$tracked"
    find "$repo/$relative" -type f -name '*.swift' -print0 \
        | while IFS= read -r -d '' path; do
            printf '%s\0' "${path#"$repo"/}"
          done | LC_ALL=C sort -z > "$physical"
    cmp "$tracked" "$physical" || die "$label physical Swift set differs from pinned Git"
    count=$(tr -cd '\0' < "$physical" | wc -c | tr -d '[:space:]')
    [ "$count" = "$expected_count" ] \
        || die "$label Swift count $count, expected $expected_count"
    sha256sum "$physical" | awk -v label="$label" '{print "source-set\t" label "\t" $1 "\tcount='"$count"'"}'
}

SUPPORT_COMMIT=$(git -C "$W" rev-parse --verify HEAD^{commit})
SUPPORT_TREE=$(git -C "$W" rev-parse --verify HEAD^{tree})
[ "$SUPPORT_COMMIT" = "$EXPECTED_SUPPORT_COMMIT" ] \
    || die "support commit $SUPPORT_COMMIT, expected $EXPECTED_SUPPORT_COMMIT"
[ "$SUPPORT_TREE" = "$EXPECTED_SUPPORT_TREE" ] \
    || die "support tree $SUPPORT_TREE, expected $EXPECTED_SUPPORT_TREE"
git -C "$W" merge-base --is-ancestor "$EXPECTED_SUPPORT_BASE" "$SUPPORT_COMMIT" \
    || die "support HEAD does not descend from reviewed base $EXPECTED_SUPPORT_BASE"
[ -z "$(git -C "$W" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'support checkout is dirty'
assert_clean_commit "$UIKIT" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_clean_commit "$MACHORUN" "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" machorun
require_hash "$MACHORUN/darwin/usr/lib/swift/libswiftCore.dylib" \
    "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256" machorun-Swift-core
require_hash "$MACHORUN/darwin/usr/lib/libobjc.A.dylib" \
    "$EXPECTED_MACHORUN_OBJC_SHA256" machorun-Objective-C-runtime
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE" swift-foundation
assert_clean_commit "$SWIFT_FOUNDATION_ICU" "$EXPECTED_FOUNDATION_ICU_COMMIT" \
    "$EXPECTED_FOUNDATION_ICU_TREE" swift-foundation-icu
assert_clean_commit "$SWIFT_COLLECTIONS" "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE" swift-collections
assert_clean_commit "$OPENCOMBINE_SOURCE" "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE" OpenCombine

SOURCE_SET_ATTEST=$WORK/source-sets.pre.tsv
{
    printf 'format\tcore-source-sets-v1\n'
    assert_exact_swift_set "$UIKIT" Sources/OpenUIKit \
        "$EXPECTED_UIKIT_SWIFT_COUNT" OpenUIKit openuikit
    assert_exact_swift_set "$UIKIT" Sources/OpenCoreGraphics \
        "$EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT" OpenCoreGraphics opencoregraphics
    assert_exact_swift_set "$UIKIT" Sources/Symbols \
        "$EXPECTED_SYMBOLS_SWIFT_COUNT" Symbols symbols
    assert_exact_swift_set "$UIKIT" Sources/SwiftUI \
        "$EXPECTED_SWIFTUI_SWIFT_COUNT" SwiftUI swiftui
    assert_exact_swift_set "$UIKIT" Sources/DeveloperToolsSupport \
        "$EXPECTED_DEVELOPER_TOOLS_SUPPORT_SWIFT_COUNT" \
        DeveloperToolsSupport developertoolsupport
    assert_exact_swift_set "$UIKIT" Sources/OpenUIKitPreviewMacros \
        "$EXPECTED_OPENUIKIT_PREVIEW_MACROS_SWIFT_COUNT" \
        OpenUIKitPreviewMacros open-uikit-preview-macros
    assert_exact_swift_set "$UIKIT" Sources/OpenSwiftUIMacros \
        "$EXPECTED_OPENSWIFTUI_MACROS_SWIFT_COUNT" \
        OpenSwiftUIMacros open-swiftui-macros
} > "$SOURCE_SET_ATTEST"
cquartz_count=$(find "$UIKIT/Sources/CQuartz" -maxdepth 1 -type f -name '*.cpp' \
    | wc -l | tr -d '[:space:]')
[ "$cquartz_count" = "$EXPECTED_CQUARTZ_CPP_COUNT" ] \
    || die "CQuartz C++ count $cquartz_count, expected $EXPECTED_CQUARTZ_CPP_COUNT"

python3 "$MANIFEST_TOOL" foundation-sources \
    --support-root "$W" --manifest "$FOUNDATION_SOURCES_MANIFEST" \
    --output "$WORK/foundation-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/foundation-sources.pre.tsv")" -eq \
    "$EXPECTED_FOUNDATION_SOURCE_COUNT" ] || die 'Foundation source count drifted'

mapfile -t OBSERVATION_SOURCES < "$OBSERVATION_SOURCES_MANIFEST"
[ "${#OBSERVATION_SOURCES[@]}" -eq "$EXPECTED_OBSERVATION_SOURCE_COUNT" ] \
    || die 'Observation source count drifted'
[ "${#OBSERVATION_SOURCE_HASHES[@]}" -eq "$EXPECTED_OBSERVATION_SOURCE_COUNT" ] \
    || die 'Observation source hash cardinality drifted'
observation_physical=$WORK/observation-physical.txt
find "$W/full/observation/Sources/Observation" -maxdepth 1 -type f \
    -name '*.swift' -print \
    | sed "s#^$W/##" | LC_ALL=C sort > "$observation_physical"
printf '%s\n' "${OBSERVATION_SOURCES[@]}" | LC_ALL=C sort \
    > "$WORK/observation-manifest-sorted.txt"
cmp "$observation_physical" "$WORK/observation-manifest-sorted.txt" \
    || die 'Observation physical Swift set differs from its manifest'
for index in "${!OBSERVATION_SOURCES[@]}"; do
    relative=${OBSERVATION_SOURCES[$index]}
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Observation source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "Observation source is not tracked: $relative"
    require_hash "$W/$relative" "${OBSERVATION_SOURCE_HASHES[$index]}" \
        "Observation-source-$index"
done
for relative in \
    full/observation/ObservationRuntimeBridge.c \
    full/observation/UPSTREAM.md \
    full/observation/observation_guest_sources.txt \
    full/observation/tests/ObservationGuestRuntimeProbe.swift \
    full/observation/tests/ObservationGuestRuntimeMain.swift; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Observation platform input is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "Observation platform input is not tracked: $relative"
done
write_observation_sources_attestation() {
    local output=$1 index relative
    {
        printf 'format\tobservation-guest-sources-v1\n'
        printf 'upstream\tswiftlang/swift\tcommit=%s\ttag=swift-6.2.4-RELEASE\n' \
            "$EXPECTED_OBSERVATION_UPSTREAM_COMMIT"
        printf 'manifest\t%s\tcount=%s\n' \
            "$(hash_file "$OBSERVATION_SOURCES_MANIFEST")" \
            "$EXPECTED_OBSERVATION_SOURCE_COUNT"
        for index in "${!OBSERVATION_SOURCES[@]}"; do
            relative=${OBSERVATION_SOURCES[$index]}
            printf 'source\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
        done
        for relative in \
            full/observation/ObservationRuntimeBridge.c \
            full/observation/tests/ObservationGuestRuntimeProbe.swift \
            full/observation/tests/ObservationGuestRuntimeMain.swift; do
            printf 'platform\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
    } > "$output"
}
write_observation_sources_attestation "$WORK/observation-sources.pre.tsv"
python3 -B "$WEBKIT_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$WEBKIT_PROVENANCE_POLICY" \
    --output "$WORK/webkit-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/webkit-sources.pre.tsv")" -eq \
    "$EXPECTED_WEBKIT_SOURCE_COUNT" ] || die 'WebKit source count drifted'
[ -f "$HACKERS_WEBKIT_SURFACE" ] && [ ! -L "$HACKERS_WEBKIT_SURFACE" ] \
    || die 'Hackers WebKit Swift 6 surface gate is missing or linked'
git -C "$W" ls-files --error-unmatch \
    "${HACKERS_WEBKIT_SURFACE#"$W"/}" >/dev/null \
    || die 'Hackers WebKit Swift 6 surface gate is not tracked'
require_hash "$HACKERS_WEBKIT_SURFACE" \
    "$EXPECTED_HACKERS_WEBKIT_SURFACE_SHA256" \
    Hackers-WebKit-Swift-6-surface

mapfile -t INTENTS_SOURCES < "$INTENTS_SOURCES_MANIFEST"
mapfile -t INTENTSUI_SOURCES < "$INTENTSUI_SOURCES_MANIFEST"
[ "${#INTENTS_SOURCES[@]}" -eq "$EXPECTED_INTENTS_SOURCE_COUNT" ] \
    || die 'Intents source count drifted'
[ "${#INTENTSUI_SOURCES[@]}" -eq "$EXPECTED_INTENTSUI_SOURCE_COUNT" ] \
    || die 'IntentsUI source count drifted'
[ "${INTENTS_SOURCES[0]}" = full/intents/Intents.swift ] \
    || die 'Intents ordered source manifest drifted'
[ "${INTENTSUI_SOURCES[0]}" = full/intentsui/IntentsUI.swift ] \
    || die 'IntentsUI ordered source manifest drifted'
for relative in "${INTENTS_SOURCES[@]}" "${INTENTSUI_SOURCES[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "framework source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "framework source is not tracked: $relative"
done
{
    printf 'format\tframework-guest-sources-v1\n'
    printf 'manifest\tIntents\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTS_SOURCES_MANIFEST")" "${#INTENTS_SOURCES[@]}"
    for relative in "${INTENTS_SOURCES[@]}"; do
        printf 'source\tIntents\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
    printf 'manifest\tIntentsUI\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTSUI_SOURCES_MANIFEST")" "${#INTENTSUI_SOURCES[@]}"
    for relative in "${INTENTSUI_SOURCES[@]}"; do
        printf 'source\tIntentsUI\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
} > "$WORK/intents-sources.pre.tsv"

mapfile -t COREIMAGE_SOURCES < "$COREIMAGE_SOURCES_MANIFEST"
mapfile -t QUARTZCORE_SOURCES < "$QUARTZCORE_SOURCES_MANIFEST"
[ "${#COREIMAGE_SOURCES[@]}" -eq "$EXPECTED_COREIMAGE_SOURCE_COUNT" ] \
    || die 'CoreImage source count drifted'
[ "${#QUARTZCORE_SOURCES[@]}" -eq "$EXPECTED_QUARTZCORE_SOURCE_COUNT" ] \
    || die 'QuartzCore source count drifted'
[ "${COREIMAGE_SOURCES[0]}" = full/coreimage/CoreImage.swift ] \
    || die 'CoreImage ordered source manifest drifted'
[ "${QUARTZCORE_SOURCES[0]}" = full/quartzcore/QuartzCore.swift ] \
    || die 'QuartzCore ordered source manifest drifted'
for relative in "${COREIMAGE_SOURCES[@]}" "${QUARTZCORE_SOURCES[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "graphics framework source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "graphics framework source is not tracked: $relative"
done
for coreimage_input in \
    "$COREIMAGE_SOURCES_MANIFEST" \
    "$W/full/coreimage/include/CoreImage.h" \
    "$W/full/coreimage/include/CIFilterBuiltins.h" \
    "$W/full/coreimage/include/module.modulemap" \
    "$QUARTZCORE_SOURCES_MANIFEST"; do
    [ -f "$coreimage_input" ] && [ ! -L "$coreimage_input" ] \
        || die "graphics framework input is not a regular file: $coreimage_input"
    git -C "$W" ls-files --error-unmatch "${coreimage_input#"$W"/}" >/dev/null \
        || die "graphics framework input is not tracked: $coreimage_input"
done
write_graphics_sources_attestation() {
    local output=$1 relative
    {
        printf 'format\tgraphics-framework-guest-sources-v1\n'
        printf 'manifest\tCoreImage\t%s\tcount=%s\n' \
            "$(hash_file "$COREIMAGE_SOURCES_MANIFEST")" \
            "${#COREIMAGE_SOURCES[@]}"
        for relative in "${COREIMAGE_SOURCES[@]}"; do
            printf 'source\tCoreImage\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
        printf 'underlying\tCoreImage\t%s\t%s\n' \
            full/coreimage/include/CoreImage.h \
            "$(hash_file "$W/full/coreimage/include/CoreImage.h")"
        printf 'underlying\tCoreImage.CIFilterBuiltins\t%s\t%s\n' \
            full/coreimage/include/CIFilterBuiltins.h \
            "$(hash_file "$W/full/coreimage/include/CIFilterBuiltins.h")"
        printf 'modulemap\tCoreImage\t%s\t%s\n' \
            full/coreimage/include/module.modulemap \
            "$(hash_file "$W/full/coreimage/include/module.modulemap")"
        printf 'manifest\tQuartzCore\t%s\tcount=%s\n' \
            "$(hash_file "$QUARTZCORE_SOURCES_MANIFEST")" \
            "${#QUARTZCORE_SOURCES[@]}"
        for relative in "${QUARTZCORE_SOURCES[@]}"; do
            printf 'source\tQuartzCore\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
    } > "$output"
}
write_graphics_sources_attestation "$WORK/graphics-sources.pre.tsv"

mapfile -t APPKIT_SOURCES < "$APPKIT_SOURCES_MANIFEST"
mapfile -t SWIFTUI_APPKIT_SOURCES < "$SWIFTUI_APPKIT_SOURCES_MANIFEST"
[ "${#APPKIT_SOURCES[@]}" -eq "$EXPECTED_APPKIT_SOURCE_COUNT" ] \
    || die 'AppKit source manifest cardinality drifted'
[ "${#SWIFTUI_APPKIT_SOURCES[@]}" -eq \
    "$EXPECTED_SWIFTUI_APPKIT_SOURCE_COUNT" ] \
    || die 'SwiftUI/AppKit source manifest cardinality drifted'
[ "${APPKIT_SOURCES[0]}" = full/appkit/AppKit.swift ] \
    || die 'AppKit ordered source manifest drifted'
[ "${SWIFTUI_APPKIT_SOURCES[0]}" = \
    full/appkit/SwiftUIAppKitCompatibility.swift ] \
    || die 'SwiftUI/AppKit ordered source manifest drifted'
APPKIT_PLATFORM_INPUTS=(
    full/appkit/appkit_guest_sources.txt
    full/appkit/AppKit.swift
    full/appkit/swiftui_appkit_guest_sources.txt
    full/appkit/SwiftUIAppKitCompatibility.swift
    full/appkit/tests/AppKitGuestRuntime.swift
    full/appkit/tests/AppKitInterfaceOracle.swift
    full/appkit/tests/SwiftUIAppKitColorRuntime.swift
    full/appkit/tests/StoreKitAppKitRuntime.swift
    full/appkit/tests/appkit-interface-apple-xcode-26.1.txt
    full/appkit/tests/appkit-load-identities.txt
)
for relative in "${APPKIT_PLATFORM_INPUTS[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "AppKit platform input is missing or linked: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "AppKit platform input is not tracked: $relative"
done
write_appkit_sources_attestation() {
    local output=$1 relative
    {
        printf 'format\tappkit-production-sources-v1\n'
        printf 'manifest\tAppKit\t%s\tcount=%s\n' \
            "$(hash_file "$APPKIT_SOURCES_MANIFEST")" \
            "${#APPKIT_SOURCES[@]}"
        for relative in "${APPKIT_SOURCES[@]}"; do
            printf 'source\tAppKit\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
        printf 'manifest\tSwiftUI-AppKit\t%s\tcount=%s\n' \
            "$(hash_file "$SWIFTUI_APPKIT_SOURCES_MANIFEST")" \
            "${#SWIFTUI_APPKIT_SOURCES[@]}"
        for relative in "${SWIFTUI_APPKIT_SOURCES[@]}"; do
            printf 'source\tSwiftUI-AppKit\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
        for relative in \
            full/appkit/tests/AppKitGuestRuntime.swift \
            full/appkit/tests/AppKitInterfaceOracle.swift \
            full/appkit/tests/SwiftUIAppKitColorRuntime.swift \
            full/appkit/tests/StoreKitAppKitRuntime.swift \
            full/appkit/tests/appkit-interface-apple-xcode-26.1.txt \
            full/appkit/tests/appkit-load-identities.txt; do
            printf 'gate\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
    } > "$output"
}
write_appkit_sources_attestation "$WORK/appkit-sources.pre.tsv"

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/first-party-sources.pre.tsv")" -eq 7 ] \
    || die 'first-party production source count drifted'
append_frontier_sources() {
    local output=$1 index framework source_dir source_manifest relative expected_count
    local -a frontier_sources frontier_inputs
    for index in "${!FRONTIER_FRAMEWORKS[@]}"; do
        framework=${FRONTIER_FRAMEWORKS[$index]}
        source_dir=${FRONTIER_SOURCE_DIRS[$index]}
        source_manifest=$W/full/$source_dir/${source_dir}_guest_sources.txt
        [ -f "$source_manifest" ] && [ ! -L "$source_manifest" ] \
            || die "$framework frontier source manifest is missing or linked"
        mapfile -t frontier_sources < "$source_manifest"
        expected_count=1
        case "$framework" in
            SwiftData) expected_count=$EXPECTED_SWIFTDATA_SOURCE_COUNT ;;
            CoreMedia) expected_count=$EXPECTED_COREMEDIA_SOURCE_COUNT ;;
            AVFoundation) expected_count=$EXPECTED_AVFOUNDATION_SOURCE_COUNT ;;
            AVKit) expected_count=$EXPECTED_AVKIT_SOURCE_COUNT ;;
            Charts) expected_count=$EXPECTED_CHARTS_SOURCE_COUNT ;;
            WidgetKit) expected_count=$EXPECTED_WIDGETKIT_SOURCE_COUNT ;;
            CoreTransferable) expected_count=$EXPECTED_CORETRANSFERABLE_SOURCE_COUNT ;;
            Photos) expected_count=$EXPECTED_PHOTOS_SOURCE_COUNT ;;
            PhotosUI) expected_count=$EXPECTED_PHOTOSUI_SOURCE_COUNT ;;
            NaturalLanguage) expected_count=$EXPECTED_NATURALLANGUAGE_SOURCE_COUNT ;;
            AuthenticationServices) expected_count=$EXPECTED_AUTHENTICATIONSERVICES_SOURCE_COUNT ;;
        esac
        [ "${#frontier_sources[@]}" -eq "$expected_count" ] \
            || die "$framework frontier source manifest cardinality drifted"
        if [ "$framework" = SwiftData ]; then
            [ "${frontier_sources[*]}" = \
                'full/swiftdata/SwiftData.swift full/swiftdata/SwiftDataSwiftUI.swift' ] \
                || die 'SwiftData frontier source paths drifted'
        else
            [ "${frontier_sources[0]}" = "full/$source_dir/$framework.swift" ] \
                || die "$framework frontier source path drifted: ${frontier_sources[0]}"
        fi
        git -C "$W" ls-files --error-unmatch \
            "${source_manifest#"$W"/}" "${frontier_sources[@]}" >/dev/null \
            || die "$framework frontier inputs are not tracked"
        for relative in "${frontier_sources[@]}"; do
            [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                || die "$framework frontier source is missing or linked"
            printf 'frontier-source\t%s\t%s\t%s\t%s\n' \
                "$((index + 1))" "$framework" "$relative" \
                "$(hash_file "$W/$relative")" >> "$output"
        done
        printf 'frontier-manifest\t%s\t%s\t%s\t%s\n' \
            "$((index + 1))" "$framework" "${source_manifest#"$W"/}" \
            "$(hash_file "$source_manifest")" >> "$output"
        if [ "$framework" = CommonCrypto ]; then
            frontier_inputs=(
                full/commoncrypto/CommonDigest.c
                full/commoncrypto/include/CommonDigest.h
                full/commoncrypto/include/module.modulemap
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "CommonCrypto underlying input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "CommonCrypto underlying input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = UserNotifications ]; then
            frontier_inputs=(
                full/usernotifications/tests/UserNotificationsHostRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "UserNotifications supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "UserNotifications supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = BackgroundTasks ]; then
            frontier_inputs=(
                full/backgroundtasks/tests/BackgroundTasksHostRuntime.swift
                full/backgroundtasks/tests/test_background_spotlight_host.sh
                full/corespotlight/tests/CorpusConsumerSurface.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "BackgroundTasks supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "BackgroundTasks supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = CoreSpotlight ]; then
            frontier_inputs=(
                full/corespotlight/tests/CoreSpotlightHostRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "CoreSpotlight supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "CoreSpotlight supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = QuickLook ]; then
            frontier_inputs=(
                full/quicklook/QuickLookSwiftUI.swift
                full/quicklook/quicklook_swiftui_guest_sources.txt
                full/quicklook/SwiftUI.swiftoverlay
                full/quicklook/tests/QuickLookGuestRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "QuickLook supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "QuickLook supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = SwiftData ]; then
            frontier_inputs=(
                full/swiftdata/SwiftDataMacros.swift
                full/swiftdata/tests/SwiftDataGuestRuntime.swift
                full/foundation/patches/FoundationEssentials-PredicateFinalClassKeyPath.patch
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "SwiftData supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "SwiftData supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = CoreMedia ]; then
            frontier_inputs=(
                full/coremedia/tests/CoreMediaTranscript.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "CoreMedia supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "CoreMedia supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = AVFoundation ]; then
            frontier_inputs=(
                full/avfoundation/tests/AVFoundationHostRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "AVFoundation supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "AVFoundation supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = Charts ]; then
            frontier_inputs=(
                full/charts/tests/ChartsHostRuntime.swift
                full/charts/tests/IceCubesChartsConsumer.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "Charts supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "Charts supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = WidgetKit ]; then
            frontier_inputs=(
                full/widgetkit/tests/WidgetKitHostRuntime.swift
                full/widgetkit/tests/IceCubesWidgetKitConsumer.swift
                full/widgetkit/tests/SimplenoteWidgetKitConsumer.swift
                full/widgetkit/tests/IceCubesWidgetBundleSupport.swift
                full/widgetkit/tests/SimplenoteWidgetControllerSupport.swift
                full/widgetkit/tests/SimplenoteExactWidgetSupport.swift
                full/widgetkit/tests/icecubes-widgetkit-frontier.tsv
                full/widgetkit/tests/test_widgetkit_host.sh
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "WidgetKit supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "WidgetKit supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = CoreTransferable ]; then
            frontier_inputs=(
                full/coretransferable/tests/CoreTransferableHostRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "CoreTransferable supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "CoreTransferable supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = Photos ]; then
            frontier_inputs=(
                full/photos/tests/PhotosHostRuntime.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "Photos supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "Photos supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = PhotosUI ]; then
            frontier_inputs=(
                full/photosui/PhotosUISwiftUI.swift
                full/photosui/photosui_swiftui_guest_sources.txt
                full/photosui/SwiftUI.swiftoverlay
                full/photosui/tests/PhotosUIHostRuntime.swift
                full/photosui/tests/IceCubesPhotosUIConsumer.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "PhotosUI supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "PhotosUI supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = Accelerate ]; then
            frontier_inputs=(
                full/accelerate/Accelerate.c
                full/accelerate/include/Accelerate.h
                full/accelerate/include/module.modulemap
                full/accelerate/tests/AccelerateBoxConvolveOracle.c
                full/accelerate/tests/AccelerateGuestRuntime.swift
                full/accelerate/tests/accelerate-box-convolve-apple-2026-09-01.txt
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "Accelerate supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "Accelerate supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = NaturalLanguage ]; then
            frontier_inputs=(
                full/naturallanguage/tests/NaturalLanguageHostRuntime.swift
                full/naturallanguage/tests/IceCubesNaturalLanguageConsumers.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "NaturalLanguage supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "NaturalLanguage supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = Compression ]; then
            frontier_inputs=(
                full/compression/OpenCompressionBridge.c
                full/compression/OpenCompressionHost.c
                full/compression/include/OpenCompressionABI.h
                full/compression/include/module.modulemap
                full/compression/tests/CompressionBrotliOracle.swift
                full/compression/tests/CompressionGuestRuntime.swift
                full/compression/tests/OpenCompressionHostTests.c
                full/compression/tests/compression-brotli-apple-2026-09-01.txt
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "Compression supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "Compression supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = CoreText ]; then
            frontier_inputs=(
                full/coretext/tests/CoreTextFontManagerOracle.swift
                full/coretext/tests/CoreTextGuestRuntime.swift
                full/coretext/tests/coretext-font-manager-apple-2026-09-01.txt
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "CoreText supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "CoreText supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = AdServices ]; then
            frontier_inputs=(
                full/adservices/tests/AdServicesInterfaceOracle.swift
                full/adservices/tests/AdServicesGuestRuntime.swift
                full/adservices/tests/RevenueCatAttributionRuntimeSupport.swift
                full/adservices/tests/adservices-interface-apple-2026-09-01.txt
                full/adservices/tests/revenuecat-frontier.tsv
                full/adservices/tests/test_revenuecat_frontier_guest.sh
                full/zlib/OpenZlibBridge.c
                full/zlib/OpenZlibHost.c
                full/zlib/include/COpenZlib/OpenZlibABI.h
                full/zlib/include/COpenZlib/module.modulemap
                full/zlib/include/zlib/zlib.h
                full/zlib/include/zlib/module.modulemap
                full/zlib/tests/OpenZlibHostTests.c
                full/zlib/tests/ZlibGuestRuntime.swift
                full/zlib/tests/ZlibGzipOracle.swift
                full/zlib/tests/RevenueCatZlibRuntimeSupport.swift
                full/zlib/tests/zlib-gzip-apple-2026-09-01.txt
                full/zlib/zlib_guest_sources.txt
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "RevenueCat frontier input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "RevenueCat frontier input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = AuthenticationServices ]; then
            frontier_inputs=(
                full/authenticationservices/AuthenticationServicesSwiftUI.swift
                full/authenticationservices/authenticationservices_swiftui_guest_sources.txt
                full/authenticationservices/SwiftUI.swiftoverlay
                full/authenticationservices/tests/AuthenticationServicesHostRuntime.swift
                full/authenticationservices/tests/IceCubesAuthenticationServicesConsumer.swift
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "AuthenticationServices supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "AuthenticationServices supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = FoundationModels ]; then
            frontier_inputs=(
                full/foundationmodels/FoundationModelsMacros.swift
                full/foundationmodels/README.md
                full/foundationmodels/tests/FoundationModelsMacroOracle.swift
                full/foundationmodels/tests/FoundationModelsNativeOracle.swift
                full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift
                full/foundationmodels/tests/foundationmodels-apple-26.1.txt
                full/foundationmodels/tests/icecubes_foundationmodels_frontier.tsv
                full/foundationmodels/tests/build_foundationmodels_guest.sh
                full/foundationmodels/tests/build_foundationmodels_guest_in_container.sh
                full/foundationmodels/tests/test_foundationmodels_frontier.py
                full/foundationmodels/tests/test_foundationmodels_native.sh
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "FoundationModels supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "FoundationModels supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
        if [ "$framework" = NaturalLanguage ]; then
            frontier_inputs=(
                full/naturallanguage/README.md
                full/naturallanguage/tests/NaturalLanguageIceCubesOracle.swift
                full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift
                full/naturallanguage/tests/naturallanguage-apple-26.1.txt
                full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt
                full/naturallanguage/tests/icecubes_naturallanguage_frontier.tsv
                full/naturallanguage/tests/build_naturallanguage_guest.sh
                full/naturallanguage/tests/build_naturallanguage_guest_in_container.sh
                full/naturallanguage/tests/test_naturallanguage_native.sh
                full/naturallanguage/tests/test_naturallanguage_frontier.py
            )
            for relative in "${frontier_inputs[@]}"; do
                [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
                    || die "NaturalLanguage supporting input is missing or linked: $relative"
                git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
                    || die "NaturalLanguage supporting input is not tracked: $relative"
                printf 'frontier-input\t%s\t%s\t%s\t%s\n' \
                    "$((index + 1))" "$framework" "$relative" \
                    "$(hash_file "$W/$relative")" >> "$output"
            done
        fi
    done
    printf 'frontier-source\t34\tIOKit\t%s\t%s\n' \
        full/iokit/IOKit.c "$(hash_file "$W/full/iokit/IOKit.c")" >> "$output"
    printf 'frontier-source\t35\tIOKit\t%s\t%s\n' \
        full/iokit/IOKit.swift \
        "$(hash_file "$W/full/iokit/IOKit.swift")" >> "$output"
    printf 'frontier-source\t36\tSwiftIOKitRuntime\t%s\t%s\n' \
        full/iokit/OpenSwiftIOKitRuntime.c \
        "$(hash_file "$W/full/iokit/OpenSwiftIOKitRuntime.c")" >> "$output"
    iokit_inputs=(
        full/iokit/OpenSwiftIOKitRuntime.h
        full/iokit/include/IOKit.h
        full/iokit/include/module.modulemap
        full/iokit/tests/IOKitHostTests.c
        full/iokit/tests/IOKitGuestRuntime.swift
        full/iokit/tests/IOKitInterfaceOracle.swift
        full/iokit/tests/OpenSwiftIOKitHostTests.c
        full/iokit/tests/RevenueCatIOKitRuntimeSupport.swift
        full/iokit/tests/iokit-interface-apple-2026-09-01.txt
        full/iokit/tests/iokit-interface-portable-2026-09-01.txt
        full/iokit/tests/libswiftIOKit-apple-2026-09-01.exports
    )
    for relative in "${iokit_inputs[@]}"; do
        [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
            || die "IOKit frontier input is missing or linked: $relative"
        git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
            || die "IOKit frontier input is not tracked: $relative"
        printf 'frontier-input\t34\tIOKit\t%s\t%s\n' "$relative" \
            "$(hash_file "$W/$relative")" >> "$output"
    done
}
append_frontier_sources "$WORK/first-party-sources.pre.tsv"
[ "$(grep -c '^frontier-source' "$WORK/first-party-sources.pre.tsv")" -eq 35 ] \
    || die 'frontier framework source count drifted'
[ "$(grep -c '^frontier-input' "$WORK/first-party-sources.pre.tsv")" -eq 108 ] \
    || die 'frontier underlying input count drifted'

python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$UIKIT/Sources/OpenUIKit/Resources" \
    --logical-root resources/OpenUIKit --reject-symlinks \
    --output "$WORK/openuikit-resources.pre.tsv"
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$SYS" --logical-root sdk \
    --dangling-exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk.pre.tsv"
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$SYS" --exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk-dangling.pre.tsv"

require_hash "$OPENCOMBINE_ROOT/export/RESULT.txt" "$EXPECTED_OPENCOMBINE_RESULT" OpenCombine-result
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$EXPECTED_OPENCOMBINE_OBJECT" OpenCombine-object
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" "$EXPECTED_OPENCOMBINE_MODULE" OpenCombine-module
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$EXPECTED_OPENCOMBINE_DOC" OpenCombine-doc
require_hash "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_HELPER" OpenCombine-helper
require_hash "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" "$EXPECTED_OPENCOMBINE_HEADER" OpenCombine-header
require_hash "$OPENCOMBINE_HELPERS/include/module.modulemap" "$EXPECTED_OPENCOMBINE_MODULEMAP" OpenCombine-modulemap
require_hash "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch" \
    "$EXPECTED_OPENCOMBINE_PATCH" OpenCombine-patch
require_hash "$W/full/oracle-opencombine/Combine.swift" "$EXPECTED_COMBINE_SHIM" Combine-shim
require_hash "$FOUNDATION_CACHE_ORACLE" \
    "$EXPECTED_FOUNDATION_CACHE_ORACLE_SHA256" Foundation-cache-oracle
require_hash "$FOUNDATION_CACHE_GOLDEN" \
    "$EXPECTED_FOUNDATION_CACHE_GOLDEN_SHA256" Foundation-cache-Apple-golden
for cache_input in "$FOUNDATION_CACHE_ORACLE" "$FOUNDATION_CACHE_GOLDEN"; do
    git -C "$W" ls-files --error-unmatch "${cache_input#"$W"/}" >/dev/null \
        || die "Foundation cache oracle input is not tracked: $cache_input"
done
require_hash "$FOUNDATION_BYTE_COUNT_ORACLE" \
    "$EXPECTED_FOUNDATION_BYTE_COUNT_ORACLE_SHA256" Foundation-byte-count-oracle
require_hash "$FOUNDATION_BYTE_COUNT_GOLDEN" \
    "$EXPECTED_FOUNDATION_BYTE_COUNT_GOLDEN_SHA256" Foundation-byte-count-Apple-golden
for byte_count_input in "$FOUNDATION_BYTE_COUNT_ORACLE" "$FOUNDATION_BYTE_COUNT_GOLDEN"; do
    git -C "$W" ls-files --error-unmatch "${byte_count_input#"$W"/}" >/dev/null \
        || die "Foundation byte-count oracle input is not tracked: $byte_count_input"
done
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT" system-font
require_hash "$BOLD_FONT" "$EXPECTED_BOLD_FONT" bold-font

[ "${#OBSERVATION_PLUGIN_HOST_LIBS[@]}" -eq \
    "${#OBSERVATION_PLUGIN_HOST_HASHES[@]}" ] \
    || die 'Observation host plugin closure cardinality drifted'
[ "${#OBSERVATION_PLUGIN_LINUX_LIBS[@]}" -eq \
    "${#OBSERVATION_PLUGIN_LINUX_HASHES[@]}" ] \
    || die 'Observation Linux plugin closure cardinality drifted'
require_hash "$OBSERVATION_MACRO_PLUGIN" "$EXPECTED_OBSERVATION_PLUGIN_SHA" \
    Observation-macro-plugin
require_hash "$FOUNDATION_MACRO_PLUGIN" "$EXPECTED_FOUNDATION_PLUGIN_SHA" \
    Foundation-macro-plugin
file "$OBSERVATION_MACRO_PLUGIN" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
    || die 'Observation macro plugin is not native ELF64/aarch64'
readelf -h "$OBSERVATION_MACRO_PLUGIN" \
    | grep -Eq 'Machine:[[:space:]]+AArch64' \
    || die 'Observation macro plugin ELF machine is not AArch64'
for index in "${!OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_HOST_LIBS[$index]}
    require_hash "/usr/lib/swift/host/$library" \
        "${OBSERVATION_PLUGIN_HOST_HASHES[$index]}" \
        "Observation-plugin-host-$library"
done
for index in "${!OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_LINUX_LIBS[$index]}
    require_hash "/usr/lib/swift/linux/$library" \
        "${OBSERVATION_PLUGIN_LINUX_HASHES[$index]}" \
        "Observation-plugin-linux-$library"
done
OBSERVATION_TOOLCHAIN=$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')
printf '%s\n' "$OBSERVATION_TOOLCHAIN" | grep -Fq 'Swift version 6.2.4' \
    || die "Observation consumer toolchain is not Swift 6.2.4: $OBSERVATION_TOOLCHAIN"

PREVIEW_MODULE_SHA=''
PREVIEW_OBJECT_SHA=''
PREVIEW_PLUGIN_SHA=''
PREVIEW_TOOLCHAIN=''
PREVIEW_FLAGS=()
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    [ "$(basename "$DEVELOPER_TOOLS_SUPPORT_MODULE")" = DeveloperToolsSupport.swiftmodule ] \
        || die 'DeveloperToolsSupport module basename drifted'
    [ "$(basename "$DEVELOPER_TOOLS_SUPPORT_OBJECT")" = developertoolsupport.o ] \
        || die 'DeveloperToolsSupport object basename drifted'
    [ "$(basename "$PREVIEW_MACRO_PLUGIN")" = OpenUIKitPreviewMacros-tool ] \
        || die 'Preview plugin basename drifted'
    for input in "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_MACRO_PLUGIN"; do
        [ -f "$input" ] && [ ! -L "$input" ] \
            || die "Preview input is not a regular non-symlink file: $input"
    done
    [ -x "$PREVIEW_MACRO_PLUGIN" ] || die 'Preview macro plugin is not executable'
    llvm-otool-18 -hv "$DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
        || die 'DeveloperToolsSupport object is not an ARM64 Mach-O object'
    preview_export_definition_count=$(nm_symbol_count --defined-only \
        "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    [ "$preview_export_definition_count" -eq 1 ] \
        || die "Preview DTS initializer definition count $preview_export_definition_count, expected 1"
    file "$PREVIEW_MACRO_PLUGIN" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
        || die 'Preview macro plugin is not native ELF64/aarch64'
    readelf -h "$PREVIEW_MACRO_PLUGIN" | grep -Eq 'Machine:[[:space:]]+AArch64' \
        || die 'Preview macro plugin ELF machine is not AArch64'
    PREVIEW_TOOLCHAIN=$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    printf '%s\n' "$PREVIEW_TOOLCHAIN" | grep -Fq 'Swift version 6.2.4' \
        || die "Preview consumer toolchain is not Swift 6.2.4: $PREVIEW_TOOLCHAIN"
    PREVIEW_MODULE_SHA=$(hash_file "$DEVELOPER_TOOLS_SUPPORT_MODULE")
    PREVIEW_OBJECT_SHA=$(hash_file "$DEVELOPER_TOOLS_SUPPORT_OBJECT")
    PREVIEW_PLUGIN_SHA=$(hash_file "$PREVIEW_MACRO_PLUGIN")
    PREVIEW_FLAGS=(-load-plugin-executable \
        "$PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros" -j1)
fi

echo '== rebuild the proven FoundationEssentials/OpenUIKit substrate from cold roots'
# build_full deliberately proves the Foundation-hidden UIKit branch. Current
# DeveloperToolsSupport owns ImageResource's real Foundation.Bundle identity,
# so loading that module before the Foundation facade exists would violate the
# very visibility boundary build_full is designed to test. Preview and Entry
# are production compiler-library plugins below, after Foundation is staged;
# the legacy executable remains an immutable external compatibility input.
BUILD_FULL_ENV=(
    W="$W" UIKIT="$UIKIT" MACHORUN="$MACHORUN"
    SWIFT_CORE_RUNTIME_EXPECTED_SHA256="$EXPECTED_MACHORUN_SWIFT_CORE_SHA256"
    BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE=disabled
    BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER=core-package-post-foundation
    BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE=''
    BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT=''
    BUILD_FULL_PREVIEW_MACRO_PLUGIN=''
)
env "${BUILD_FULL_ENV[@]}" bash "$W/full/scripts/build_full.sh"
expected_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
actual_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
[ "$actual_subject" = "$expected_subject" ] \
    || die 'build_full subject marker is stale'
if grep -Eq '^(DeveloperToolsSupport\.swiftmodule|developertoolsupport\.o|OpenUIKitPreviewMacros-tool)[[:space:]]' \
    "$FULL/uihelpers-artifacts.sha256"; then
    die 'Foundation-hidden build_full output carries Preview artifact attestations'
fi
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    [ "$(hash_file "$DEVELOPER_TOOLS_SUPPORT_MODULE")" = "$PREVIEW_MODULE_SHA" ] \
        || die 'external DeveloperToolsSupport module changed during build_full'
    [ "$(hash_file "$DEVELOPER_TOOLS_SUPPORT_OBJECT")" = "$PREVIEW_OBJECT_SHA" ] \
        || die 'external DeveloperToolsSupport object changed during build_full'
    [ "$(hash_file "$PREVIEW_MACRO_PLUGIN")" = "$PREVIEW_PLUGIN_SHA" ] \
        || die 'external Preview executable changed during build_full'
fi

mkdir -p "$STAGE/sdk" "$STAGE/modules" "$STAGE/lib" "$STAGE/include" \
    "$STAGE/frameworks" \
    "$STAGE/objects" "$STAGE/resources/OpenUIKit/fonts" \
    "$STAGE/guest-root" "$STAGE/probe" "$STAGE/attestation" \
    "$STAGE/host-tools/swift/host/plugins" \
    "$STAGE/host-tools/swift/linux"
cp -a "$SYS/." "$STAGE/sdk/"
cp "$SDK_DANGLING_EXCLUSIONS" \
    "$STAGE/attestation/sdk-dangling-symlink-exclusions.tsv"
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$STAGE/sdk" \
    --exclusions "$STAGE/attestation/sdk-dangling-symlink-exclusions.tsv" \
    --output "$STAGE/attestation/sdk-dangling-symlinks.tsv" --remove
cmp "$WORK/sdk-dangling.pre.tsv" \
    "$STAGE/attestation/sdk-dangling-symlinks.tsv" \
    || die 'staged SDK dangling-symlink set differs from bracketed input'
cp -a "$MRROOT/." "$STAGE/guest-root/"
cp "$FULL/swift-core-runtime-stage.json" \
    "$STAGE/attestation/build-full-swift-core-stage.json"
cp -a "$UIKIT/Sources/OpenUIKit/Resources/." "$STAGE/resources/OpenUIKit/"
cp "$SYSTEM_FONT" "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf"
cp "$BOLD_FONT" "$STAGE/resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf"

cp "$OBSERVATION_MACRO_PLUGIN" \
    "$STAGE/host-tools/swift/host/plugins/libObservationMacros.so"
cp "$FOUNDATION_MACRO_PLUGIN" \
    "$STAGE/host-tools/swift/host/plugins/libFoundationMacros.so"
for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    cp "/usr/lib/swift/host/$library" "$STAGE/host-tools/swift/host/$library"
done
for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    cp "/usr/lib/swift/linux/$library" "$STAGE/host-tools/swift/linux/$library"
done
STAGED_OBSERVATION_PLUGIN=$STAGE/host-tools/swift/host/plugins/libObservationMacros.so
OBSERVATION_PLUGIN_FLAGS=(-load-plugin-library "$STAGED_OBSERVATION_PLUGIN")
STAGED_FOUNDATION_PLUGIN=$STAGE/host-tools/swift/host/plugins/libFoundationMacros.so
FOUNDATION_PLUGIN_FLAGS=(-load-plugin-library "$STAGED_FOUNDATION_PLUGIN")
STAGED_SWIFTDATA_PLUGIN=$STAGE/host-tools/swift/host/plugins/libSwiftDataMacros.so
swiftc -parse-as-library -emit-library -module-name SwiftDataMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$W/full/swiftdata/SwiftDataMacros.swift" -o "$STAGED_SWIFTDATA_PLUGIN"
SWIFTDATA_PLUGIN_FLAGS=(-load-plugin-library "$STAGED_SWIFTDATA_PLUGIN")
STAGED_FOUNDATIONMODELS_PLUGIN=$STAGE/host-tools/swift/host/plugins/libFoundationModelsMacros.so
swiftc -parse-as-library -emit-library -module-name FoundationModelsMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$W/full/foundationmodels/FoundationModelsMacros.swift" \
    -o "$STAGED_FOUNDATIONMODELS_PLUGIN"
FOUNDATIONMODELS_PLUGIN_FLAGS=(
    -load-plugin-library "$STAGED_FOUNDATIONMODELS_PLUGIN"
)
STAGED_OPENUIKIT_PREVIEW_PLUGIN=$STAGE/host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so
swiftc -parse-as-library -emit-library -module-name OpenUIKitPreviewMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$UIKIT/Sources/OpenUIKitPreviewMacros/UIKitPreviewMacro.swift" \
    -o "$STAGED_OPENUIKIT_PREVIEW_PLUGIN"
OPENUIKIT_PREVIEW_PLUGIN_FLAGS=(
    -load-plugin-library "$STAGED_OPENUIKIT_PREVIEW_PLUGIN"
)
STAGED_OPENSWIFTUI_PLUGIN=$STAGE/host-tools/swift/host/plugins/libOpenSwiftUIMacros.so
swiftc -parse-as-library -emit-library -module-name OpenSwiftUIMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$UIKIT/Sources/OpenSwiftUIMacros/EntryMacro.swift" \
    -o "$STAGED_OPENSWIFTUI_PLUGIN"
OPENSWIFTUI_PLUGIN_FLAGS=(-load-plugin-library "$STAGED_OPENSWIFTUI_PLUGIN")
# From this point forward Preview uses the packaged in-process library. The
# external executable remains only as the immutable build_full/evidence input;
# ordinary framework, package, and app compiler arguments use this generic
# relocatable transport alongside Entry and the other first-party macros.
PREVIEW_FLAGS=("${OPENUIKIT_PREVIEW_PLUGIN_FLAGS[@]}")
if ldd "$STAGED_OBSERVATION_PLUGIN" | grep -Fq 'not found'; then
    die 'packaged Observation macro plugin closure is incomplete'
fi
for plugin in "$STAGED_FOUNDATION_PLUGIN" "$STAGED_SWIFTDATA_PLUGIN" \
    "$STAGED_FOUNDATIONMODELS_PLUGIN" \
    "$STAGED_OPENUIKIT_PREVIEW_PLUGIN" "$STAGED_OPENSWIFTUI_PLUGIN"; do
    file "$plugin" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
        || die "packaged compiler plugin is not native ELF64/aarch64: $plugin"
    readelf -h "$plugin" | grep -Eq 'Machine:[[:space:]]+AArch64' \
        || die "packaged compiler plugin ELF machine is not AArch64: $plugin"
    LD_LIBRARY_PATH="$STAGE/host-tools/swift/host:$STAGE/host-tools/swift/linux" \
        ldd "$plugin" | grep -Fq 'not found' \
        && die "packaged compiler plugin closure is incomplete: $plugin"
done
{
    printf 'format\tobservation-macro-plugin-v1\n'
    printf 'toolchain\t%s\n' "$OBSERVATION_TOOLCHAIN"
    printf 'plugin\thost-tools/swift/host/plugins/libObservationMacros.so\t%s\n' \
        "$(hash_file "$STAGED_OBSERVATION_PLUGIN")"
    for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
        printf 'closure\thost-tools/swift/host/%s\t%s\n' \
            "$library" \
            "$(hash_file "$STAGE/host-tools/swift/host/$library")"
    done
    for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
        printf 'closure\thost-tools/swift/linux/%s\t%s\n' \
            "$library" \
            "$(hash_file "$STAGE/host-tools/swift/linux/$library")"
    done
    while IFS=$'\t' read -r soname resolved; do
        resolved=${resolved#"$STAGE/"}
        printf 'resolved\t%s\t%s\n' "$soname" "$resolved"
    done < <(ldd "$STAGED_OBSERVATION_PLUGIN" \
        | awk '/=>/ { print $1 "\t" $3; next } \
            /^[[:space:]]*\// { print $1 "\t" $1 }' \
        | LC_ALL=C sort -u)
} > "$STAGE/attestation/observation-macro-plugin.tsv"

PLUGIN_CLOSURE_PATHS=()
for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    PLUGIN_CLOSURE_PATHS+=("host-tools/swift/host/$library")
done
for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    PLUGIN_CLOSURE_PATHS+=("host-tools/swift/linux/$library")
done
mapfile -t PLUGIN_CLOSURE_PATHS < <(printf '%s\n' \
    "${PLUGIN_CLOSURE_PATHS[@]}" | LC_ALL=C sort)
{
    printf 'format\tcore-compiler-plugins-v1\n'
    printf 'plugin\tObservationMacros\tlibrary\thost-tools/swift/host/plugins/libObservationMacros.so\t%s\tObservableMacro,ObservationIgnoredMacro,ObservationTrackedMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_OBSERVATION_PLUGIN")"
    printf 'plugin\tFoundationMacros\tlibrary\thost-tools/swift/host/plugins/libFoundationMacros.so\t%s\tExpressionMacro,PredicateMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_FOUNDATION_PLUGIN")"
    printf 'plugin\tSwiftDataMacros\tlibrary\thost-tools/swift/host/plugins/libSwiftDataMacros.so\t%s\tPersistentModelMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_SWIFTDATA_PLUGIN")"
    printf 'plugin\tFoundationModelsMacros\tlibrary\thost-tools/swift/host/plugins/libFoundationModelsMacros.so\t%s\tGenerableMacro,GuideMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_FOUNDATIONMODELS_PLUGIN")"
    printf 'plugin\tOpenUIKitPreviewMacros\tlibrary\thost-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so\t%s\tUIKitPreviewMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_OPENUIKIT_PREVIEW_PLUGIN")"
    printf 'plugin\tOpenSwiftUIMacros\tlibrary\thost-tools/swift/host/plugins/libOpenSwiftUIMacros.so\t%s\tEntryMacro\tapp,framework,package\tserialized=no\n' \
        "$(hash_file "$STAGED_OPENSWIFTUI_PLUGIN")"
    for module in ObservationMacros FoundationMacros SwiftDataMacros \
        FoundationModelsMacros \
        OpenUIKitPreviewMacros OpenSwiftUIMacros; do
        for relative in "${PLUGIN_CLOSURE_PATHS[@]}"; do
            printf 'closure\t%s\t%s\t%s\n' "$module" "$relative" \
                "$(hash_file "$STAGE/$relative")"
        done
    done
} > "$STAGE/attestation/compiler-plugins.tsv"

cp -a "$FULL/inc/CPortableIO" "$STAGE/include/"
cp -a "$FULL/inc/CSTBTrueType" "$STAGE/include/"
mkdir -p "$STAGE/include/CHostClock" "$STAGE/include/CQuartz" \
    "$STAGE/include/COpenCombineHelpers" "$STAGE/include/COpenURLTransport" \
    "$STAGE/include/COpenRelativeTime" "$STAGE/include/COpenDispatch" \
    "$STAGE/include/CCommonCrypto" "$STAGE/include/COpenFoundationCore" \
    "$STAGE/include/COpenAccelerate" "$STAGE/include/COpenCompression" \
    "$STAGE/include/COpenZlib" "$STAGE/include/zlib" \
    "$STAGE/include/_FoundationCShims" \
    "$STAGE/guest-root/host"
cp -a "$W/full/hostclock/include/." "$STAGE/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$STAGE/include/CQuartz/"
cp -a "$OPENCOMBINE_HELPERS/include/." "$STAGE/include/COpenCombineHelpers/"
cp -a "$W/full/urltransport/include/." "$STAGE/include/COpenURLTransport/"
cp -a "$W/full/relativetime/include/." "$STAGE/include/COpenRelativeTime/"
cp -a "$W/full/dispatch/include/." "$STAGE/include/COpenDispatch/"
cp -a "$W/full/commoncrypto/include/." "$STAGE/include/CCommonCrypto/"
cp -a "$W/full/accelerate/include/." "$STAGE/include/COpenAccelerate/"
cp -a "$W/full/compression/include/." "$STAGE/include/COpenCompression/"
cp -a "$W/full/zlib/include/COpenZlib/." "$STAGE/include/COpenZlib/"
cp -a "$W/full/zlib/include/zlib/." "$STAGE/include/zlib/"
cp -a "$COPEN_FOUNDATION_CORE_INCLUDE/." \
    "$STAGE/include/COpenFoundationCore/"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/." \
    "$STAGE/include/_FoundationCShims/"
cp -a "$W/full/coreimage/include" "$STAGE/include/CoreImage"

copy_module_family() {
    local source_dir=$1 name=$2 suffix source
    [ -f "$source_dir/$name.swiftmodule" ] \
        || die "required module is missing: $source_dir/$name.swiftmodule"
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        source=$source_dir/$name.$suffix
        [ ! -e "$source" ] || cp "$source" "$STAGE/modules/"
    done
}
copy_module_family "$FULL/foundation/essentials" FoundationEssentials
copy_module_family "$FULL/foundation/collections" InternalCollectionsUtilities
copy_module_family "$FULL/foundation/collections" OrderedCollections
copy_module_family "$FULL/foundation/collections" _RopeModule
copy_module_family "$FULL/foundation/os" os
copy_module_family "$FULL" OpenCoreGraphics
copy_module_family "$FULL" OpenUIKit
cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$STAGE/modules/"

if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    cp "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$STAGE/modules/DeveloperToolsSupport.swiftmodule"
    cp "$DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        "$STAGE/objects/developertoolsupport.o"
fi

MODULE_CACHE=$WORK/module-cache
mkdir -p "$MODULE_CACHE"
SWIFTC=(swiftc -target "$TARGET" -sdk "$STAGE/sdk" -F "$STAGE/frameworks"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -enable-cross-import-overlays
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
# Platform modules suppress the compiler's convenience Regex import so their
# dependency inventories stay explicit. Untouched app/package consumers must
# retain normal Swift source semantics: StatusKit uses `Regex` after importing
# Foundation and NaturalLanguage, without an explicit _StringProcessing import.
APP_CONSUMER_SWIFTC=(swiftc -target "$TARGET" -sdk "$STAGE/sdk"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -enable-cross-import-overlays
    -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS"
    -syslibroot "$STAGE/sdk")
C_FLAGS=(-Xcc -I"$STAGE/include/CPortableIO"
    -Xcc -I"$STAGE/include/CSTBTrueType"
    -Xcc -I"$STAGE/include/CHostClock"
    -Xcc -I"$STAGE/include/COpenCombineHelpers"
    -Xcc -I"$STAGE/include/CQuartz"
    -Xcc -fmodule-map-file="$STAGE/include/CoreImage/module.modulemap"
    -Xcc -I"$STAGE/include/CoreImage"
    -Xcc -fmodule-map-file="$STAGE/include/COpenURLTransport/module.modulemap"
    -Xcc -I"$STAGE/include/COpenURLTransport"
    -Xcc -fmodule-map-file="$STAGE/include/COpenRelativeTime/module.modulemap"
    -Xcc -I"$STAGE/include/COpenRelativeTime"
    -Xcc -fmodule-map-file="$STAGE/include/COpenDispatch/module.modulemap"
    -Xcc -I"$STAGE/include/COpenDispatch"
    -Xcc -fmodule-map-file="$STAGE/include/CCommonCrypto/module.modulemap"
    -Xcc -I"$STAGE/include/CCommonCrypto"
    -Xcc -fmodule-map-file="$STAGE/include/COpenAccelerate/module.modulemap"
    -Xcc -I"$STAGE/include/COpenAccelerate"
    -Xcc -fmodule-map-file="$STAGE/include/COpenCompression/module.modulemap"
    -Xcc -I"$STAGE/include/COpenCompression"
    -Xcc -fmodule-map-file="$STAGE/include/zlib/module.modulemap"
    -Xcc -I"$STAGE/include/zlib"
    -Xcc -fmodule-map-file="$STAGE/include/COpenFoundationCore/module.modulemap"
    -Xcc -I"$STAGE/include/COpenFoundationCore"
    -Xcc -fmodule-map-file="$STAGE/include/FoundationICU/_foundation_unicode/module.modulemap"
    -Xcc -I"$STAGE/include/FoundationICU")
FE_FLAGS=(-I "$STAGE/modules"
    -Xcc -fmodule-map-file="$STAGE/include/_FoundationCShims/module.modulemap"
    -Xcc -I"$STAGE/include/_FoundationCShims")
RUNTIME=$STAGE/guest-root
SWIFT_CORE_RUNTIME=$RUNTIME/darwin/usr/lib/swift/libswiftCore.dylib
OBJC_RUNTIME=$RUNTIME/darwin/usr/lib/libobjc.A.dylib
SWIFT_CORE_TBD=$STAGE/sdk/usr/lib/swift/libswiftCore.tbd
[ -f "$SWIFT_CORE_RUNTIME" ] && [ ! -L "$SWIFT_CORE_RUNTIME" ] \
    || die 'staged Swift core runtime is missing or linked'
[ -f "$SWIFT_CORE_TBD" ] && [ ! -L "$SWIFT_CORE_TBD" ] \
    || die 'staged Swift core TBD is missing or linked'
require_hash "$SWIFT_CORE_RUNTIME" "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256" \
    staged-machorun-Swift-core
require_hash "$OBJC_RUNTIME" "$EXPECTED_MACHORUN_OBJC_SHA256" \
    staged-machorun-Objective-C-runtime
swift_core_install_name=$(llvm-otool-18 -D "$SWIFT_CORE_RUNTIME" | tail -n 1)
[ "$swift_core_install_name" = /usr/lib/swift/libswiftCore.dylib ] \
    || die "staged Swift core install name $swift_core_install_name is invalid"
llvm-otool-18 -hv "$SWIFT_CORE_RUNTIME" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'staged Swift core is not an ARM64 Mach-O dylib'
objc_install_name=$(llvm-otool-18 -D "$OBJC_RUNTIME" | tail -n 1)
[ "$objc_install_name" = /usr/lib/libobjc.A.dylib ] \
    || die "staged Objective-C runtime install name $objc_install_name is invalid"
llvm-otool-18 -hv "$OBJC_RUNTIME" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'staged Objective-C runtime is not an ARM64 Mach-O dylib'
swift_core_objc_load_count=$(llvm-otool-18 -L "$SWIFT_CORE_RUNTIME" \
    | awk '$1 == "/usr/lib/libobjc.A.dylib" { count++ } END { print count + 0 }')
[ "$swift_core_objc_load_count" -eq 1 ] \
    || die "Swift core Objective-C runtime load count $swift_core_objc_load_count, expected 1"
swift_core_tbd_symbol_count=$(awk \
    -v symbol="$SWIFT_CORE_REQUIRED_AVAILABILITY_SYMBOL" \
    'index($0, symbol) { count++ } END { print count + 0 }' "$SWIFT_CORE_TBD")
[ "$swift_core_tbd_symbol_count" -eq 1 ] \
    || die "Swift core TBD availability promise count $swift_core_tbd_symbol_count, expected 1"
swift_core_runtime_symbol_count=$(nm_symbol_count --defined-only \
    "$SWIFT_CORE_RUNTIME" "$SWIFT_CORE_REQUIRED_AVAILABILITY_SYMBOL")
[ "$swift_core_runtime_symbol_count" -eq 1 ] \
    || die "Swift core runtime availability export count $swift_core_runtime_symbol_count, expected 1"
{
    printf 'format\tswift-core-runtime-contract-v1\n'
    printf 'runtime\tguest-root/darwin/usr/lib/swift/libswiftCore.dylib\tsha256=%s\tinstall-name=%s\tarchitecture=arm64\n' \
        "$(hash_file "$SWIFT_CORE_RUNTIME")" "$swift_core_install_name"
    printf 'dependency\tguest-root/darwin/usr/lib/libobjc.A.dylib\tsha256=%s\tinstall-name=%s\tload-count=%s\tarchitecture=arm64\n' \
        "$(hash_file "$OBJC_RUNTIME")" "$objc_install_name" \
        "$swift_core_objc_load_count"
    printf 'link-input\tsdk/usr/lib/swift/libswiftCore.tbd\tsha256=%s\n' \
        "$(hash_file "$SWIFT_CORE_TBD")"
    printf 'availability-symbol\t%s\ttbd-promises=%s\truntime-exports=%s\n' \
        "$SWIFT_CORE_REQUIRED_AVAILABILITY_SYMBOL" \
        "$swift_core_tbd_symbol_count" "$swift_core_runtime_symbol_count"
} > "$STAGE/attestation/swift-core-runtime.tsv"
COMMON_LINK=(-rpath @loader_path -L"$STAGE/lib"
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift"
    -lswiftCore -lswiftObjectiveC "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib"
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc
    "$RUNTIME/darwin/usr/lib/libquartz.dylib"
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib")
SWIFTUI_RUNTIME_BASENAME=libswift_Concurrency
SWIFTUI_RUNTIME_LINK_FLAG=-lswift_Concurrency
SWIFTUI_RUNTIME_INSTALL_NAME=/usr/lib/swift/libswift_Concurrency.dylib
FOUNDATION_RUNTIME_BASENAMES=(
    libswift_StringProcessing
    libswiftSynchronization
    libswiftDarwin
    "${SWIFTUI_RUNTIME_BASENAME}"
    libswift_errno
)
FOUNDATION_RUNTIME_LINK_FLAGS=(
    -lswift_StringProcessing
    -lswiftSynchronization
    -lswiftDarwin
    "${SWIFTUI_RUNTIME_LINK_FLAG}"
    -lswift_errno
)
FOUNDATION_RUNTIME_INSTALL_NAMES=(
    /usr/lib/swift/libswift_StringProcessing.dylib
    /usr/lib/swift/libswiftSynchronization.dylib
    /usr/lib/swift/libswiftDarwin.dylib
    "${SWIFTUI_RUNTIME_INSTALL_NAME}"
    /usr/lib/swift/libswift_errno.dylib
)
[ "${#FOUNDATION_RUNTIME_BASENAMES[@]}" -eq 5 ] \
    && [ "${#FOUNDATION_RUNTIME_LINK_FLAGS[@]}" -eq 5 ] \
    && [ "${#FOUNDATION_RUNTIME_INSTALL_NAMES[@]}" -eq 5 ] \
    || die 'Foundation runtime closure cardinality drifted'
for index in "${!FOUNDATION_RUNTIME_BASENAMES[@]}"; do
    library=${FOUNDATION_RUNTIME_BASENAMES[$index]}
    install_name=${FOUNDATION_RUNTIME_INSTALL_NAMES[$index]}
    link_input=$STAGE/sdk/usr/lib/swift/$library.tbd
    runtime_input=$RUNTIME/darwin$install_name
    [ -f "$link_input" ] && [ ! -L "$link_input" ] \
        || die "Foundation runtime link input is missing: $link_input"
    [ -f "$runtime_input" ] && [ ! -L "$runtime_input" ] \
        || die "Foundation staged runtime dylib is missing: $runtime_input"
    actual_id=$(llvm-otool-18 -D "$runtime_input" | tail -n 1)
    [ "$actual_id" = "$install_name" ] \
        || die "Foundation staged runtime ID $actual_id, expected $install_name"
done
swiftui_runtime_link_input=$STAGE/sdk/usr/lib/swift/$SWIFTUI_RUNTIME_BASENAME.tbd
swiftui_runtime_input=$RUNTIME/darwin$SWIFTUI_RUNTIME_INSTALL_NAME
[ -f "$swiftui_runtime_link_input" ] && [ ! -L "$swiftui_runtime_link_input" ] \
    || die "SwiftUI runtime link input is missing: $swiftui_runtime_link_input"
[ -f "$swiftui_runtime_input" ] && [ ! -L "$swiftui_runtime_input" ] \
    || die "SwiftUI staged runtime dylib is missing: $swiftui_runtime_input"
swiftui_runtime_actual_id=$(llvm-otool-18 -D "$swiftui_runtime_input" | tail -n 1)
[ "$swiftui_runtime_actual_id" = "$SWIFTUI_RUNTIME_INSTALL_NAME" ] \
    || die "SwiftUI staged runtime ID $swiftui_runtime_actual_id, expected $SWIFTUI_RUNTIME_INSTALL_NAME"

APPKIT_INSTALL_NAME=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
APPKIT_FRAMEWORK=$STAGE/frameworks/AppKit.framework
APPKIT_VERSIONED=$APPKIT_FRAMEWORK/Versions/C
APPKIT_MODULE_DIR=$APPKIT_VERSIONED/Modules/AppKit.swiftmodule
APPKIT_FRAMEWORK_BINARY=$APPKIT_VERSIONED/AppKit
APPKIT_RUNTIME_FRAMEWORK=$RUNTIME/darwin/System/Library/Frameworks/AppKit.framework
APPKIT_RUNTIME_VERSIONED=$APPKIT_RUNTIME_FRAMEWORK/Versions/C
APPKIT_RUNTIME_BINARY=$APPKIT_RUNTIME_VERSIONED/AppKit
mkdir -p "$APPKIT_MODULE_DIR" "$APPKIT_RUNTIME_VERSIONED"

echo '== build and audit the fail-closed IOKit C framework boundary'
IOKIT_INSTALL_NAME=/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
IOKIT_FRAMEWORK=$STAGE/frameworks/IOKit.framework
IOKIT_FRAMEWORK_BINARY=$IOKIT_FRAMEWORK/IOKit
IOKIT_RUNTIME_FRAMEWORK=$RUNTIME/darwin/System/Library/Frameworks/IOKit.framework
IOKIT_RUNTIME_BINARY=$IOKIT_RUNTIME_FRAMEWORK/Versions/A/IOKit
SWIFT_IOKIT_INSTALL_NAME=/usr/lib/swift/libswiftIOKit.dylib
SWIFT_IOKIT_TBD=$STAGE/sdk/usr/lib/swift/libswiftIOKit.tbd
SWIFT_IOKIT_RUNTIME=$RUNTIME/darwin$SWIFT_IOKIT_INSTALL_NAME
mkdir -p "$IOKIT_FRAMEWORK/Headers" "$IOKIT_FRAMEWORK/Modules" \
    "$IOKIT_RUNTIME_FRAMEWORK/Versions/A"
cp "$W/full/iokit/include/IOKit.h" "$IOKIT_FRAMEWORK/Headers/IOKit.h"
cp "$W/full/iokit/include/module.modulemap" \
    "$IOKIT_FRAMEWORK/Modules/module.modulemap"

clang-18 -std=c11 -O2 -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/iokit/include" "$W/full/iokit/IOKit.c" \
    "$IOKIT_HOST_TEST" -o "$WORK/iokit-host-tests"
"$WORK/iokit-host-tests" > "$STAGE/attestation/iokit-host-test.log"
grep -Fxq \
    'IOKIT_HOST_OK matching=nil services=unsupported iterator=nil properties=nil' \
    "$STAGE/attestation/iokit-host-test.log" \
    || die 'native IOKit fail-closed marker is missing'

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/iokit/include" -c "$W/full/iokit/IOKit.c" \
    -o "$WORK/iokit.o"
"${LD[@]}" -dylib -dead_strip -install_name "$IOKIT_INSTALL_NAME" \
    -o "$IOKIT_FRAMEWORK_BINARY" "$WORK/iokit.o"
cp "$IOKIT_FRAMEWORK_BINARY" "$IOKIT_RUNTIME_BINARY"
ln -s A "$IOKIT_RUNTIME_FRAMEWORK/Versions/Current"
ln -s Versions/Current/IOKit "$IOKIT_RUNTIME_FRAMEWORK/IOKit"

printf '%s\n' \
    _IOBSDNameMatching \
    _IOIteratorNext \
    _IOObjectRelease \
    _IORegistryEntryCreateCFProperty \
    _IORegistryEntrySearchCFProperty \
    _IOServiceGetMatchingServices \
    > "$WORK/iokit-expected-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$IOKIT_FRAMEWORK_BINARY" | LC_ALL=C sort -u \
    > "$WORK/iokit-exports.txt"
cmp "$WORK/iokit-expected-exports.txt" "$WORK/iokit-exports.txt" \
    || die 'IOKit framework exports drifted'
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$IOKIT_FRAMEWORK_BINARY" | LC_ALL=C sort -u \
    > "$WORK/iokit-imports.txt"
[ ! -s "$WORK/iokit-imports.txt" ] \
    || die 'IOKit framework has unexpected undefined imports'
iokit_external_loads=$(llvm-otool-18 -L "$IOKIT_FRAMEWORK_BINARY" \
    | awk 'NR > 2 { count++ } END { print count + 0 }')
[ "$iokit_external_loads" -eq 0 ] \
    || die "IOKit framework external load count $iokit_external_loads, expected 0"
for iokit_binary in "$IOKIT_FRAMEWORK_BINARY" "$IOKIT_RUNTIME_BINARY"; do
    llvm-otool-18 -hv "$iokit_binary" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "IOKit framework is not an ARM64 Mach-O dylib: $iokit_binary"
    [ "$(llvm-otool-18 -D "$iokit_binary" | tail -n 1)" = \
        "$IOKIT_INSTALL_NAME" ] \
        || die "IOKit framework install name drifted: $iokit_binary"
done
cmp "$IOKIT_FRAMEWORK_BINARY" "$IOKIT_RUNTIME_BINARY" \
    || die 'IOKit compile/runtime framework copies differ'
{
    printf 'format\tiokit-framework-v1\n'
    printf 'compile-framework\tframeworks/IOKit.framework/IOKit\tsha256=%s\n' \
        "$(hash_file "$IOKIT_FRAMEWORK_BINARY")"
    printf 'runtime-framework\tguest-root/darwin%s\tsha256=%s\n' \
        "$IOKIT_INSTALL_NAME" "$(hash_file "$IOKIT_RUNTIME_BINARY")"
    printf 'install-name\t%s\n' "$IOKIT_INSTALL_NAME"
    printf 'architecture\tarm64\n'
    printf 'exports\tcount=6\tsha256=%s\n' \
        "$(hash_file "$WORK/iokit-exports.txt")"
    printf 'undefined-imports\tcount=0\n'
    printf 'external-loads\tcount=0\n'
    printf 'policy\tmatching=nil\tservices=unsupported\titerator=nil\tproperties=nil\n'
} > "$STAGE/attestation/iokit-framework.tsv"
printf 'local\tdarwin%s\t%s\tbuilt from full/iokit/IOKit.c\n' \
    "$IOKIT_INSTALL_NAME" "$(hash_file "$IOKIT_RUNTIME_BINARY")" \
    >> "$RUNTIME/.manifest"

echo '== build and audit the complete open Swift IOKit overlay runtime'
[ -f "$SWIFT_IOKIT_TBD" ] && [ ! -L "$SWIFT_IOKIT_TBD" ] \
    || die 'SDK libswiftIOKit TBD is missing or linked'
grep -Fxq "install-name:    '$SWIFT_IOKIT_INSTALL_NAME'" "$SWIFT_IOKIT_TBD" \
    || die 'SDK libswiftIOKit TBD install name drifted'
python3 -B - "$SWIFT_IOKIT_TBD" "$WORK/swift-iokit-tbd-exports.txt" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
symbols = sorted(
    set(
        symbol
        for symbol in re.findall(r"'([^']+)'", source)
        if symbol.startswith("_$s5IOKit")
        or symbol == "__swift_FORCE_LOAD_$_swiftIOKit"
    )
)
Path(sys.argv[2]).write_text("\n".join(symbols) + "\n", encoding="utf-8")
PY
cmp "$SWIFT_IOKIT_EXPORTS" "$WORK/swift-iokit-tbd-exports.txt" \
    || die 'tracked libswiftIOKit export contract differs from the SDK TBD'

clang-18 -std=c11 -O2 -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/iokit" "$W/full/iokit/OpenSwiftIOKitRuntime.c" \
    "$SWIFT_IOKIT_HOST_TEST" -o "$WORK/swift-iokit-host-tests"
"$WORK/swift-iokit-host-tests" \
    > "$STAGE/attestation/swift-iokit-host-test.log"
grep -Fxq 'SWIFT_IOKIT_HOST_OK constants=52 unsupported=0xe00002c7' \
    "$STAGE/attestation/swift-iokit-host-test.log" \
    || die 'native Swift IOKit overlay-runtime marker is missing'

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror -I "$W/full/iokit" \
    -c "$W/full/iokit/OpenSwiftIOKitRuntime.c" \
    -o "$WORK/swift-iokit-runtime.o"
"${LD[@]}" -dylib -dead_strip -install_name "$SWIFT_IOKIT_INSTALL_NAME" \
    -o "$SWIFT_IOKIT_RUNTIME" "$WORK/swift-iokit-runtime.o"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$SWIFT_IOKIT_RUNTIME" | LC_ALL=C sort -u \
    > "$WORK/swift-iokit-runtime-exports.txt"
cmp "$SWIFT_IOKIT_EXPORTS" "$WORK/swift-iokit-runtime-exports.txt" \
    || die 'open libswiftIOKit exports differ from the complete SDK contract'
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$SWIFT_IOKIT_RUNTIME" | LC_ALL=C sort -u \
    > "$WORK/swift-iokit-runtime-imports.txt"
[ ! -s "$WORK/swift-iokit-runtime-imports.txt" ] \
    || die 'open libswiftIOKit has unexpected undefined imports'
swift_iokit_external_loads=$(llvm-otool-18 -L "$SWIFT_IOKIT_RUNTIME" \
    | awk 'NR > 2 { count++ } END { print count + 0 }')
[ "$swift_iokit_external_loads" -eq 0 ] \
    || die "open libswiftIOKit external load count $swift_iokit_external_loads, expected 0"
llvm-otool-18 -hv "$SWIFT_IOKIT_RUNTIME" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'open libswiftIOKit is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$SWIFT_IOKIT_RUNTIME" | tail -n 1)" = \
    "$SWIFT_IOKIT_INSTALL_NAME" ] \
    || die 'open libswiftIOKit install name drifted'
{
    printf 'format\tswift-iokit-runtime-v1\n'
    printf 'runtime\tguest-root/darwin%s\tsha256=%s\n' \
        "$SWIFT_IOKIT_INSTALL_NAME" "$(hash_file "$SWIFT_IOKIT_RUNTIME")"
    printf 'link-input\tsdk/usr/lib/swift/libswiftIOKit.tbd\tsha256=%s\n' \
        "$(hash_file "$SWIFT_IOKIT_TBD")"
    printf 'exports\tcount=53\tsha256=%s\n' \
        "$(hash_file "$WORK/swift-iokit-runtime-exports.txt")"
    printf 'constants\tcount=52\tapple-differential=exact\n'
    printf 'undefined-imports\tcount=0\n'
    printf 'external-loads\tcount=0\n'
} > "$STAGE/attestation/swift-iokit-runtime.tsv"
printf 'local\tdarwin%s\t%s\tbuilt from full/iokit/OpenSwiftIOKitRuntime.c\n' \
    "$SWIFT_IOKIT_INSTALL_NAME" "$(hash_file "$SWIFT_IOKIT_RUNTIME")" \
    >> "$RUNTIME/.manifest"

echo '== build and audit the fixed-ABI Linux URL transport boundary'
URL_TRANSPORT_DARWIN=$RUNTIME/darwin/usr/lib/libOpenURLTransport.dylib
URL_TRANSPORT_HOST=$RUNTIME/host/libOpenURLTransportHost.so
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" \
    -c "$W/full/urltransport/OpenURLTransportBridge.c" \
    -o "$WORK/open-url-transport-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenURLTransport.dylib \
    -o "$URL_TRANSPORT_DARWIN" "$WORK/open-url-transport-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" -shared \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    -o "$URL_TRANSPORT_HOST" -lcurl -pthread
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    "$W/full/urltransport/OpenURLTransportHostTests.c" \
    -o "$WORK/open-url-transport-host-tests" -lcurl -pthread

(
    set -e
    server_port_file=$WORK/url-transport-server.port
    server_log=$WORK/url-transport-server.log
    python3 -B "$W/full/foundation/tests/url_session_test_server.py" \
        --port-file "$server_port_file" >"$server_log" 2>&1 &
    server_pid=$!
    trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
    for _ in $(seq 1 200); do
        [ ! -s "$server_port_file" ] || break
        sleep 0.01
    done
    [ -s "$server_port_file" ] || die 'URL transport test server did not publish its port'
    server_port=$(tr -d '[:space:]' < "$server_port_file")
    "$WORK/open-url-transport-host-tests" "http://127.0.0.1:$server_port" \
        > "$WORK/url-transport-host-test.log"
)
grep -Fx \
    'OPEN_URL_TRANSPORT_HOST_OK bounds=hard,response method=token headers=validated cancel-destroy=race-safe' \
    "$WORK/url-transport-host-test.log" >/dev/null \
    || die 'native URL transport semantic marker is missing'

URL_TRANSPORT_SYMBOLS=(cancel create destroy perform release_response)
URL_TRANSPORT_EXPECTED_ELF=$WORK/url-transport-expected-elf.txt
URL_TRANSPORT_EXPECTED_MACH_EXPORTS=$WORK/url-transport-expected-mach-exports.txt
URL_TRANSPORT_EXPECTED_MACH_IMPORTS=$WORK/url-transport-expected-mach-imports.txt
: > "$URL_TRANSPORT_EXPECTED_ELF"
: > "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS"
: > "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS"
for symbol in "${URL_TRANSPORT_SYMBOLS[@]}"; do
    printf 'openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_ELF"
    printf '_openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS"
    printf '_glibc_openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS"
done
readelf --wide --syms "$URL_TRANSPORT_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_url_transport_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$URL_TRANSPORT_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/url-transport-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$URL_TRANSPORT_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/url-transport-mach-imports.txt"
cmp "$URL_TRANSPORT_EXPECTED_ELF" "$WORK/url-transport-elf-exports.txt" \
    || die 'Linux URL transport helper exports drifted'
cmp "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS" "$WORK/url-transport-mach-exports.txt" \
    || die 'Mach-O URL transport bridge exports drifted'
cmp "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS" "$WORK/url-transport-mach-imports.txt" \
    || die 'Mach-O URL transport host imports drifted'
[ "$(llvm-otool-18 -D "$URL_TRANSPORT_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenURLTransport.dylib ] \
    || die 'Mach-O URL transport install name drifted'
{
    printf 'format\topen-url-transport-abi-v1\n'
    printf 'request-layout\tsize=104\tpointers=64-bit\n'
    printf 'response-layout\tsize=88\tpointers=64-bit\n'
    for symbol in "${URL_TRANSPORT_SYMBOLS[@]}"; do
        printf 'symbol\topenui_url_transport_v1_%s\tguest-export=_openui_url_transport_v1_%s\tguest-host-import=_glibc_openui_url_transport_v1_%s\thost-export=openui_url_transport_v1_%s\n' \
            "$symbol" "$symbol" "$symbol" "$symbol"
    done
} > "$STAGE/attestation/url-transport-abi.tsv"

curl_ca=$(curl-config --ca)
[ -f "$curl_ca" ] && [ ! -L "$curl_ca" ] \
    || die "libcurl CA bundle is not a regular file: $curl_ca"
readelf --wide --dynamic "$URL_TRANSPORT_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-direct-sonames.txt"
ldd "$URL_TRANSPORT_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-transitive-sonames.txt"
{
    printf 'format\topen-url-transport-host-v1\n'
    printf 'libcurl-version\t%s\n' "$(curl-config --version)"
    printf 'tls-backend\t%s\n' "$(curl-config --ssl-backends)"
    printf 'tls-verification\tpeer=required\thost=required\n'
    printf 'redirects\thost-disabled\tguest-owned\n'
    printf 'ca-bundle\t%s\t%s\n' "$curl_ca" "$(hash_file "$curl_ca")"
    while IFS= read -r feature; do
        printf 'feature\t%s\n' "$feature"
    done < <(curl-config --features)
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/url-transport-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$WORK/url-transport-transitive-sonames.txt"
} > "$STAGE/attestation/url-transport-host.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenURLTransport.dylib\t%s\tbuilt from full/urltransport/OpenURLTransportBridge.c\n' \
        "$(hash_file "$URL_TRANSPORT_DARWIN")"
    printf 'local\thost/libOpenURLTransportHost.so\t%s\tbuilt from full/urltransport/OpenURLTransportHost.c\n' \
        "$(hash_file "$URL_TRANSPORT_HOST")"
} >> "$RUNTIME/.manifest"

echo '== build and audit the fixed-ABI ICU relative-time boundary'
RELATIVE_TIME_DARWIN=$RUNTIME/darwin/usr/lib/libOpenRelativeTime.dylib
RELATIVE_TIME_HOST=$RUNTIME/host/libOpenRelativeTimeHost.so
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$WORK/open-relative-time-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -o "$RELATIVE_TIME_DARWIN" "$WORK/open-relative-time-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" -shared \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    -o "$RELATIVE_TIME_HOST" -licui18n -licuuc -lm
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    "$W/full/relativetime/OpenRelativeTimeHostTests.c" \
    -o "$WORK/open-relative-time-host-tests" -licui18n -licuuc -lm
"$WORK/open-relative-time-host-tests" \
    > "$WORK/open-relative-time-host-test.log"
grep -Fx \
    'OPEN_RELATIVE_TIME_HOST_OK icu=real locale=en,fr,de,ja styles=4 bounds=hard' \
    "$WORK/open-relative-time-host-test.log" >/dev/null \
    || die 'native relative-time semantic marker is missing'

printf 'openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-elf.txt"
printf '_openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-mach-exports.txt"
printf '_glibc_openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-mach-imports.txt"
readelf --wide --syms "$RELATIVE_TIME_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_relative_time_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/relative-time-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/relative-time-mach-imports.txt"
cmp "$WORK/relative-time-expected-elf.txt" \
    "$WORK/relative-time-elf-exports.txt" \
    || die 'Linux relative-time helper exports drifted'
cmp "$WORK/relative-time-expected-mach-exports.txt" \
    "$WORK/relative-time-mach-exports.txt" \
    || die 'Mach-O relative-time bridge exports drifted'
cmp "$WORK/relative-time-expected-mach-imports.txt" \
    "$WORK/relative-time-mach-imports.txt" \
    || die 'Mach-O relative-time host imports drifted'
[ "$(llvm-otool-18 -D "$RELATIVE_TIME_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenRelativeTime.dylib ] \
    || die 'Mach-O relative-time install name drifted'

readelf --wide --dynamic "$RELATIVE_TIME_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-direct-sonames.txt"
ldd "$RELATIVE_TIME_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-transitive-sonames.txt"
{
    printf 'format\topen-relative-time-abi-v1\n'
    printf 'symbol\topenui_relative_time_v1_format\tguest-export=_openui_relative_time_v1_format\tguest-host-import=_glibc_openui_relative_time_v1_format\thost-export=openui_relative_time_v1_format\n'
    printf 'limits\tlocale-bytes=256\toutput-bytes=4096\n'
} > "$STAGE/attestation/relative-time-abi.tsv"
{
    printf 'format\topen-relative-time-host-v1\n'
    printf 'icu-version\t%s\n' "$(pkg-config --modversion icu-i18n)"
    printf 'locales\ticu-data-driven\n'
    printf 'styles\tfull,spell-out,short,abbreviated\n'
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/relative-time-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$WORK/relative-time-transitive-sonames.txt"
} > "$STAGE/attestation/relative-time-host.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenRelativeTime.dylib\t%s\tbuilt from full/relativetime/OpenRelativeTimeBridge.c\n' \
        "$(hash_file "$RELATIVE_TIME_DARWIN")"
    printf 'local\thost/libOpenRelativeTimeHost.so\t%s\tbuilt from full/relativetime/OpenRelativeTimeHost.c\n' \
        "$(hash_file "$RELATIVE_TIME_HOST")"
} >> "$RUNTIME/.manifest"

echo '== build and pin the Linux libdispatch scheduling boundary'
for host_runtime_input in "$HOST_DISPATCH_SOURCE" "$HOST_BLOCKS_RUNTIME_SOURCE"; do
    [ -f "$host_runtime_input" ] && [ ! -L "$host_runtime_input" ] \
        || die "host Dispatch runtime input is not a regular file: $host_runtime_input"
done
require_hash "$HOST_DISPATCH_SOURCE" "$EXPECTED_HOST_DISPATCH_SHA256" \
    host-libdispatch
require_hash "$HOST_BLOCKS_RUNTIME_SOURCE" \
    "$EXPECTED_HOST_BLOCKS_RUNTIME_SHA256" host-BlocksRuntime
cp "$HOST_DISPATCH_SOURCE" "$RUNTIME/host/libdispatch.so"
cp "$HOST_BLOCKS_RUNTIME_SOURCE" "$RUNTIME/host/libBlocksRuntime.so"

DISPATCH_HOST=$RUNTIME/host/libOpenDispatchHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift -shared \
    "$W/full/dispatch/OpenDispatchHost.c" \
    -L "$RUNTIME/host" -Wl,-rpath,'$ORIGIN' \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$DISPATCH_HOST"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift \
    "$W/full/dispatch/OpenDispatchHost.c" \
    "$W/full/dispatch/OpenDispatchHostTests.c" \
    -L "$RUNTIME/host" -Wl,-rpath,"$RUNTIME/host" \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$WORK/open-dispatch-host-tests"
LD_LIBRARY_PATH="$RUNTIME/host" "$WORK/open-dispatch-host-tests" \
    > "$WORK/open-dispatch-host-test.log" 2>&1
grep -Fx \
    'OPEN_DISPATCH_HOST_OK global=minted async=worker after=timer main-token=contained glibc>=2.38' \
    "$WORK/open-dispatch-host-test.log" >/dev/null \
    || die 'native Dispatch host semantic marker is missing'

DISPATCH_HOST_EXPECTED_EXPORTS=$WORK/open-dispatch-host-expected-exports.txt
{
    printf '%s\n' \
        openui_dispatch_host_v1_after \
        openui_dispatch_host_v1_async \
        openui_dispatch_host_v1_get_global_queue \
        openui_dispatch_host_v1_main \
        openui_dispatch_host_v1_monotonic_nanoseconds \
        openui_dispatch_host_v1_runtime_check
} > "$DISPATCH_HOST_EXPECTED_EXPORTS"
readelf --wide --syms "$DISPATCH_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_dispatch_host_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/open-dispatch-host-exports.txt"
cmp "$DISPATCH_HOST_EXPECTED_EXPORTS" "$WORK/open-dispatch-host-exports.txt" \
    || die 'Linux Dispatch helper exports drifted'

dispatch_glibc_max=$(readelf --version-info "$RUNTIME/host/libdispatch.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
blocks_glibc_max=$(readelf --version-info "$RUNTIME/host/libBlocksRuntime.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
[ "$dispatch_glibc_max" = GLIBC_2.38 ] \
    || die "staged libdispatch maximum glibc requirement is $dispatch_glibc_max, expected GLIBC_2.38"
[ "$blocks_glibc_max" = GLIBC_2.17 ] \
    || die "staged BlocksRuntime maximum glibc requirement is $blocks_glibc_max, expected GLIBC_2.17"
readelf --wide --dynamic "$DISPATCH_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/open-dispatch-host-sonames.txt"
for required_soname in libdispatch.so libBlocksRuntime.so; do
    grep -Fx "$required_soname" "$WORK/open-dispatch-host-sonames.txt" >/dev/null \
        || die "Linux Dispatch helper does not pin $required_soname"
done
{
    printf 'format\topen-dispatch-host-v1\n'
    printf 'host-abi\tELF64-AArch64\n'
    printf 'glibc-minimum\t2.38\tsource=staged-libdispatch-version-needs\n'
    printf 'runtime\tlibdispatch.so\t%s\tmax-version=%s\n' \
        "$(hash_file "$RUNTIME/host/libdispatch.so")" "$dispatch_glibc_max"
    printf 'runtime\tlibBlocksRuntime.so\t%s\tmax-version=%s\n' \
        "$(hash_file "$RUNTIME/host/libBlocksRuntime.so")" "$blocks_glibc_max"
    printf 'helper\tlibOpenDispatchHost.so\t%s\trpath=$ORIGIN\n' \
        "$(hash_file "$DISPATCH_HOST")"
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/open-dispatch-host-sonames.txt"
    printf 'queue-policy\tmain=kind-only\tglobal=helper-minted-only\n'
    printf 'job-policy\tguest-callback=opaque\thost-dispatch=dispatch_async_f\n'
} > "$STAGE/attestation/open-dispatch-host.tsv"
cp "$WORK/open-dispatch-host-test.log" \
    "$STAGE/attestation/open-dispatch-host-test.log"

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenDispatch" \
    -c "$W/full/dispatch/OpenDispatchBridge.c" \
    -o "$WORK/open-dispatch-bridge.o"
DISPATCH_DARWIN=$RUNTIME/darwin/usr/lib/libOpenDispatch.dylib
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenDispatch.dylib \
    -o "$DISPATCH_DARWIN" "$WORK/open-dispatch-bridge.o"
{
    printf '%s\n' \
        _openui_dispatch_v1_after \
        _openui_dispatch_v1_async \
        _openui_dispatch_v1_get_global_queue \
        _openui_dispatch_v1_monotonic_nanoseconds
} > "$WORK/open-dispatch-mach-expected-exports.txt"
{
    printf '%s\n' \
        _glibc_openui_dispatch_host_v1_after \
        _glibc_openui_dispatch_host_v1_async \
        _glibc_openui_dispatch_host_v1_get_global_queue \
        _glibc_openui_dispatch_host_v1_monotonic_nanoseconds
} > "$WORK/open-dispatch-mach-expected-imports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$DISPATCH_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/open-dispatch-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$DISPATCH_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/open-dispatch-mach-imports.txt"
cmp "$WORK/open-dispatch-mach-expected-exports.txt" \
    "$WORK/open-dispatch-mach-exports.txt" \
    || die 'Mach-O Dispatch bridge exports drifted'
cmp "$WORK/open-dispatch-mach-expected-imports.txt" \
    "$WORK/open-dispatch-mach-imports.txt" \
    || die 'Mach-O Dispatch bridge host imports drifted'
[ "$(llvm-otool-18 -D "$DISPATCH_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenDispatch.dylib ] \
    || die 'Mach-O Dispatch bridge install name drifted'
{
    printf 'local\tdarwin/usr/lib/libOpenDispatch.dylib\t%s\tbuilt from full/dispatch/OpenDispatchBridge.c\n' \
        "$(hash_file "$DISPATCH_DARWIN")"
    printf 'local\thost/libdispatch.so\t%s\tpinned Swift 6.2.4 Linux libdispatch\n' \
        "$(hash_file "$RUNTIME/host/libdispatch.so")"
    printf 'local\thost/libBlocksRuntime.so\t%s\tpinned Swift 6.2.4 BlocksRuntime\n' \
        "$(hash_file "$RUNTIME/host/libBlocksRuntime.so")"
    printf 'local\thost/libOpenDispatchHost.so\t%s\tbuilt from full/dispatch/OpenDispatchHost.c\n' \
        "$(hash_file "$DISPATCH_HOST")"
} >> "$RUNTIME/.manifest"

echo '== prove Accelerate vImage against the frozen Apple transcript'
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenAccelerate" \
    "$W/full/accelerate/Accelerate.c" "$ACCELERATE_ORACLE" \
    -o "$WORK/accelerate-native-oracle"
"$WORK/accelerate-native-oracle" > "$WORK/accelerate-native-oracle.log"
cmp "$ACCELERATE_GOLDEN" "$WORK/accelerate-native-oracle.log" \
    || die 'portable Accelerate output differs from Apple'

echo '== build and audit the fixed-ABI Brotli Compression boundary'
BROTLI_DECODER=$(readlink -f /lib/aarch64-linux-gnu/libbrotlidec.so.1)
BROTLI_ENCODER=$(readlink -f /lib/aarch64-linux-gnu/libbrotlienc.so.1)
BROTLI_COMMON=$(readlink -f /lib/aarch64-linux-gnu/libbrotlicommon.so.1)
for brotli_library in "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"; do
    [ -f "$brotli_library" ] && [ ! -L "$brotli_library" ] \
        || die "pinned Brotli runtime is not a regular file: $brotli_library"
    case "$brotli_library" in
        /usr/lib/aarch64-linux-gnu/libbrotli*.so.1.1.0) ;;
        *) die "pinned Brotli runtime resolved outside the exact closure: $brotli_library" ;;
    esac
done
COMPRESSION_HOST=$RUNTIME/host/libOpenCompressionHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenCompression" -shared \
    "$W/full/compression/OpenCompressionHost.c" \
    -o "$COMPRESSION_HOST" \
    "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenCompression" \
    "$W/full/compression/OpenCompressionHost.c" "$COMPRESSION_HOST_TEST" \
    -o "$WORK/open-compression-host-tests" \
    "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"
"$WORK/open-compression-host-tests" \
    > "$WORK/open-compression-host-test.log"
grep -Fx \
    'OPEN_COMPRESSION_HOST_OK algorithm=brotli roundtrip=exact malformed=fail-closed limit=hard abi=v1' \
    "$WORK/open-compression-host-test.log" >/dev/null \
    || die 'native Compression semantic marker is missing'

printf '%s\n' openui_compression_v1_release openui_compression_v1_transform \
    > "$WORK/open-compression-expected-elf.txt"
readelf --wide --syms "$COMPRESSION_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_compression_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/open-compression-elf-exports.txt"
cmp "$WORK/open-compression-expected-elf.txt" \
    "$WORK/open-compression-elf-exports.txt" \
    || die 'Linux Compression helper exports drifted'
readelf --wide --file-header "$COMPRESSION_HOST" \
    | grep -Fq 'Machine:                           AArch64' \
    || die 'Linux Compression helper is not ELF AArch64'

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenCompression" \
    -c "$W/full/compression/OpenCompressionBridge.c" \
    -o "$WORK/open-compression-bridge.o"
printf '%s\n' _openui_compression_v1_release _openui_compression_v1_transform \
    > "$WORK/open-compression-expected-mach-exports.txt"
printf '%s\n' _glibc_openui_compression_v1_release _glibc_openui_compression_v1_transform \
    > "$WORK/open-compression-expected-mach-imports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$WORK/open-compression-bridge.o" | LC_ALL=C sort -u \
    > "$WORK/open-compression-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$WORK/open-compression-bridge.o" | LC_ALL=C sort -u \
    > "$WORK/open-compression-mach-imports.txt"
cmp "$WORK/open-compression-expected-mach-exports.txt" \
    "$WORK/open-compression-mach-exports.txt" \
    || die 'Mach-O Compression bridge exports drifted'
cmp "$WORK/open-compression-expected-mach-imports.txt" \
    "$WORK/open-compression-mach-imports.txt" \
    || die 'Mach-O Compression host imports drifted'

# Host fallback is intentionally available only to images that machorun
# loaded from its Darwin runtime root.  Keep the `_glibc_*` imports in this
# private runtime bridge; the app-rpath Compression framework links to the
# bridge and therefore never asks a package-local image to cross into ELF.
COMPRESSION_DARWIN=$RUNTIME/darwin/usr/lib/libOpenCompression.dylib
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenCompression.dylib \
    -o "$COMPRESSION_DARWIN" "$WORK/open-compression-bridge.o"
llvm-otool-18 -hv "$COMPRESSION_DARWIN" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'Mach-O Compression bridge is not an ARM64 dylib'
[ "$(llvm-otool-18 -D "$COMPRESSION_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenCompression.dylib ] \
    || die 'Mach-O Compression bridge install name drifted'
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$COMPRESSION_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/open-compression-darwin-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$COMPRESSION_DARWIN" \
    | awk '$0 ~ /^_glibc_openui_compression_v1_/ { print }' \
    | LC_ALL=C sort -u > "$WORK/open-compression-darwin-host-imports.txt"
cmp "$WORK/open-compression-expected-mach-exports.txt" \
    "$WORK/open-compression-darwin-exports.txt" \
    || die 'Mach-O Compression bridge dylib exports drifted'
cmp "$WORK/open-compression-expected-mach-imports.txt" \
    "$WORK/open-compression-darwin-host-imports.txt" \
    || die 'Mach-O Compression bridge dylib host imports drifted'

readelf --wide --dynamic "$COMPRESSION_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/open-compression-direct-sonames.txt"
ldd "$COMPRESSION_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$WORK/open-compression-transitive-sonames.txt"
for required_soname in libbrotlidec.so.1 libbrotlienc.so.1 libbrotlicommon.so.1; do
    grep -Fx "$required_soname" "$WORK/open-compression-transitive-sonames.txt" >/dev/null \
        || die "Linux Compression closure does not contain $required_soname"
done
{
    printf 'format\topen-compression-host-v1\n'
    printf 'host-abi\tELF64-AArch64\n'
    printf 'algorithm\tbrotli\tencode=real\tdecode=real\n'
    printf 'limits\tguest-input=256MiB\tguest-output=256MiB\n'
    printf 'apple-transcript\t%s\n' "$(hash_file "$W/full/compression/tests/compression-brotli-apple-2026-09-01.txt")"
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/open-compression-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$WORK/open-compression-transitive-sonames.txt"
} > "$STAGE/attestation/open-compression-host.tsv"
cp "$WORK/open-compression-host-test.log" \
    "$STAGE/attestation/open-compression-host-test.log"
{
    printf 'format\topen-compression-abi-v1\n'
    printf 'response-layout\tsize=24\tpointers=64-bit\n'
    printf 'symbol\topenui_compression_v1_transform\tguest-export=_openui_compression_v1_transform\tguest-host-import=_glibc_openui_compression_v1_transform\thost-export=openui_compression_v1_transform\n'
    printf 'symbol\topenui_compression_v1_release\tguest-export=_openui_compression_v1_release\tguest-host-import=_glibc_openui_compression_v1_release\thost-export=openui_compression_v1_release\n'
} > "$STAGE/attestation/open-compression-abi.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenCompression.dylib\t%s\tbuilt from full/compression/OpenCompressionBridge.c\n' \
        "$(hash_file "$COMPRESSION_DARWIN")"
    printf 'local\thost/libOpenCompressionHost.so\t%s\tbuilt from full/compression/OpenCompressionHost.c\n' \
        "$(hash_file "$COMPRESSION_HOST")"
} >> "$RUNTIME/.manifest"

echo '== build and audit the fixed-ABI zlib gzip boundary'
ZLIB_NATIVE=$(readlink -f /lib/aarch64-linux-gnu/libz.so.1)
[ -f "$ZLIB_NATIVE" ] && [ ! -L "$ZLIB_NATIVE" ] \
    || die "pinned zlib runtime is not a regular file: $ZLIB_NATIVE"
[ "$ZLIB_NATIVE" = /usr/lib/aarch64-linux-gnu/libz.so.1.3 ] \
    || die "pinned zlib runtime resolved outside the exact closure: $ZLIB_NATIVE"
ZLIB_HOST=$RUNTIME/host/libOpenZlibHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenZlib" -shared \
    -Wl,-soname,libOpenZlibHost.so \
    "$W/full/zlib/OpenZlibHost.c" -o "$ZLIB_HOST" "$ZLIB_NATIVE"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenZlib" \
    "$W/full/zlib/OpenZlibHost.c" "$ZLIB_HOST_TEST" \
    -o "$WORK/open-zlib-host-tests" "$ZLIB_NATIVE"
"$WORK/open-zlib-host-tests" > "$WORK/open-zlib-host-test.log"
grep -Eq \
    '^OPEN_ZLIB_HOST_OK abi=v1 host=1\.[0-9.]+ gzip=exact malformed=fail-closed$' \
    "$WORK/open-zlib-host-test.log" \
    || die 'native zlib semantic marker is missing'

printf '%s\n' open_zlib_abi_version open_zlib_host_version \
    open_zlib_inflate open_zlib_inflate_end open_zlib_inflate_init2 \
    > "$WORK/open-zlib-expected-elf.txt"
readelf --wide --syms "$ZLIB_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^open_zlib_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/open-zlib-elf-exports.txt"
cmp "$WORK/open-zlib-expected-elf.txt" "$WORK/open-zlib-elf-exports.txt" \
    || die 'Linux zlib helper exports drifted'
readelf --wide --file-header "$ZLIB_HOST" \
    | grep -Fq 'Machine:                           AArch64' \
    || die 'Linux zlib helper is not ELF AArch64'
readelf --wide --dynamic "$ZLIB_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/open-zlib-direct-sonames.txt"
grep -Fx libz.so.1 "$WORK/open-zlib-direct-sonames.txt" >/dev/null \
    || die 'Linux zlib helper does not load libz.so.1'

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/zlib" -I "$STAGE/include/COpenZlib" \
    -c "$W/full/zlib/OpenZlibBridge.c" -o "$WORK/open-zlib-bridge.o"
printf '%s\n' _inflate _inflateEnd _inflateInit2_ _zlibVersion \
    > "$WORK/open-zlib-expected-mach-exports.txt"
printf '%s\n' _glibc_open_zlib_abi_version _glibc_open_zlib_inflate \
    _glibc_open_zlib_inflate_end _glibc_open_zlib_inflate_init2 \
    > "$WORK/open-zlib-expected-mach-imports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$WORK/open-zlib-bridge.o" | LC_ALL=C sort -u \
    > "$WORK/open-zlib-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$WORK/open-zlib-bridge.o" | LC_ALL=C sort -u \
    > "$WORK/open-zlib-mach-imports.txt"
cmp "$WORK/open-zlib-expected-mach-exports.txt" \
    "$WORK/open-zlib-mach-exports.txt" \
    || die 'Mach-O zlib bridge exports drifted'
cmp "$WORK/open-zlib-expected-mach-imports.txt" \
    "$WORK/open-zlib-mach-imports.txt" \
    || die 'Mach-O zlib host imports drifted'

# As with the other fixed host ABIs, only a Darwin-root image owns the
# `_glibc_*` escape hatch.  libz.dylib below is an app-facing re-export facade;
# this private bridge is the sole host-bound implementation image.
ZLIB_DARWIN=$RUNTIME/darwin/usr/lib/libOpenZlib.dylib
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenZlib.dylib \
    -o "$ZLIB_DARWIN" "$WORK/open-zlib-bridge.o" \
    -L"$STAGE/sdk/usr/lib" -lSystem
llvm-otool-18 -hv "$ZLIB_DARWIN" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'Mach-O zlib bridge is not an ARM64 dylib'
[ "$(llvm-otool-18 -D "$ZLIB_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenZlib.dylib ] \
    || die 'Mach-O zlib bridge install name drifted'
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$ZLIB_DARWIN" \
    | awk '$0 == "_inflate" || $0 == "_inflateEnd" || \
        $0 == "_inflateInit2_" || $0 == "_zlibVersion" { print }' \
    | LC_ALL=C sort -u > "$WORK/open-zlib-darwin-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$ZLIB_DARWIN" \
    | awk '$0 ~ /^_glibc_open_zlib_/ { print }' | LC_ALL=C sort -u \
    > "$WORK/open-zlib-darwin-host-imports.txt"
cmp "$WORK/open-zlib-expected-mach-exports.txt" \
    "$WORK/open-zlib-darwin-exports.txt" \
    || die 'Mach-O zlib bridge dylib exports drifted'
cmp "$WORK/open-zlib-expected-mach-imports.txt" \
    "$WORK/open-zlib-darwin-host-imports.txt" \
    || die 'Mach-O zlib bridge dylib host imports drifted'

swiftc -module-cache-path "$WORK/zlib-native-module-cache" \
    -Xcc -fmodule-map-file="$STAGE/include/zlib/module.modulemap" \
    -Xcc -I"$STAGE/include/zlib" \
    "$ZLIB_ORACLE" -L/usr/lib/aarch64-linux-gnu -lz \
    -o "$WORK/zlib-native-oracle"
"$WORK/zlib-native-oracle" > "$WORK/zlib-native-oracle.log"
cmp "$ZLIB_GOLDEN" "$WORK/zlib-native-oracle.log" \
    || die 'portable zlib output differs from Apple'
{
    printf 'format\topen-zlib-host-v1\n'
    printf 'host-abi\tELF64-AArch64\n'
    printf 'stream-layout\tsize=112\tpointers=64-bit\n'
    printf 'algorithm\tgzip\tdecode=real\tmalformed=fail-closed\n'
    printf 'native-library\t%s\t%s\n' "$ZLIB_NATIVE" "$(hash_file "$ZLIB_NATIVE")"
    printf 'apple-transcript\t%s\n' "$(hash_file "$ZLIB_GOLDEN")"
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/open-zlib-direct-sonames.txt"
} > "$STAGE/attestation/open-zlib-host.tsv"
cp "$WORK/open-zlib-host-test.log" \
    "$STAGE/attestation/open-zlib-host-test.log"
{
    printf 'format\topen-zlib-abi-v1\n'
    printf 'stream-layout\tsize=112\tnext-in=0\tavail-in=8\tnext-out=24\tstate=56\treserved=104\n'
    printf 'guest-exports\tinflate,inflateEnd,inflateInit2_,zlibVersion\n'
    printf 'host-imports\t_glibc_open_zlib_abi_version,_glibc_open_zlib_inflate,_glibc_open_zlib_inflate_end,_glibc_open_zlib_inflate_init2\n'
} > "$STAGE/attestation/open-zlib-abi.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenZlib.dylib\t%s\tbuilt from full/zlib/OpenZlibBridge.c\n' \
        "$(hash_file "$ZLIB_DARWIN")"
    printf 'local\thost/libOpenZlibHost.so\t%s\tbuilt from full/zlib/OpenZlibHost.c\n' \
        "$(hash_file "$ZLIB_HOST")"
} >> "$RUNTIME/.manifest"
EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$URL_TRANSPORT_HOST:$RELATIVE_TIME_HOST:$COMPRESSION_HOST:$ZLIB_HOST

echo '== prove pinned Darwin group lookup adapters and native ABI agreement'
LIBSYSTEM_REAL=$RUNTIME/darwin/usr/lib/libSystem.real.dylib
[ -f "$LIBSYSTEM_REAL" ] && [ ! -L "$LIBSYSTEM_REAL" ] \
    || die 'staged libSystem.real implementation image is missing'
[ "$(llvm-otool-18 -D "$LIBSYSTEM_REAL" | tail -n 1)" = \
    /usr/lib/libSystem.real.dylib ] \
    || die 'staged libSystem.real install name drifted'
for symbol in _nan _remquo; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
        | awk -v expected="$symbol" \
            '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
GROUP_FIXTURE=$MACHORUN/tests/bin/grp
GROUP_GOLDEN=$MACHORUN/tests/expected/grp.stdout
GROUP_SOURCE=$MACHORUN/tests/src/grp.c
require_hash "$GROUP_FIXTURE" "$EXPECTED_MACHORUN_GROUP_FIXTURE_SHA" \
    machorun-group-fixture
require_hash "$GROUP_GOLDEN" "$EXPECTED_MACHORUN_GROUP_GOLDEN_SHA" \
    machorun-group-golden
require_hash "$GROUP_SOURCE" "$EXPECTED_MACHORUN_GROUP_SOURCE_SHA" \
    machorun-group-source
for symbol in _getgrgid _getgrgid_r _getgrnam _getgrnam_r; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
clang-18 -D_DEFAULT_SOURCE=1 -std=c11 -O2 -Wall -Wextra -Werror \
    "$GROUP_SOURCE" -o "$WORK/group-lookup-native"
"$WORK/group-lookup-native" > "$WORK/group-lookup-native.log"
# Darwin's non-reentrant getgrgid/getgrnam pair shares one static record;
# glibc uses distinct records. That storage-identity difference is contractual,
# while every _r layout/buffer/errno/not-found line is common and compared.
grep -Fx '  static storage reused 0' "$WORK/group-lookup-native.log" >/dev/null \
    || die 'native Linux group static-storage contract drifted'
awk '$0 == "  static storage reused 0" { $0 = "  static storage reused 1" }
     { print }' "$WORK/group-lookup-native.log" \
    > "$WORK/group-lookup-native.normalized.log"
cmp "$GROUP_GOLDEN" "$WORK/group-lookup-native.normalized.log" \
    || die 'native Linux group reentrant/layout contract differs from Darwin'
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$GROUP_FIXTURE" \
    > "$WORK/group-lookup-macho.log"
cmp "$GROUP_GOLDEN" "$WORK/group-lookup-macho.log" \
    || die 'Mach-O Darwin group lookup differs from the pinned native contract'
printf '%s\n' \
    'OPEN_FOUNDATION_GROUP_LOOKUP_OK layout=32,0,8,16,24 reentrant=gid,name,erange,not-found static=gid,name' \
    >> "$WORK/group-lookup-macho.log"

echo '== prove pinned Darwin extended-attribute translation'
XATTR_FIXTURE=$MACHORUN/tests/bin/xattr
XATTR_GOLDEN=$MACHORUN/tests/expected/xattr.stdout
XATTR_SOURCE=$MACHORUN/tests/src/xattr.c
require_hash "$XATTR_FIXTURE" "$EXPECTED_MACHORUN_XATTR_FIXTURE_SHA" \
    machorun-xattr-fixture
require_hash "$XATTR_GOLDEN" "$EXPECTED_MACHORUN_XATTR_GOLDEN_SHA" \
    machorun-xattr-golden
require_hash "$XATTR_SOURCE" "$EXPECTED_MACHORUN_XATTR_SOURCE_SHA" \
    machorun-xattr-source
for symbol in _fgetxattr _fsetxattr _getxattr _listxattr _setxattr; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$XATTR_FIXTURE" \
    > "$WORK/xattr-macho.log"
cmp "$XATTR_GOLDEN" "$WORK/xattr-macho.log" \
    || die 'Mach-O Darwin xattr translation differs from its pinned contract'
printf '%s\n' \
    'OPEN_FOUNDATION_XATTR_OK names=darwin-mapped flags=create,replace,nofollow errno=translated list=repacked' \
    >> "$WORK/xattr-macho.log"

echo '== prove genuine Darwin-to-glibc fts ABI translation'
FTS_FIXTURE=$MACHORUN/tests/bin/fts
FTS_GOLDEN=$MACHORUN/tests/expected/fts.stdout
FTS_STDERR=$MACHORUN/tests/expected/fts.stderr
FTS_EXIT=$MACHORUN/tests/expected/fts.exit
FTS_SOURCE=$MACHORUN/tests/src/fts.c
FTS_SUMMARY=$MACHORUN/tests/meta/fts.summary.txt
require_hash "$FTS_FIXTURE" "$EXPECTED_MACHORUN_FTS_FIXTURE_SHA" \
    machorun-fts-fixture
require_hash "$FTS_GOLDEN" "$EXPECTED_MACHORUN_FTS_GOLDEN_SHA" \
    machorun-fts-golden
require_hash "$FTS_STDERR" "$EXPECTED_MACHORUN_FTS_STDERR_SHA" \
    machorun-fts-stderr
require_hash "$FTS_EXIT" "$EXPECTED_MACHORUN_FTS_EXIT_SHA" \
    machorun-fts-exit
require_hash "$FTS_SOURCE" "$EXPECTED_MACHORUN_FTS_SOURCE_SHA" \
    machorun-fts-source
require_hash "$FTS_SUMMARY" "$EXPECTED_MACHORUN_FTS_SUMMARY_SHA" \
    machorun-fts-summary
require_hash "$MACHORUN/darwin/src/posix.c" \
    "$EXPECTED_MACHORUN_FTS_LIBSYSTEM_SOURCE_SHA" machorun-fts-libsystem-source
for symbol in _fts_open _fts_read _fts_children _fts_set _fts_close; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
set +e
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$FTS_FIXTURE" \
    > "$WORK/fts-macho.stdout" 2> "$WORK/fts-macho.stderr"
fts_status=$?
set -e
printf '%s\n' "$fts_status" > "$WORK/fts-macho.exit"
cmp "$FTS_GOLDEN" "$WORK/fts-macho.stdout" \
    || die 'Mach-O Darwin fts translation differs from the Apple golden stdout'
cmp "$FTS_STDERR" "$WORK/fts-macho.stderr" \
    || die 'Mach-O Darwin fts translation produced unexpected stderr'
cmp "$FTS_EXIT" "$WORK/fts-macho.exit" \
    || die 'Mach-O Darwin fts translation produced the wrong exit status'
cp "$WORK/fts-macho.stdout" "$WORK/fts-macho.log"
printf '%s\n' \
    'OPEN_FOUNDATION_FTS_OK abi=72,112 traversal=physical,logical,nostat children=nameonly instructions=skip,follow,again oracle=apple-exact' \
    >> "$WORK/fts-macho.log"

echo '== prove translated Darwin statfs and fstatfs layouts and mount identity'
STATFS_FIXTURE=$MACHORUN/tests/bin/statfs
STATFS_PRODUCTION_PATH=/replay
STATFS_GOLDEN=$MACHORUN/tests/expected/statfs.stdout
STATFS_STDERR=$MACHORUN/tests/expected/statfs.stderr
STATFS_EXIT=$MACHORUN/tests/expected/statfs.exit
STATFS_SOURCE=$MACHORUN/tests/src/statfs.c
STATFS_SUMMARY=$MACHORUN/tests/meta/statfs.summary.txt
require_hash "$STATFS_FIXTURE" "$EXPECTED_MACHORUN_STATFS_FIXTURE_SHA" \
    machorun-statfs-fixture
require_hash "$STATFS_GOLDEN" "$EXPECTED_MACHORUN_STATFS_GOLDEN_SHA" \
    machorun-statfs-golden
require_hash "$STATFS_STDERR" "$EXPECTED_MACHORUN_STATFS_STDERR_SHA" \
    machorun-statfs-stderr
require_hash "$STATFS_EXIT" "$EXPECTED_MACHORUN_STATFS_EXIT_SHA" \
    machorun-statfs-exit
require_hash "$STATFS_SOURCE" "$EXPECTED_MACHORUN_STATFS_SOURCE_SHA" \
    machorun-statfs-source
require_hash "$STATFS_SUMMARY" "$EXPECTED_MACHORUN_STATFS_SUMMARY_SHA" \
    machorun-statfs-summary
require_hash "$MACHORUN/darwin/src/posix.c" \
    "$EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA" \
    machorun-statfs-libsystem-source
[ -d "$STATFS_PRODUCTION_PATH" ] && [ ! -L "$STATFS_PRODUCTION_PATH" ] \
    || die 'production replay mount for the statfs gate is missing or linked'
statfs_primary_type=$(awk -v target="$STATFS_PRODUCTION_PATH" '
    $5 == target {
        for (field = 6; field < NF; field++) {
            if ($field == "-") {
                print $(field + 1)
                found = 1
                exit
            }
        }
    }
    END { if (!found) exit 1 }
' /proc/self/mountinfo) \
    || die "cannot identify the production $STATFS_PRODUCTION_PATH mount type"
statfs_primary_magic=$(stat -f -c %t "$STATFS_PRODUCTION_PATH") \
    || die "cannot identify the production $STATFS_PRODUCTION_PATH filesystem magic"
case "$statfs_primary_type:$statfs_primary_magic" in
    fakeowner:6a656a63|virtiofs:*) ;;
    *) die "production $STATFS_PRODUCTION_PATH filesystem $statfs_primary_type/$statfs_primary_magic is not a pinned Docker Desktop bind type" ;;
esac
for symbol in _statfs _fstatfs '_statfs$INODE64' '_fstatfs$INODE64'; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
set +e
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$STATFS_FIXTURE" "$STATFS_PRODUCTION_PATH" \
    > "$WORK/statfs-macho.stdout" 2> "$WORK/statfs-macho.stderr"
statfs_status=$?
set -e
printf '%s\n' "$statfs_status" > "$WORK/statfs-macho.exit"
cmp "$STATFS_GOLDEN" "$WORK/statfs-macho.stdout" \
    || die 'Mach-O Darwin statfs translation differs from the Apple golden stdout'
cmp "$STATFS_STDERR" "$WORK/statfs-macho.stderr" \
    || die 'Mach-O Darwin statfs translation produced unexpected stderr'
cmp "$STATFS_EXIT" "$WORK/statfs-macho.exit" \
    || die 'Mach-O Darwin statfs translation produced the wrong exit status'
cp "$WORK/statfs-macho.stdout" "$WORK/statfs-macho.log"
printf 'OPEN_FOUNDATION_STATFS_OK primary=%s bind-filesystem=%s bind-magic=%s abi=2168 path-fd=exact mounts=root,nested flags=translated errno=darwin oracle=apple-exact\n' \
    "$STATFS_PRODUCTION_PATH" "$statfs_primary_type" "$statfs_primary_magic" \
    >> "$WORK/statfs-macho.log"

echo '== prove genuine Darwin copyfile and fcopyfile semantics'
COPYFILE_FIXTURE=$MACHORUN/tests/bin/copyfile
COPYFILE_GOLDEN=$MACHORUN/tests/expected/copyfile.stdout
COPYFILE_STDERR=$MACHORUN/tests/expected/copyfile.stderr
COPYFILE_EXIT=$MACHORUN/tests/expected/copyfile.exit
COPYFILE_SOURCE=$MACHORUN/tests/src/copyfile.c
COPYFILE_SUMMARY=$MACHORUN/tests/meta/copyfile.summary.txt
COPYFILE_XATTR_GATE=$MACHORUN/scripts/copyfile_xattr_unavailable.sh
require_hash "$COPYFILE_FIXTURE" "$EXPECTED_MACHORUN_COPYFILE_FIXTURE_SHA" \
    machorun-copyfile-fixture
require_hash "$COPYFILE_GOLDEN" "$EXPECTED_MACHORUN_COPYFILE_GOLDEN_SHA" \
    machorun-copyfile-golden
require_hash "$COPYFILE_STDERR" "$EXPECTED_MACHORUN_COPYFILE_STDERR_SHA" \
    machorun-copyfile-stderr
require_hash "$COPYFILE_EXIT" "$EXPECTED_MACHORUN_COPYFILE_EXIT_SHA" \
    machorun-copyfile-exit
require_hash "$COPYFILE_SOURCE" "$EXPECTED_MACHORUN_COPYFILE_SOURCE_SHA" \
    machorun-copyfile-source
require_hash "$COPYFILE_SUMMARY" "$EXPECTED_MACHORUN_COPYFILE_SUMMARY_SHA" \
    machorun-copyfile-summary
require_hash "$COPYFILE_XATTR_GATE" \
    "$EXPECTED_MACHORUN_COPYFILE_XATTR_GATE_SHA" \
    machorun-copyfile-xattr-unavailable-gate
require_hash "$MACHORUN/darwin/src/posix.c" \
    "$EXPECTED_MACHORUN_COPYFILE_LIBSYSTEM_SOURCE_SHA" \
    machorun-copyfile-libsystem-source
for symbol in _copyfile _fcopyfile _copyfile_state_alloc \
    _copyfile_state_free _copyfile_state_get _copyfile_state_set; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $symbol definition count $definition_count, expected 1"
done
set +e
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$COPYFILE_FIXTURE" \
    > "$WORK/copyfile-macho.stdout" 2> "$WORK/copyfile-macho.stderr"
copyfile_status=$?
set -e
printf '%s\n' "$copyfile_status" > "$WORK/copyfile-macho.exit"
cmp "$COPYFILE_GOLDEN" "$WORK/copyfile-macho.stdout" \
    || die 'Mach-O Darwin copyfile translation differs from the Apple golden stdout'
cmp "$COPYFILE_STDERR" "$WORK/copyfile-macho.stderr" \
    || die 'Mach-O Darwin copyfile translation produced unexpected stderr'
cmp "$COPYFILE_EXIT" "$WORK/copyfile-macho.exit" \
    || die 'Mach-O Darwin copyfile translation produced the wrong exit status'
cp "$WORK/copyfile-macho.stdout" "$WORK/copyfile-macho.log"
printf '%s\n' \
    'OPEN_FOUNDATION_COPYFILE_OK state=owned-paths,pointers objects=regular,symlink,directory data=byte-copy stat=owner,mode,times xattr=darwin-mapped clone=fallback oracle=apple-exact' \
    >> "$WORK/copyfile-macho.log"

# The ordinary Apple differential lives on /tmp, where Linux xattrs work. The
# production package itself is built on Docker Desktop's host bind (fakeowner
# today and virtiofs on earlier releases), where listxattr reports Linux
# EOPNOTSUPP. Exercise that real second route before a Foundation runtime can
# discover it indirectly while copying a bundled font.
COPYFILE_XATTR_UNAVAILABLE_ROOT=$WORK/copyfile-xattr-unavailable-probe
[ ! -e "$COPYFILE_XATTR_UNAVAILABLE_ROOT" ] \
    || die 'copyfile xattr-unavailable probe root already exists'
set +e
LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$RUNTIME" \
    "$RUNTIME/machorun" "$COPYFILE_FIXTURE" \
        "$COPYFILE_XATTR_UNAVAILABLE_ROOT" \
    > "$WORK/copyfile-xattr-unavailable.stdout" \
    2> "$WORK/copyfile-xattr-unavailable.stderr"
copyfile_xattr_status=$?
set -e
printf '%s\n' "$copyfile_xattr_status" \
    > "$WORK/copyfile-xattr-unavailable.exit"
[ "$copyfile_xattr_status" -eq 0 ] \
    || die 'Mach-O copyfile failed on an xattr-unavailable source filesystem'
cmp "$COPYFILE_STDERR" "$WORK/copyfile-xattr-unavailable.stderr" \
    || die 'Mach-O copyfile xattr-unavailable route produced unexpected stderr'
copyfile_xattr_marker_count=$(awk \
    '$0 == "xattr-unavailable fallback=success run-in-place=neutral" { count++ } END { print count + 0 }' \
    "$WORK/copyfile-xattr-unavailable.stdout")
[ "$copyfile_xattr_marker_count" -eq 1 ] \
    || die "copyfile xattr-unavailable marker count $copyfile_xattr_marker_count, expected 1"
awk '$0 != "xattr-unavailable fallback=success run-in-place=neutral"' \
    "$WORK/copyfile-xattr-unavailable.stdout" \
    > "$WORK/copyfile-xattr-unavailable.oracle-projection"
cmp "$COPYFILE_GOLDEN" "$WORK/copyfile-xattr-unavailable.oracle-projection" \
    || die 'copyfile xattr-unavailable route drifted outside its explicit marker'
[ ! -e "$COPYFILE_XATTR_UNAVAILABLE_ROOT" ] \
    || die 'copyfile xattr-unavailable fixture left its probe root behind'
{
    cat "$WORK/copyfile-xattr-unavailable.stdout"
    printf '%s\n' \
        'OPEN_FOUNDATION_COPYFILE_XATTR_UNAVAILABLE_OK source=docker-bindfs errno=EOPNOTSUPP metadata=absent copy=success'
} > "$WORK/copyfile-xattr-unavailable-macho.log"

echo '== remove stale shadows over pinned quota and uname translations'
: > "$WORK/libsystem-compat-macho.log"
for fixture in quota uname; do
    case "$fixture" in
        quota)
            fixture_sha=$EXPECTED_MACHORUN_QUOTA_FIXTURE_SHA
            golden_sha=$EXPECTED_MACHORUN_QUOTA_GOLDEN_SHA
            source_sha=$EXPECTED_MACHORUN_QUOTA_SOURCE_SHA
            adapter_symbol=_quotactl
            ;;
        uname)
            fixture_sha=$EXPECTED_MACHORUN_UNAME_FIXTURE_SHA
            golden_sha=$EXPECTED_MACHORUN_UNAME_GOLDEN_SHA
            source_sha=$EXPECTED_MACHORUN_UNAME_SOURCE_SHA
            adapter_symbol=_uname
            ;;
        *) die "unknown libSystem compatibility fixture: $fixture" ;;
    esac
    fixture_binary=$MACHORUN/tests/bin/$fixture
    fixture_golden=$MACHORUN/tests/expected/$fixture.stdout
    fixture_source=$MACHORUN/tests/src/$fixture.c
    require_hash "$fixture_binary" "$fixture_sha" "machorun-$fixture-fixture"
    require_hash "$fixture_golden" "$golden_sha" "machorun-$fixture-golden"
    require_hash "$fixture_source" "$source_sha" "machorun-$fixture-source"
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$LIBSYSTEM_REAL" \
        | awk -v expected="$adapter_symbol" \
            '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "staged libSystem $adapter_symbol definition count $definition_count, expected 1"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
    MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" "$fixture_binary" \
        > "$WORK/$fixture-macho.actual"
    cmp "$fixture_golden" "$WORK/$fixture-macho.actual" \
        || die "Mach-O $fixture adapter differs from its pinned contract"
    printf 'fixture\t%s\t%s\n' "$fixture" "$(hash_file "$WORK/$fixture-macho.actual")" \
        >> "$WORK/libsystem-compat-macho.log"
done
printf '%s\n' \
    'OPEN_FOUNDATION_LIBSYSTEM_COMPAT_OK quota=darwin-enotsup uname=layout-translated' \
    >> "$WORK/libsystem-compat-macho.log"

FE_OBJECTS=(
    "$FULL/foundation/essentials/FoundationEssentials.o"
    "$FULL/foundation/collections/InternalCollectionsUtilities.o"
    "$FULL/foundation/collections/OrderedCollections.o"
    "$FULL/foundation/collections/_RopeModule.o"
    "$FULL/foundation/os/os.o"
    "$FULL/foundation/cshims/platform_shims.o"
    "$FULL/foundation/cshims/string_shims.o"
    "$FULL/foundation/cshims/uuid.o"
    "$FULL/foundation/essentials/fm_unimplemented.o"
    "$FULL/foundation/essentials/removefile_compat.o"
    "$FULL/foundation/essentials/uuid_compat.o"
)

echo '== link FoundationEssentials before its full internationalization layer'
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libFoundationEssentials.dylib -rpath @loader_path \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
{
    llvm-objdump-18 --macho --bind \
        "$STAGE/lib/libFoundationEssentials.dylib"
    llvm-objdump-18 --macho --lazy-bind \
        "$STAGE/lib/libFoundationEssentials.dylib"
} > "$WORK/foundation-essentials-bindings.txt"
for symbol in _getgrgid_r _getgrnam_r _fgetxattr _fsetxattr \
    _getxattr _listxattr _setxattr _fts_close _fts_open _fts_read _fts_set \
    _statfs _copyfile _fcopyfile _quotactl _uname; do
    binding_count=$(awk -v expected="$symbol" \
        '$NF == expected && $(NF - 1) == "libSystem.real" { count++ }
         END { print count + 0 }' "$WORK/foundation-essentials-bindings.txt")
    [ "$binding_count" -eq 1 ] \
        || die "FoundationEssentials $symbol libSystem.real bind count $binding_count, expected 1"
done
for symbol in _removefile _removefileat _removefile_cancel \
    _removefile_state_alloc _removefile_state_free \
    _removefile_state_get _removefile_state_set; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$STAGE/lib/libFoundationEssentials.dylib" \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }')
    [ "$definition_count" -eq 1 ] \
        || die "FoundationEssentials $symbol definition count $definition_count, expected 1"
done

echo '== build full pinned FoundationInternationalization and 474-TU ICU'
env SUPPORT_ROOT="$W" SWIFT_FOUNDATION="$SWIFT_FOUNDATION" \
    SWIFT_FOUNDATION_ICU="$SWIFT_FOUNDATION_ICU" STAGE="$STAGE" \
    WORK="$WORK" TARGET="$TARGET" MIN_OS="$MIN_OS" \
    FOUNDATION_ICU_JOBS="${FOUNDATION_ICU_JOBS:-8}" \
    bash "$FOUNDATION_INTERNATIONALIZATION_BUILDER"
FOUNDATION_INTL_HOST=$RUNTIME/host/libOpenFoundationInternationalizationHost.so
[ -f "$FOUNDATION_INTL_HOST" ] && [ ! -L "$FOUNDATION_INTL_HOST" ] \
    || die 'FoundationInternationalization Linux helper is missing after build'
PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$URL_TRANSPORT_HOST:$RELATIVE_TIME_HOST:$COMPRESSION_HOST:$ZLIB_HOST

echo '== prewarm a new core-package Darwin module cache'
swiftc -target "$TARGET" -sdk "$STAGE/sdk" \
    -module-cache-path "$MODULE_CACHE" -parse-stdlib -typecheck -e 'import Swift'

echo '== build the portable Dispatch Swift module'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" \
    -I "$STAGE/modules" \
    -module-name Dispatch -module-link-name Dispatch -emit-module \
    -emit-module-path "$STAGE/modules/Dispatch.swiftmodule" \
    -emit-object -o "$WORK/dispatch.o" "$W/full/dispatch/Dispatch.swift"

echo '== build the official Observation runtime and portable helper boundary'
OBSERVATION_SOURCE_PATHS=()
for relative in "${OBSERVATION_SOURCES[@]}"; do
    OBSERVATION_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library -suppress-warnings \
    -module-name Observation -module-link-name swiftObservation \
    -enable-library-evolution -enable-experimental-feature Macros \
    -enable-experimental-feature ExtensionMacros \
    -emit-module -emit-module-path "$STAGE/modules/Observation.swiftmodule" \
    -emit-module-interface-path "$STAGE/modules/Observation.swiftinterface" \
    -emit-object -o "$WORK/observation.o" "${OBSERVATION_SOURCE_PATHS[@]}"
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -c "$W/full/observation/ObservationRuntimeBridge.c" \
    -o "$WORK/observation-runtime-bridge.o"
OBSERVATION_DYLIB=$RUNTIME/darwin/usr/lib/swift/libswiftObservation.dylib
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/swift/libswiftObservation.dylib \
    -o "$OBSERVATION_DYLIB" \
    "$WORK/observation.o" "$WORK/observation-runtime-bridge.o" \
    "$FULL/swiftcorepatch.o" \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore -lswiftObjectiveC "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib"
[ "$(llvm-otool-18 -D "$OBSERVATION_DYLIB" | tail -n 1)" = \
    /usr/lib/swift/libswiftObservation.dylib ] \
    || die 'Observation runtime install name drifted'
llvm-otool-18 -hv "$OBSERVATION_DYLIB" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'Observation runtime is not an ARM64 Mach-O dylib'
if llvm-nm-18 --undefined-only --just-symbol-name "$OBSERVATION_DYLIB" \
    | grep -Eq '^__swift_observation_(lock|tls)_'; then
    die 'Observation runtime retained an unresolved lock/TLS primitive'
fi
observation_protocol_exports=$(llvm-nm-18 --defined-only --extern-only \
    --just-symbol-name "$OBSERVATION_DYLIB" \
    | awk 'index($0, "$s11Observation10ObservableMp") { count++ } \
        END { print count + 0 }')
observation_registrar_exports=$(llvm-nm-18 --defined-only --extern-only \
    --just-symbol-name "$OBSERVATION_DYLIB" \
    | awk 'index($0, "$s11Observation0A9RegistrarV") { count++ } \
        END { print count + 0 }')
[ "$observation_protocol_exports" -eq 1 ] \
    || die "Observation protocol export count $observation_protocol_exports, expected 1"
[ "$observation_registrar_exports" -ge 12 ] \
    || die "Observation registrar export count $observation_registrar_exports, expected at least 12"
printf 'local\tdarwin/usr/lib/swift/libswiftObservation.dylib\t%s\tbuilt from official Swift 6.2.4 Observation sources\n' \
    "$(hash_file "$OBSERVATION_DYLIB")" >> "$RUNTIME/.manifest"

echo '== build pinned OpenCombine and literal Combine'
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$WORK/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$WORK/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
require_hash "$WORK/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_PATCHED_HELPER" patched-OpenCombine-helper
clang++-18 -target "$TARGET" -isysroot "$STAGE/sdk" -stdlib=libc++ \
    -std=c++17 -O2 -I "$STAGE/include/COpenCombineHelpers" \
    -c "$WORK/COpenCombineHelpers.cpp" -o "$WORK/copencombinehelpers.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenCombine.dylib -rpath @loader_path \
    -o "$STAGE/lib/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$WORK/copencombinehelpers.o" \
    "$STAGE/sdk/usr/lib/swift/libswift_Concurrency.tbd" \
    "$STAGE/sdk/usr/lib/swift/libswiftCore.tbd" \
    "$RUNTIME/darwin/usr/lib/libc++abi.dylib" \
    "$STAGE/sdk/usr/lib/libSystem.tbd" \
    "$RUNTIME/darwin/usr/lib/libSystem.real.dylib" \
    "$STAGE/sdk/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" -I "$STAGE/modules" \
    -module-name Combine -emit-module \
    -emit-module-path "$STAGE/modules/Combine.swiftmodule" \
    -emit-object -o "$WORK/combine.o" "$W/full/oracle-opencombine/Combine.swift"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCombine.dylib -rpath @loader_path \
    -reexport_library "$STAGE/lib/libOpenCombine.dylib" \
    -o "$STAGE/lib/libCombine.dylib" "$WORK/combine.o" \
    "$STAGE/sdk/usr/lib/swift/libswiftCore.tbd" "$STAGE/sdk/usr/lib/libSystem.tbd"

echo '== compile the first-party Symbols value model while Foundation is hidden'
mapfile -d '' -t SYMBOLS_SOURCES < <(
    find "$UIKIT/Sources/Symbols" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#SYMBOLS_SOURCES[@]}" -eq "$EXPECTED_SYMBOLS_SWIFT_COUNT" ] \
    || die 'Symbols source count changed before compile'
"${SWIFTC[@]}" -parse-as-library \
    -module-name Symbols -module-link-name Symbols \
    -enable-library-evolution \
    -emit-module -emit-module-path "$STAGE/modules/Symbols.swiftmodule" \
    -emit-module-interface-path "$STAGE/modules/Symbols.swiftinterface" \
    -emit-object -o "$WORK/symbols.o" "${SYMBOLS_SOURCES[@]}"
echo '== compile the ordered app-facing Foundation facade manifest'
mapfile -t FOUNDATION_SOURCES < "$FOUNDATION_SOURCES_MANIFEST"
[ "${#FOUNDATION_SOURCES[@]}" -eq "$EXPECTED_FOUNDATION_SOURCE_COUNT" ] \
    || die 'Foundation source array count changed'
FOUNDATION_SOURCE_PATHS=()
for relative in "${FOUNDATION_SOURCES[@]}"; do
    FOUNDATION_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name Foundation -emit-module \
    -emit-module-path "$STAGE/modules/Foundation.swiftmodule" \
    -emit-object -o "$WORK/foundation.o" "${FOUNDATION_SOURCE_PATHS[@]}"
llvm-nm-18 -u -j "$WORK/foundation.o" | LC_ALL=C sort -u \
    > "$WORK/foundation-undefined-symbols.txt"
for forbidden in _CFErrorGetDomain _CFErrorGetCode _CFErrorCopyUserInfo; do
    [ "$(grep -Fxc "$forbidden" "$WORK/foundation-undefined-symbols.txt")" -eq 0 ] \
        || die "Foundation CFError bridge eagerly imports absent C API: $forbidden"
done
foundation_string_processing_undefineds=$(awk \
    'index($0, "17_StringProcessing") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
foundation_synchronization_undefineds=$(awk \
    'index($0, "15Synchronization") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
foundation_regex_parser_undefineds=$(awk \
    'index($0, "12_RegexParser") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
foundation_darwin_undefineds=$(awk \
    'index($0, "6Darwin") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
[ "$foundation_string_processing_undefineds" -eq \
    "$EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS" ] \
    || die "Foundation StringProcessing undefined count $foundation_string_processing_undefineds, expected $EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS"
[ "$foundation_synchronization_undefineds" -eq \
    "$EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS" ] \
    || die "Foundation Synchronization undefined count $foundation_synchronization_undefineds, expected $EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS"
[ "$foundation_regex_parser_undefineds" -eq \
    "$EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS" ] \
    || die "Foundation RegexParser undefined count $foundation_regex_parser_undefineds, expected $EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS"
[ "$foundation_darwin_undefineds" -eq \
    "$EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS" ] \
    || die "Foundation Darwin undefined count $foundation_darwin_undefineds, expected $EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS"
printf 'Foundation facade direct undefineds: StringProcessing=%s Synchronization=%s RegexParser=%s Darwin=%s\n' \
    "$foundation_string_processing_undefineds" \
    "$foundation_synchronization_undefineds" \
    "$foundation_regex_parser_undefineds" \
    "$foundation_darwin_undefineds"

echo '== compile the versioned AppKit framework module against portable Foundation'
APPKIT_SOURCE_PATHS=()
for relative in "${APPKIT_SOURCES[@]}"; do
    APPKIT_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AppKit -module-link-name AppKit \
    -enable-library-evolution -no-verify-emitted-module-interface \
    -emit-module \
    -emit-module-path \
        "$APPKIT_MODULE_DIR/arm64-apple-macos.swiftmodule" \
    -emit-module-interface-path \
        "$APPKIT_MODULE_DIR/arm64-apple-macos.swiftinterface" \
    -emit-object -o "$WORK/appkit.o" "${APPKIT_SOURCE_PATHS[@]}"
ln -s C "$APPKIT_FRAMEWORK/Versions/Current"
ln -s Versions/Current/AppKit "$APPKIT_FRAMEWORK/AppKit"
ln -s Versions/Current/Modules "$APPKIT_FRAMEWORK/Modules"

echo '== compile the package-owned Swift IOKit overlay against portable Foundation'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IOKit -module-link-name swiftIOKit \
    -import-underlying-module \
    -emit-module -emit-module-path "$STAGE/modules/IOKit.swiftmodule" \
    "$W/full/iokit/IOKit.swift"

# UIKit only imports the Preview-facing compatibility extensions when the
# caller supplied the legacy external Preview inputs.  Compile it before the
# package-owned fallback DeveloperToolsSupport module is made visible so the
# ordinary route does not accidentally acquire the executable-owned Preview
# ABI.
echo '== compile final Foundation-visible UIKit (optional Preview plugin explicit)'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name UIKit -emit-module \
    -emit-module-path "$STAGE/modules/UIKit.swiftmodule" \
    -emit-object -o "$WORK/uikit.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

# SwiftUI's ImageResource API now has a nominal DeveloperToolsSupport
# dependency even when #Preview hosting is disabled.  Preserve the external
# executable/object contract for explicit Preview builds, while making the
# ordinary package self-hosting from the canonical post-Foundation source.
SWIFTUI_DEVELOPER_TOOLS_SUPPORT_LINK_INPUTS=()
if [ "$PREVIEW_ENABLED" -eq 0 ]; then
    echo '== compile package-owned DeveloperToolsSupport for SwiftUI ImageResource'
    "${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
        -module-name DeveloperToolsSupport -emit-module \
        -emit-module-path "$STAGE/modules/DeveloperToolsSupport.swiftmodule" \
        -emit-object -o "$WORK/developertoolsupport-package.o" \
        "$UIKIT/Sources/DeveloperToolsSupport/Preview.swift"
    llvm-otool-18 -hv "$WORK/developertoolsupport-package.o" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
        || die 'package-owned DeveloperToolsSupport object is not ARM64 Mach-O'
    SWIFTUI_DEVELOPER_TOOLS_SUPPORT_LINK_INPUTS+=(
        "$WORK/developertoolsupport-package.o"
    )
fi

echo '== compile SwiftUI against the app-facing Foundation facade'
mapfile -d '' -t SWIFTUI_SOURCES < <(
    find "$UIKIT/Sources/SwiftUI" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#SWIFTUI_SOURCES[@]}" -eq "$EXPECTED_SWIFTUI_SWIFT_COUNT" ] \
    || die 'SwiftUI source count changed before compile'
for relative in "${SWIFTUI_APPKIT_SOURCES[@]}"; do
    SWIFTUI_SOURCES+=("$W/$relative")
done
[ "${#SWIFTUI_SOURCES[@]}" -eq \
    "$((EXPECTED_SWIFTUI_SWIFT_COUNT + EXPECTED_SWIFTUI_APPKIT_SOURCE_COUNT))" ] \
    || die 'SwiftUI production source count changed after AppKit integration'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${OBSERVATION_PLUGIN_FLAGS[@]}" \
    "${OPENUIKIT_PREVIEW_PLUGIN_FLAGS[@]}" \
    "${OPENSWIFTUI_PLUGIN_FLAGS[@]}" \
    -module-name SwiftUI -emit-module \
    -emit-module-path "$STAGE/modules/SwiftUI.swiftmodule" \
    -emit-object -o "$WORK/swiftui.o" "${SWIFTUI_SOURCES[@]}"

echo '== expand packaged SwiftUI Preview and Entry macros in an ordinary client'
swiftui_plugin_expansions=$WORK/swiftui-compiler-plugin-expansions.log
if ! "${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${OPENUIKIT_PREVIEW_PLUGIN_FLAGS[@]}" \
    "${OPENSWIFTUI_PLUGIN_FLAGS[@]}" \
    -Xfrontend -dump-macro-expansions \
    -module-name SwiftUICompilerPluginsProbe -typecheck \
    "$W/full/frameworks/SwiftUICompilerPluginsProbe.swift" \
    > "$swiftui_plugin_expansions" 2>&1; then
    cat "$swiftui_plugin_expansions" >&2
    die 'packaged SwiftUI compiler-plugin client failed'
fi
preview_expansion_count=$(grep -c 'PreviewRegistry' \
    "$swiftui_plugin_expansions" || true)
[ "$preview_expansion_count" -ge 2 ] \
    || die "SwiftUI Preview expansion count $preview_expansion_count, expected at least 2"
grep -Fq '__Key_portableCompilerPluginProbe' "$swiftui_plugin_expansions" \
    || die 'SwiftUI Entry expansion is missing its generated environment key'
printf '%s\n' \
    'SWIFTUI_COMPILER_PLUGINS_OK preview=unnamed,named entry=environment-key transport=library scopes=app,framework,package' \
    > "$STAGE/attestation/swiftui-compiler-plugins.log"

echo '== compile CoreImage overlay and identity-preserving QuartzCore facade'
COREIMAGE_SOURCE_PATHS=()
for relative in "${COREIMAGE_SOURCES[@]}"; do
    COREIMAGE_SOURCE_PATHS+=("$W/$relative")
done
QUARTZCORE_SOURCE_PATHS=()
for relative in "${QUARTZCORE_SOURCES[@]}"; do
    QUARTZCORE_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreImage -import-underlying-module -emit-module \
    -emit-module-path "$STAGE/modules/CoreImage.swiftmodule" \
    -emit-object -o "$WORK/coreimage.o" "${COREIMAGE_SOURCE_PATHS[@]}"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name QuartzCore -emit-module \
    -emit-module-path "$STAGE/modules/QuartzCore.swiftmodule" \
    -emit-object -o "$WORK/quartzcore.o" "${QUARTZCORE_SOURCE_PATHS[@]}"

echo '== compile production Intents and IntentsUI modules'
INTENTS_SOURCE_PATHS=()
for relative in "${INTENTS_SOURCES[@]}"; do
    INTENTS_SOURCE_PATHS+=("$W/$relative")
done
INTENTSUI_SOURCE_PATHS=()
for relative in "${INTENTSUI_SOURCES[@]}"; do
    INTENTSUI_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name Intents -emit-module \
    -emit-module-path "$STAGE/modules/Intents.swiftmodule" \
    -emit-object -o "$WORK/intents.o" "${INTENTS_SOURCE_PATHS[@]}"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IntentsUI -emit-module \
    -emit-module-path "$STAGE/modules/IntentsUI.swiftmodule" \
    -emit-object -o "$WORK/intentsui.o" "${INTENTSUI_SOURCE_PATHS[@]}"

echo '== compile the production first-party WebKit module'
mapfile -t WEBKIT_SOURCES < "$WEBKIT_SOURCES_MANIFEST"
[ "${#WEBKIT_SOURCES[@]}" -eq "$EXPECTED_WEBKIT_SOURCE_COUNT" ] \
    || die 'WebKit source array count changed'
WEBKIT_SOURCE_PATHS=()
for relative in "${WEBKIT_SOURCES[@]}"; do
    WEBKIT_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name WebKit -emit-module \
    -emit-module-path "$STAGE/modules/WebKit.swiftmodule" \
    -emit-object -o "$WORK/webkit.o" "${WEBKIT_SOURCE_PATHS[@]}"
echo '== strict Swift 6 Hackers WebKit/KVO source-surface gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -swift-version 6 \
    -module-name HackersWebKitSurface -typecheck \
    "$HACKERS_WEBKIT_SURFACE"

echo '== compile thirty-eight independent first-party framework modules'
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/CCommonCrypto" \
    -c "$W/full/commoncrypto/CommonDigest.c" \
    -o "$WORK/commoncrypto-c.o"
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenAccelerate" \
    -c "$W/full/accelerate/Accelerate.c" \
    -o "$WORK/accelerate-c.o"
for index in "${!FIRST_PARTY_FRAMEWORKS[@]}"; do
    framework=${FIRST_PARTY_FRAMEWORKS[$index]}
    source_dir=${FIRST_PARTY_SOURCE_DIRS[$index]}
    source_manifest=$W/full/$source_dir/${source_dir}_guest_sources.txt
    mapfile -t framework_sources < "$source_manifest"
    expected_framework_source_count=1
    case "$framework" in
        SwiftData) expected_framework_source_count=$EXPECTED_SWIFTDATA_SOURCE_COUNT ;;
        CoreMedia) expected_framework_source_count=$EXPECTED_COREMEDIA_SOURCE_COUNT ;;
        AVFoundation) expected_framework_source_count=$EXPECTED_AVFOUNDATION_SOURCE_COUNT ;;
        AVKit) expected_framework_source_count=$EXPECTED_AVKIT_SOURCE_COUNT ;;
        Charts) expected_framework_source_count=$EXPECTED_CHARTS_SOURCE_COUNT ;;
        WidgetKit) expected_framework_source_count=$EXPECTED_WIDGETKIT_SOURCE_COUNT ;;
        CoreTransferable) expected_framework_source_count=$EXPECTED_CORETRANSFERABLE_SOURCE_COUNT ;;
        Photos) expected_framework_source_count=$EXPECTED_PHOTOS_SOURCE_COUNT ;;
        PhotosUI) expected_framework_source_count=$EXPECTED_PHOTOSUI_SOURCE_COUNT ;;
        NaturalLanguage) expected_framework_source_count=$EXPECTED_NATURALLANGUAGE_SOURCE_COUNT ;;
        AuthenticationServices) expected_framework_source_count=$EXPECTED_AUTHENTICATIONSERVICES_SOURCE_COUNT ;;
    esac
    [ "${#framework_sources[@]}" -eq "$expected_framework_source_count" ] \
        || die "$framework source manifest cardinality drifted"
    framework_source_paths=()
    for relative in "${framework_sources[@]}"; do
        framework_source_paths+=("$W/$relative")
    done
    framework_compile_flags=()
    if [ "$framework" = Security ]; then
        framework_compile_flags+=(-D OPENUIKIT_PORTABLE_FOUNDATION)
    fi
    if [ "$framework" = SwiftData ]; then
        framework_compile_flags+=(
            -D OPENUIKIT_PORTABLE_SWIFTUI
            "${FOUNDATION_PLUGIN_FLAGS[@]}"
            "${SWIFTDATA_PLUGIN_FLAGS[@]}"
        )
    fi
    if [ "$framework" = WidgetKit ]; then
        framework_compile_flags+=(
            -D OPENUIKIT_PORTABLE_SWIFTUI
        )
    fi
    if [ "$framework" = FoundationModels ]; then
        framework_compile_flags+=("${FOUNDATIONMODELS_PLUGIN_FLAGS[@]}")
    fi
    "${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
        "${framework_compile_flags[@]}" \
        -module-name "$framework" -emit-module \
        -emit-module-path "$STAGE/modules/$framework.swiftmodule" \
        -emit-object -o "$WORK/$source_dir.o" \
        "${framework_source_paths[@]}"
done

echo '== compile the QuickLook SwiftUI cross-import overlay'
mapfile -t QUICKLOOK_SWIFTUI_SOURCES < "$QUICKLOOK_SWIFTUI_SOURCES_MANIFEST"
[ "${#QUICKLOOK_SWIFTUI_SOURCES[@]}" -eq \
    "$EXPECTED_QUICKLOOK_SWIFTUI_SOURCE_COUNT" ] \
    || die 'QuickLook SwiftUI overlay source count drifted'
[ "${QUICKLOOK_SWIFTUI_SOURCES[0]}" = \
    full/quicklook/QuickLookSwiftUI.swift ] \
    || die 'QuickLook SwiftUI overlay source path drifted'
QUICKLOOK_SWIFTUI_SOURCE_PATHS=()
for relative in "${QUICKLOOK_SWIFTUI_SOURCES[@]}"; do
    QUICKLOOK_SWIFTUI_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name _QuickLook_SwiftUI -emit-module \
    -emit-module-path "$STAGE/modules/_QuickLook_SwiftUI.swiftmodule" \
    -emit-object -o "$WORK/quicklook-swiftui.o" \
    "${QUICKLOOK_SWIFTUI_SOURCE_PATHS[@]}"
mkdir -p "$STAGE/modules/QuickLook.swiftcrossimport"
cp "$W/full/quicklook/SwiftUI.swiftoverlay" \
    "$STAGE/modules/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay"

echo '== compile the PhotosUI SwiftUI cross-import overlay'
mapfile -t PHOTOSUI_SWIFTUI_SOURCES < "$PHOTOSUI_SWIFTUI_SOURCES_MANIFEST"
[ "${#PHOTOSUI_SWIFTUI_SOURCES[@]}" -eq \
    "$EXPECTED_PHOTOSUI_SWIFTUI_SOURCE_COUNT" ] \
    || die 'PhotosUI SwiftUI overlay source count drifted'
[ "${PHOTOSUI_SWIFTUI_SOURCES[0]}" = \
    full/photosui/PhotosUISwiftUI.swift ] \
    || die 'PhotosUI SwiftUI overlay source path drifted'
PHOTOSUI_SWIFTUI_SOURCE_PATHS=()
for relative in "${PHOTOSUI_SWIFTUI_SOURCES[@]}"; do
    PHOTOSUI_SWIFTUI_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name _PhotosUI_SwiftUI -emit-module \
    -emit-module-path "$STAGE/modules/_PhotosUI_SwiftUI.swiftmodule" \
    -emit-object -o "$WORK/photosui-swiftui.o" \
    "${PHOTOSUI_SWIFTUI_SOURCE_PATHS[@]}"
mkdir -p "$STAGE/modules/PhotosUI.swiftcrossimport"
cp "$W/full/photosui/SwiftUI.swiftoverlay" \
    "$STAGE/modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay"

echo '== compile the AuthenticationServices SwiftUI cross-import overlay'
mapfile -t AUTHENTICATIONSERVICES_SWIFTUI_SOURCES \
    < "$AUTHENTICATIONSERVICES_SWIFTUI_SOURCES_MANIFEST"
[ "${#AUTHENTICATIONSERVICES_SWIFTUI_SOURCES[@]}" -eq \
    "$EXPECTED_AUTHENTICATIONSERVICES_SWIFTUI_SOURCE_COUNT" ] \
    || die 'AuthenticationServices SwiftUI overlay source count drifted'
[ "${AUTHENTICATIONSERVICES_SWIFTUI_SOURCES[0]}" = \
    full/authenticationservices/AuthenticationServicesSwiftUI.swift ] \
    || die 'AuthenticationServices SwiftUI overlay source path drifted'
AUTHENTICATIONSERVICES_SWIFTUI_SOURCE_PATHS=()
for relative in "${AUTHENTICATIONSERVICES_SWIFTUI_SOURCES[@]}"; do
    AUTHENTICATIONSERVICES_SWIFTUI_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name _AuthenticationServices_SwiftUI -emit-module \
    -emit-module-path \
        "$STAGE/modules/_AuthenticationServices_SwiftUI.swiftmodule" \
    -emit-object -o "$WORK/authenticationservices-swiftui.o" \
    "${AUTHENTICATIONSERVICES_SWIFTUI_SOURCE_PATHS[@]}"
mkdir -p "$STAGE/modules/AuthenticationServices.swiftcrossimport"
cp "$W/full/authenticationservices/SwiftUI.swiftoverlay" \
    "$STAGE/modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"
network_string_processing_undefineds=$(llvm-nm-18 -u -j "$WORK/network.o" \
    | awk 'index($0, "_StringProcessing") { count++ } END { print count + 0 }')
[ "$network_string_processing_undefineds" -eq 0 ] \
    || die "Network has $network_string_processing_undefineds direct StringProcessing undefineds, expected 0"

echo '== final Foundation/UIKit notification identity proof'
echo '== Foundation-only notification selective-reexport proof'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -swift-version 6 -warnings-as-errors \
    -module-name FoundationNotificationPublicImportProbe -emit-module \
    -emit-module-path "$WORK/FoundationNotificationPublicImportProbe.swiftmodule" \
    "$W/full/foundation/notification_foundation_extension_probe.swift"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name CorePackageNotificationIdentityProbe \
    -typecheck \
    "$W/full/foundation/notification_foundation_extension_probe.swift" \
    "$W/full/foundation/notification_uikit_consumer_probe.swift" \
    "$W/full/foundation/notification_direct_import_probe.swift"

echo '== prove SwiftUI publicly reexports full Foundation, Combine and Dispatch'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name SwiftUIFoundationReexportProbe -typecheck \
    "$W/full/frameworks/SwiftUIFoundationReexportProbe.swift"

echo '== link fifty-nine reusable platform dylibs (fifty-seven frameworks, ICU, and zlib)'
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libz.dylib -rpath @loader_path \
    -o "$STAGE/lib/libz.dylib" \
    -reexport_library "$ZLIB_DARWIN" \
    -L"$STAGE/sdk/usr/lib" -lSystem
"${LD[@]}" -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name @rpath/libDispatch.dylib -rpath @loader_path \
    -o "$STAGE/lib/libDispatch.dylib" \
    "$WORK/dispatch.o" "$DISPATCH_DARWIN" \
    "${COMMON_LINK[@]}" -lOpenCombine \
    "$STAGE/sdk/usr/lib/swift/libswiftSynchronization.tbd" \
    "$STAGE/sdk/usr/lib/swift/libswift_Concurrency.tbd"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenCoreGraphics.dylib -rpath @loader_path \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem "$RUNTIME/darwin/usr/lib/libquartz.dylib" \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libOpenCoreGraphics.dylib" "$FULL/opencoregraphics.o"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenUIKit.dylib -rpath @loader_path \
    -L"$STAGE/lib" -lFoundationEssentials -lOpenCoreGraphics \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore -lswiftObjectiveC "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc \
    "$RUNTIME/darwin/usr/lib/libquartz.dylib" \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libOpenUIKit.dylib" "$FULL/openuikit.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libFoundation.dylib -rpath @loader_path \
    -o "$STAGE/lib/libFoundation.dylib" "$WORK/foundation.o" \
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine -lDispatch \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}" "$URL_TRANSPORT_DARWIN" \
    "$RELATIVE_TIME_DARWIN" \
    -reexport_library "$STAGE/lib/libFoundationInternationalization.dylib"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$STAGE/lib/libFoundation.dylib" | LC_ALL=C sort -u \
    > "$WORK/foundation-runtime-exports.txt"
for symbol in \
    '_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF' \
    '_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF' \
    '_$s10Foundation26_ObjectiveCBridgeableErrorMp' \
    '_$sSo10CFErrorRefas5Error10FoundationMc'; do
    [ "$(grep -Fxc "$symbol" "$WORK/foundation-runtime-exports.txt")" -eq 1 ] \
        || die "Foundation runtime bridge export is missing or duplicated: $symbol"
done
{
    llvm-objdump-18 --macho --bind "$STAGE/lib/libFoundation.dylib"
    llvm-objdump-18 --macho --lazy-bind "$STAGE/lib/libFoundation.dylib"
} > "$WORK/foundation-bindings.txt"
foundation_object_identifier_core_bind_count=$(awk \
    '$NF == "_$sSOSHsWP" && $(NF - 1) == "libswiftCore" { count++ }
     END { print count + 0 }' "$WORK/foundation-bindings.txt")
[ "$foundation_object_identifier_core_bind_count" -eq 1 ] \
    || die "libFoundation ObjectIdentifier.Hashable libswiftCore bind count $foundation_object_identifier_core_bind_count, expected 1"
foundation_errno_runtime_bind_count=$(awk \
    '$NF == "_$s6Darwin5errnos5Int32Vvg" && $(NF - 1) == "libswift_errno" { count++ }
     END { print count + 0 }' "$WORK/foundation-bindings.txt")
[ "$foundation_errno_runtime_bind_count" -eq 1 ] \
    || die "libFoundation Darwin.errno libswift_errno bind count $foundation_errno_runtime_bind_count, expected 1"
foundation_graphics_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
[ "$foundation_graphics_load_count" -eq 1 ] \
    || die "libFoundation OpenCoreGraphics load count $foundation_graphics_load_count, expected 1"
for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"; do
    load_count=$(llvm-otool-18 -L "$STAGE/lib/libFoundation.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libFoundation runtime load count $load_count for $install_name, expected 1"
done
foundation_transport_load_count=$(llvm-otool-18 -L "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "/usr/lib/libOpenURLTransport.dylib" { count++ } END { print count + 0 }')
[ "$foundation_transport_load_count" -eq 1 ] \
    || die "libFoundation URL transport load count $foundation_transport_load_count, expected 1"
foundation_relative_time_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "/usr/lib/libOpenRelativeTime.dylib" { count++ } END { print count + 0 }')
[ "$foundation_relative_time_load_count" -eq 1 ] \
    || die "libFoundation relative-time load count $foundation_relative_time_load_count, expected 1"
foundation_internationalization_load_count=$(llvm-otool-18 -l \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "@rpath/libFoundationInternationalization.dylib" && command == "LC_LOAD_DYLIB" { count++ }
        END { print count + 0 }')
foundation_internationalization_reexport_count=$(llvm-otool-18 -l \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "@rpath/libFoundationInternationalization.dylib" && command == "LC_REEXPORT_DYLIB" { count++ }
        END { print count + 0 }')
[ "$foundation_internationalization_load_count" -eq 1 ] \
    || die "libFoundation FoundationInternationalization load command count $foundation_internationalization_load_count, expected 1"
[ "$foundation_internationalization_reexport_count" -eq 1 ] \
    || die "libFoundation FoundationInternationalization reexport command count $foundation_internationalization_reexport_count, expected 1"

echo '== link and audit the production versioned AppKit framework'
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name "$APPKIT_INSTALL_NAME" -rpath @loader_path \
    -o "$APPKIT_FRAMEWORK_BINARY" "$WORK/appkit.o" \
    -L"$STAGE/lib" -L"$RUNTIME/darwin/usr/lib" \
    -L"$STAGE/sdk/usr/lib/swift" \
    -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    -lCombine -lOpenCombine -lDispatch \
    -lswiftCore -lswiftObjectiveC "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$OBSERVATION_DYLIB" \
    "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc \
    "$RUNTIME/darwin/usr/lib/libquartz.dylib" \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib"
cp "$APPKIT_FRAMEWORK_BINARY" "$APPKIT_RUNTIME_BINARY"
ln -s C "$APPKIT_RUNTIME_FRAMEWORK/Versions/Current"
ln -s Versions/Current/AppKit "$APPKIT_RUNTIME_FRAMEWORK/AppKit"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$APPKIT_FRAMEWORK_BINARY" | LC_ALL=C sort -u \
    > "$WORK/appkit-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$APPKIT_FRAMEWORK_BINARY" | LC_ALL=C sort -u \
    > "$WORK/appkit-imports.txt"
llvm-otool-18 -L "$APPKIT_FRAMEWORK_BINARY" \
    > "$WORK/appkit-loads.txt"
awk 'NR > 1 { print $1 }' "$WORK/appkit-loads.txt" \
    > "$WORK/appkit-load-identities.txt"
appkit_export_count=$(wc -l < "$WORK/appkit-exports.txt" \
    | tr -d '[:space:]')
[ "$appkit_export_count" -eq "$EXPECTED_APPKIT_EXPORT_COUNT" ] \
    || die "AppKit export count $appkit_export_count, expected $EXPECTED_APPKIT_EXPORT_COUNT"
[ "$(hash_file "$WORK/appkit-exports.txt")" = \
    "$EXPECTED_APPKIT_EXPORT_SHA" ] \
    || die 'AppKit exact export contract drifted'
[ "$(hash_file "$WORK/appkit-imports.txt")" = \
    "$EXPECTED_APPKIT_IMPORT_SHA" ] \
    || die 'AppKit exact import contract drifted'
cmp "$APPKIT_LOAD_IDENTITIES" "$WORK/appkit-load-identities.txt" \
    || die 'AppKit exact load closure drifted'
for appkit_binary in "$APPKIT_FRAMEWORK_BINARY" "$APPKIT_RUNTIME_BINARY"; do
    llvm-otool-18 -hv "$appkit_binary" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "AppKit framework is not an ARM64 Mach-O dylib: $appkit_binary"
    [ "$(llvm-otool-18 -D "$appkit_binary" | tail -n 1)" = \
        "$APPKIT_INSTALL_NAME" ] \
        || die "AppKit framework install name drifted: $appkit_binary"
done
cmp "$APPKIT_FRAMEWORK_BINARY" "$APPKIT_RUNTIME_BINARY" \
    || die 'AppKit compile/runtime framework copies differ'
[ "$(awk -v expected="$APPKIT_INSTALL_NAME" \
    '$1 == expected { count++ } END { print count + 0 }' \
    "$WORK/appkit-loads.txt")" -eq 1 ] \
    || die 'AppKit self identity is missing or duplicated'
[ "$(awk '$1 == "@rpath/libFoundation.dylib" { count++ } \
    END { print count + 0 }' "$WORK/appkit-loads.txt")" -eq 1 ] \
    || die 'AppKit portable Foundation load is missing or duplicated'
if grep -Fq '/System/Library/Frameworks/Foundation.framework/' \
    "$WORK/appkit-loads.txt"; then
    die 'AppKit loads Apple Foundation rather than the portable runtime'
fi
{
    printf 'format\tappkit-framework-v1\n'
    printf 'compile-framework\tframeworks/AppKit.framework/Versions/C/AppKit\tsha256=%s\n' \
        "$(hash_file "$APPKIT_FRAMEWORK_BINARY")"
    printf 'runtime-framework\tguest-root/darwin%s\tsha256=%s\n' \
        "$APPKIT_INSTALL_NAME" "$(hash_file "$APPKIT_RUNTIME_BINARY")"
    printf 'install-name\t%s\n' "$APPKIT_INSTALL_NAME"
    printf 'architecture\tarm64\n'
    printf 'exports\tcount=%s\tsha256=%s\n' \
        "$appkit_export_count" "$(hash_file "$WORK/appkit-exports.txt")"
    printf 'imports\tcount=%s\tsha256=%s\n' \
        "$(wc -l < "$WORK/appkit-imports.txt" | tr -d '[:space:]')" \
        "$(hash_file "$WORK/appkit-imports.txt")"
    printf 'loads\tcount=16\tsha256=%s\n' \
        "$(hash_file "$WORK/appkit-load-identities.txt")"
    printf 'policy\tui=headless\tworkspace=fail-closed\talert=cancel-or-abort\tfonts=unavailable\n'
} > "$STAGE/attestation/appkit-framework.tsv"
printf 'local\tdarwin%s\t%s\tbuilt from full/appkit/AppKit.swift\n' \
    "$APPKIT_INSTALL_NAME" "$(hash_file "$APPKIT_RUNTIME_BINARY")" \
    >> "$RUNTIME/.manifest"

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSymbols.dylib -rpath @loader_path \
    -o "$STAGE/lib/libSymbols.dylib" "$WORK/symbols.o" \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem
symbols_apple_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSymbols.dylib" \
    | awk '$1 ~ /^\/System\/Library\/Frameworks\/Symbols\.framework\// { count++ } \
        END { print count + 0 }')
[ "$symbols_apple_load_count" -eq 0 ] \
    || die "libSymbols Apple Symbols load count $symbols_apple_load_count, expected 0"
PREVIEW_EXECUTABLE_RESOLUTION_FLAGS=()
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || PREVIEW_EXECUTABLE_RESOLUTION_FLAGS=(-undefined dynamic_lookup)
PREVIEW_STANDALONE_LINK_INPUTS=()
PREVIEW_STANDALONE_EXPORT_FLAGS=()
PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS=()
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    PREVIEW_STANDALONE_LINK_INPUTS+=("$STAGE/objects/developertoolsupport.o")
    PREVIEW_STANDALONE_EXPORT_FLAGS+=(
        -exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL"
    )
    # The canonical DTS ImageResource stores Foundation.Bundle's portable
    # nominal implementation, which is owned by OpenUIKit in this platform.
    PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS+=(-lOpenUIKit)
fi
preview_standalone_dts_input_count=0
for input in "${PREVIEW_STANDALONE_LINK_INPUTS[@]}"; do
    [ "$input" != "$STAGE/objects/developertoolsupport.o" ] \
        || preview_standalone_dts_input_count=$((preview_standalone_dts_input_count + 1))
done
[ "$preview_standalone_dts_input_count" -eq "$PREVIEW_ENABLED" ] \
    || die "standalone SwiftUI DTS link count $preview_standalone_dts_input_count, expected $PREVIEW_ENABLED"
preview_standalone_openuikit_flag_count=0
for input in "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}"; do
    [ "$input" != -lOpenUIKit ] \
        || preview_standalone_openuikit_flag_count=$((preview_standalone_openuikit_flag_count + 1))
done
[ "$preview_standalone_openuikit_flag_count" -eq "$PREVIEW_ENABLED" ] \
    || die "standalone DTS OpenUIKit link count $preview_standalone_openuikit_flag_count, expected $PREVIEW_ENABLED"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSwiftUI.dylib -rpath @loader_path \
    "${PREVIEW_EXECUTABLE_RESOLUTION_FLAGS[@]}" \
    -o "$STAGE/lib/libSwiftUI.dylib" "$WORK/swiftui.o" \
    "${SWIFTUI_DEVELOPER_TOOLS_SUPPORT_LINK_INPUTS[@]}" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols \
    -F "$STAGE/frameworks" -framework AppKit \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "$OBSERVATION_DYLIB" \
    "$FULL/swiftcorepatch.o"
swiftui_foundation_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "@rpath/libFoundation.dylib" { count++ } \
        END { print count + 0 }')
[ "$swiftui_foundation_load_count" -eq 1 ] \
    || die "libSwiftUI Foundation load count $swiftui_foundation_load_count, expected 1"
swiftui_foundation_essentials_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "@rpath/libFoundationEssentials.dylib" { count++ } \
        END { print count + 0 }')
[ "$swiftui_foundation_essentials_load_count" -eq 1 ] \
    || die "libSwiftUI FoundationEssentials load count $swiftui_foundation_essentials_load_count, expected 1"
swiftui_runtime_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk -v expected="$SWIFTUI_RUNTIME_INSTALL_NAME" \
        '$1 == expected { count++ } END { print count + 0 }')
[ "$swiftui_runtime_load_count" -eq 1 ] \
    || die "libSwiftUI runtime load count $swiftui_runtime_load_count for $SWIFTUI_RUNTIME_INSTALL_NAME, expected 1"
swiftui_observation_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "/usr/lib/swift/libswiftObservation.dylib" { count++ } \
        END { print count + 0 }')
[ "$swiftui_observation_load_count" -eq 1 ] \
    || die "libSwiftUI Observation load count $swiftui_observation_load_count, expected 1"
swiftui_symbols_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "@rpath/libSymbols.dylib" { count++ } END { print count + 0 }')
[ "$swiftui_symbols_load_count" -eq 1 ] \
    || die "libSwiftUI Symbols load count $swiftui_symbols_load_count, expected 1"
swiftui_appkit_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk -v expected="$APPKIT_INSTALL_NAME" \
        '$1 == expected { count++ } END { print count + 0 }')
[ "$swiftui_appkit_load_count" -eq 1 ] \
    || die "libSwiftUI AppKit load count $swiftui_appkit_load_count, expected 1"
swiftui_preview_import_count=$(nm_symbol_count --undefined-only \
    "$STAGE/lib/libSwiftUI.dylib" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$swiftui_preview_import_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Preview libSwiftUI initializer import count $swiftui_preview_import_count, expected $PREVIEW_ENABLED"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libUIKit.dylib -rpath @loader_path \
    "${PREVIEW_EXECUTABLE_RESOLUTION_FLAGS[@]}" \
    -o "$STAGE/lib/libUIKit.dylib" "$WORK/uikit.o" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCoreImage.dylib -rpath @loader_path \
    -o "$STAGE/lib/libCoreImage.dylib" "$WORK/coreimage.o" \
    "${COMMON_LINK[@]}" -lOpenCoreGraphics
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libQuartzCore.dylib -rpath @loader_path \
    -o "$STAGE/lib/libQuartzCore.dylib" "$WORK/quartzcore.o" \
    "${COMMON_LINK[@]}" -lOpenUIKit -lOpenCoreGraphics
coreimage_graphics_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libCoreImage.dylib" \
    | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
quartzcore_uikit_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libQuartzCore.dylib" \
    | awk '$1 == "@rpath/libOpenUIKit.dylib" { count++ } END { print count + 0 }')
[ "$coreimage_graphics_load_count" -eq 1 ] \
    || die "libCoreImage OpenCoreGraphics load count $coreimage_graphics_load_count, expected 1"
[ "$quartzcore_uikit_load_count" -eq 1 ] \
    || die "libQuartzCore OpenUIKit load count $quartzcore_uikit_load_count, expected 1"
for framework in CoreImage QuartzCore; do
    if llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | grep -Fq "/System/Library/Frameworks/$framework.framework/"; then
        die "lib$framework loads the Apple $framework framework"
    fi
done

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libIntents.dylib -rpath @loader_path \
    -o "$STAGE/lib/libIntents.dylib" "$WORK/intents.o" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lCombine -lOpenCombine -lswiftSynchronization
intents_runtime_load_count=$(llvm-otool-18 -L "$STAGE/lib/libIntents.dylib" \
    | awk '$1 == "/usr/lib/swift/libswiftSynchronization.dylib" { count++ } END { print count + 0 }')
[ "$intents_runtime_load_count" -eq 1 ] \
    || die "libIntents Synchronization runtime load count $intents_runtime_load_count, expected 1"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libIntentsUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/libIntentsUI.dylib" "$WORK/intentsui.o" \
    "${COMMON_LINK[@]}" -lIntents -lUIKit -lFoundation \
    -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libWebKit.dylib -rpath @loader_path \
    -needed_library "$STAGE/lib/libUIKit.dylib" \
    -needed_library "$STAGE/lib/libFoundation.dylib" \
    -o "$STAGE/lib/libWebKit.dylib" "$WORK/webkit.o" \
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

WEBKIT_REQUIRED_LOADS=(
    @rpath/libUIKit.dylib
    @rpath/libFoundation.dylib
    "$SWIFTUI_RUNTIME_INSTALL_NAME"
)
for install_name in "${WEBKIT_REQUIRED_LOADS[@]}"; do
    load_count=$(llvm-otool-18 -L "$STAGE/lib/libWebKit.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libWebKit load count $load_count for $install_name, expected 1"
done
if llvm-otool-18 -L "$STAGE/lib/libWebKit.dylib" \
    | grep -Fq '/System/Library/Frameworks/WebKit.framework/'; then
    die 'portable libWebKit must not load Apple WebKit.framework'
fi
{
    printf 'format\twebkit-dylib-loads-v1\n'
    printf 'install-id\t@rpath/libWebKit.dylib\n'
    printf 'required-load\t@rpath/libUIKit.dylib\tcount=1\n'
    printf 'required-load\t@rpath/libFoundation.dylib\tcount=1\n'
    printf 'required-load\t%s\tcount=1\n' "$SWIFTUI_RUNTIME_INSTALL_NAME"
    printf 'apple-webkit-framework-load-count\t0\n'
    printf 'rendering-engine\tabsent\n'
} > "$STAGE/attestation/webkit-dylib-loads.tsv"

uikit_preview_import_count=$(nm_symbol_count --undefined-only \
    "$STAGE/lib/libUIKit.dylib" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
uikit_dts_import_count=$(nm_developer_tools_support_count --undefined-only \
    "$STAGE/lib/libUIKit.dylib")
[ "$uikit_preview_import_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Preview libUIKit initializer import count $uikit_preview_import_count, expected $PREVIEW_ENABLED"
[ "$uikit_dts_import_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Preview libUIKit DeveloperToolsSupport import count $uikit_dts_import_count, expected $PREVIEW_ENABLED"

FIRST_PARTY_LOAD_AUDIT=$STAGE/attestation/first-party-dylib-loads.tsv
printf 'format\tfirst-party-dylib-loads-v1\n' > "$FIRST_PARTY_LOAD_AUDIT"
for index in "${!FIRST_PARTY_FRAMEWORKS[@]}"; do
    framework=${FIRST_PARTY_FRAMEWORKS[$index]}
    source_dir=${FIRST_PARTY_SOURCE_DIRS[$index]}
    framework_link_dependencies=(
        -lFoundation
        -lFoundationEssentials
        "$SWIFTUI_RUNTIME_LINK_FLAG"
    )
    framework_link_options=()
    expected_foundation_load=1
    expected_foundation_essentials_load=1
    expected_uikit_load=0
    expected_openuikit_load=0
    expected_opencoregraphics_load=0
    expected_swiftui_load=0
    expected_coremedia_load=0
    expected_avfoundation_load=0
    expected_uniformtypeidentifiers_load=0
    expected_imageio_load=0
    expected_photos_load=0
    expected_dispatch_load=0
    expected_appkit_load=0
    expected_os_runtime_reexport=0
    case "$framework" in
        SafariServices|StoreKit|PassKit|MessageUI|AppIntents|QuickLook)
            expected_uikit_load=1
            expected_openuikit_load=1
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lUIKit
                -lOpenUIKit
                -lOpenCoreGraphics
            )
            if [ "$framework" = StoreKit ]; then
                expected_appkit_load=1
                framework_link_dependencies+=(
                    -F "$STAGE/frameworks"
                    -framework AppKit
                )
            fi
            ;;
        CoreGraphics)
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lOpenCoreGraphics
            )
            ;;
        ImageIO)
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lCoreGraphics
                -lOpenCoreGraphics
                "$RUNTIME/darwin/usr/lib/libquartz.dylib"
            )
            ;;
        OSLog)
            # The public OSLog module re-exports the existing `os` identities.
            # Their implementation lives in FoundationEssentials, so make that
            # relationship a real Mach-O re-export instead of duplicating Logger.
            # Pinned ld64.lld-18 encodes an explicit re-export as one ordinary
            # load plus one LC_REEXPORT_DYLIB for the same install name. Audit
            # both commands independently instead of mistaking the pair for
            # two runtime implementations.
            expected_foundation_load=0
            expected_foundation_essentials_load=2
            expected_os_runtime_reexport=1
            unset 'framework_link_dependencies[0]'
            unset 'framework_link_dependencies[1]'
            framework_link_dependencies+=(
                -reexport_library "$STAGE/lib/libFoundationEssentials.dylib"
            )
            ;;
        SwiftData)
            expected_swiftui_load=1
            framework_link_dependencies+=(
                -lSwiftUI
                "$OBSERVATION_DYLIB"
            )
            ;;
        AVFoundation)
            expected_coremedia_load=1
            expected_openuikit_load=1
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lCoreMedia
                -lOpenUIKit
                -lOpenCoreGraphics
            )
            ;;
        AVKit)
            expected_uikit_load=1
            expected_openuikit_load=1
            expected_opencoregraphics_load=1
            expected_swiftui_load=1
            expected_avfoundation_load=1
            framework_link_dependencies+=(
                -lAVFoundation
                -lSwiftUI
                -lUIKit
                -lOpenUIKit
                -lOpenCoreGraphics
            )
            ;;
        Charts)
            expected_swiftui_load=1
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lSwiftUI
                -lOpenCoreGraphics
            )
            ;;
        WidgetKit)
            expected_swiftui_load=1
            expected_opencoregraphics_load=1
            framework_link_dependencies+=(
                -lSwiftUI
                -lAppIntents
                -lIntents
                -lOpenCoreGraphics
            )
            ;;
        CoreTransferable)
            expected_uniformtypeidentifiers_load=1
            framework_link_dependencies+=(
                -lUniformTypeIdentifiers
            )
            ;;
        Photos)
            expected_uikit_load=1
            expected_openuikit_load=1
            expected_opencoregraphics_load=1
            expected_imageio_load=1
            framework_link_dependencies+=(
                -lUIKit
                -lOpenUIKit
                -lCoreGraphics
                -lOpenCoreGraphics
                -lImageIO
            )
            ;;
        PhotosUI)
            expected_uniformtypeidentifiers_load=1
            expected_photos_load=1
            framework_link_dependencies+=(
                -lPhotos
                -lUniformTypeIdentifiers
            )
            ;;
        BackgroundTasks)
            expected_dispatch_load=1
            framework_link_dependencies+=(
                -lDispatch
            )
            ;;
        CoreSpotlight)
            expected_uniformtypeidentifiers_load=1
            framework_link_dependencies+=(
                -lUniformTypeIdentifiers
            )
            ;;
        Compression)
            framework_link_dependencies+=("$COMPRESSION_DARWIN")
            ;;
    esac
    framework_objects=("$WORK/$source_dir.o")
    if [ "$framework" = CommonCrypto ]; then
        framework_objects+=("$WORK/commoncrypto-c.o")
    fi
    if [ "$framework" = Accelerate ]; then
        framework_objects+=("$WORK/accelerate-c.o")
    fi
    "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
        "${framework_link_options[@]}" \
        -install_name "@rpath/lib$framework.dylib" -rpath @loader_path \
        -o "$STAGE/lib/lib$framework.dylib" "${framework_objects[@]}" \
        "${COMMON_LINK[@]}" "${framework_link_dependencies[@]}"
    portable_self_id_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk -v expected="@rpath/lib$framework.dylib" \
            '$1 == expected { count++ } END { print count + 0 }')
    [ "$portable_self_id_count" -eq 1 ] \
        || die "lib$framework portable install ID count $portable_self_id_count, expected 1"
    foundation_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libFoundation.dylib" { count++ } END { print count + 0 }')
    foundation_essentials_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libFoundationEssentials.dylib" { count++ } END { print count + 0 }')
    uikit_load_count=$(llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libUIKit.dylib" { count++ } END { print count + 0 }')
    openuikit_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libOpenUIKit.dylib" { count++ } END { print count + 0 }')
    opencoregraphics_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
    swiftui_load_count=$(llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libSwiftUI.dylib" { count++ } END { print count + 0 }')
    coremedia_load_count=$(llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libCoreMedia.dylib" { count++ } END { print count + 0 }')
    avfoundation_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libAVFoundation.dylib" { count++ } END { print count + 0 }')
    uniformtypeidentifiers_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libUniformTypeIdentifiers.dylib" { count++ } END { print count + 0 }')
    imageio_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libImageIO.dylib" { count++ } END { print count + 0 }')
    photos_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libPhotos.dylib" { count++ } END { print count + 0 }')
    dispatch_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libDispatch.dylib" { count++ } END { print count + 0 }')
    appkit_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk -v expected="$APPKIT_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    # `otool -L` includes the dylib's LC_ID_DYLIB as its first entry.  That is
    # an identity, not a dependency.  Exclude it when auditing the two module
    # names that are themselves members of this first-party loop.
    if [ "$framework" = CoreMedia ]; then
        coremedia_load_count=$((coremedia_load_count - portable_self_id_count))
    fi
    if [ "$framework" = AVFoundation ]; then
        avfoundation_load_count=$((avfoundation_load_count - portable_self_id_count))
    fi
    if [ "$framework" = UniformTypeIdentifiers ]; then
        uniformtypeidentifiers_load_count=$((
            uniformtypeidentifiers_load_count - portable_self_id_count
        ))
    fi
    if [ "$framework" = ImageIO ]; then
        imageio_load_count=$((imageio_load_count - portable_self_id_count))
    fi
    if [ "$framework" = Photos ]; then
        photos_load_count=$((photos_load_count - portable_self_id_count))
    fi
    concurrency_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk -v expected="$SWIFTUI_RUNTIME_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    os_runtime_reexport_count=$(llvm-otool-18 -l \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "cmd" && $2 == "LC_REEXPORT_DYLIB" { reexport = 1; next } \
            reexport && $1 == "name" { \
                if ($2 == "@rpath/libFoundationEssentials.dylib") count++; \
                reexport = 0 \
            } END { print count + 0 }')
    foundation_essentials_ordinary_load_count=$((
        foundation_essentials_load_count - os_runtime_reexport_count
    ))
    [ "$foundation_load_count" -eq "$expected_foundation_load" ] \
        || die "lib$framework Foundation load count $foundation_load_count, expected $expected_foundation_load"
    [ "$foundation_essentials_load_count" -eq \
        "$expected_foundation_essentials_load" ] \
        || die "lib$framework FoundationEssentials load count $foundation_essentials_load_count, expected $expected_foundation_essentials_load"
    [ "$foundation_essentials_ordinary_load_count" -eq 1 ] \
        || die "lib$framework ordinary FoundationEssentials load count $foundation_essentials_ordinary_load_count, expected 1"
    [ "$uikit_load_count" -eq "$expected_uikit_load" ] \
        || die "lib$framework UIKit load count $uikit_load_count, expected $expected_uikit_load"
    [ "$openuikit_load_count" -eq "$expected_openuikit_load" ] \
        || die "lib$framework OpenUIKit load count $openuikit_load_count, expected $expected_openuikit_load"
    [ "$opencoregraphics_load_count" -eq \
        "$expected_opencoregraphics_load" ] \
        || die "lib$framework OpenCoreGraphics load count $opencoregraphics_load_count, expected $expected_opencoregraphics_load"
    [ "$swiftui_load_count" -eq "$expected_swiftui_load" ] \
        || die "lib$framework SwiftUI load count $swiftui_load_count, expected $expected_swiftui_load"
    [ "$coremedia_load_count" -eq "$expected_coremedia_load" ] \
        || die "lib$framework CoreMedia load count $coremedia_load_count, expected $expected_coremedia_load"
    [ "$avfoundation_load_count" -eq "$expected_avfoundation_load" ] \
        || die "lib$framework AVFoundation load count $avfoundation_load_count, expected $expected_avfoundation_load"
    [ "$uniformtypeidentifiers_load_count" -eq \
        "$expected_uniformtypeidentifiers_load" ] \
        || die "lib$framework UniformTypeIdentifiers load count $uniformtypeidentifiers_load_count, expected $expected_uniformtypeidentifiers_load"
    [ "$imageio_load_count" -eq "$expected_imageio_load" ] \
        || die "lib$framework ImageIO load count $imageio_load_count, expected $expected_imageio_load"
    [ "$photos_load_count" -eq "$expected_photos_load" ] \
        || die "lib$framework Photos load count $photos_load_count, expected $expected_photos_load"
    [ "$dispatch_load_count" -eq "$expected_dispatch_load" ] \
        || die "lib$framework Dispatch load count $dispatch_load_count, expected $expected_dispatch_load"
    [ "$appkit_load_count" -eq "$expected_appkit_load" ] \
        || die "lib$framework AppKit load count $appkit_load_count, expected $expected_appkit_load"
    [ "$concurrency_load_count" -eq 1 ] \
        || die "lib$framework Concurrency load count $concurrency_load_count, expected 1"
    [ "$os_runtime_reexport_count" -eq "$expected_os_runtime_reexport" ] \
        || die "lib$framework os runtime re-export count $os_runtime_reexport_count, expected $expected_os_runtime_reexport"
    if llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | grep -Fq "/System/Library/Frameworks/$framework.framework/"; then
        die "lib$framework loads the Apple $framework framework"
    fi
    printf '%s\tportable-self-id=%s\tfoundation=%s\tfoundation-essentials=%s\tfoundation-essentials-ordinary=%s\tuikit=%s\topenuikit=%s\topencoregraphics=%s\tswiftui=%s\tcoremedia=%s\tavfoundation=%s\tuniformtypeidentifiers=%s\timageio=%s\tphotos=%s\tdispatch=%s\tappkit=%s\tconcurrency=%s\tos-runtime-reexport=%s\tapple-self-load=0\n' \
        "$framework" "$portable_self_id_count" "$foundation_load_count" \
        "$foundation_essentials_load_count" \
        "$foundation_essentials_ordinary_load_count" "$uikit_load_count" \
        "$openuikit_load_count" \
        "$opencoregraphics_load_count" \
        "$swiftui_load_count" "$coremedia_load_count" \
        "$avfoundation_load_count" "$uniformtypeidentifiers_load_count" \
        "$imageio_load_count" "$photos_load_count" "$dispatch_load_count" \
        "$appkit_load_count" \
        "$concurrency_load_count" \
        "$os_runtime_reexport_count" \
        >> "$FIRST_PARTY_LOAD_AUDIT"
done

[ "$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$STAGE/lib/libAccelerate.dylib" \
    | awk '$0 == "_vImageBoxConvolve_ARGB8888" { count++ } END { print count + 0 }')" \
    -eq 1 ] || die 'libAccelerate vImage export count drifted'
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$STAGE/lib/libCompression.dylib" \
    | awk '$0 ~ /^_openui_compression_v1_/ { print }' | LC_ALL=C sort -u \
    > "$WORK/libcompression-runtime-imports.txt"
cmp "$WORK/open-compression-expected-mach-exports.txt" \
    "$WORK/libcompression-runtime-imports.txt" \
    || die 'libCompression runtime bridge imports drifted'
[ "$(llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$STAGE/lib/libCompression.dylib" \
    | awk '$0 ~ /^_glibc_openui_compression_v1_/ { count++ } END { print count + 0 }')" \
    -eq 0 ] || die 'libCompression directly imports a Linux host symbol'
compression_bridge_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libCompression.dylib" \
    | awk '$1 == "/usr/lib/libOpenCompression.dylib" { count++ } END { print count + 0 }')
[ "$compression_bridge_load_count" -eq 1 ] \
    || die "libCompression runtime bridge load count $compression_bridge_load_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/libCompression.dylib" | grep -Fq libbrotli; then
    die 'libCompression must cross the fixed host ABI instead of loading Brotli'
fi
[ "$(llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$STAGE/lib/libz.dylib" \
    | awk '$0 ~ /^_glibc_open_zlib_/ { count++ } END { print count + 0 }')" \
    -eq 0 ] || die 'libz directly imports a Linux host symbol'
zlib_bridge_load_count=$(llvm-otool-18 -l "$STAGE/lib/libz.dylib" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "/usr/lib/libOpenZlib.dylib" && command == "LC_LOAD_DYLIB" { count++ }
        END { print count + 0 }')
zlib_bridge_reexport_count=$(llvm-otool-18 -l "$STAGE/lib/libz.dylib" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "/usr/lib/libOpenZlib.dylib" && command == "LC_REEXPORT_DYLIB" { count++ }
        END { print count + 0 }')
[ "$zlib_bridge_load_count" -eq 1 ] \
    || die "libz runtime bridge load count $zlib_bridge_load_count, expected 1"
[ "$zlib_bridge_reexport_count" -eq 1 ] \
    || die "libz runtime bridge re-export count $zlib_bridge_reexport_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/libz.dylib" | grep -Fq '/usr/lib/libz.'; then
    die 'libz must cross the fixed host ABI instead of loading Apple libz'
fi

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/lib_QuickLook_SwiftUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/lib_QuickLook_SwiftUI.dylib" \
    "$WORK/quicklook-swiftui.o" "${COMMON_LINK[@]}" \
    -lQuickLook -lSwiftUI -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"
quicklook_overlay_quicklook_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_QuickLook_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libQuickLook.dylib" { count++ } END { print count + 0 }')
quicklook_overlay_swiftui_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_QuickLook_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libSwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$quicklook_overlay_quicklook_load_count" -eq 1 ] \
    || die "QuickLook overlay base load count $quicklook_overlay_quicklook_load_count, expected 1"
[ "$quicklook_overlay_swiftui_load_count" -eq 1 ] \
    || die "QuickLook overlay SwiftUI load count $quicklook_overlay_swiftui_load_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/lib_QuickLook_SwiftUI.dylib" \
    | grep -Eq '/System/Library/Frameworks/(QuickLook|_QuickLook_SwiftUI)\.framework/'; then
    die 'portable QuickLook overlay loads an Apple QuickLook framework'
fi
printf '%s\tquicklook=%s\tswiftui=%s\tapple-self-load=0\n' \
    _QuickLook_SwiftUI "$quicklook_overlay_quicklook_load_count" \
    "$quicklook_overlay_swiftui_load_count" >> "$FIRST_PARTY_LOAD_AUDIT"

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/lib_PhotosUI_SwiftUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/lib_PhotosUI_SwiftUI.dylib" \
    "$WORK/photosui-swiftui.o" "${COMMON_LINK[@]}" \
    -lPhotosUI -lPhotos -lCoreTransferable -lUniformTypeIdentifiers \
    -lSwiftUI -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"
photosui_overlay_base_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_PhotosUI_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libPhotosUI.dylib" { count++ } END { print count + 0 }')
photosui_overlay_swiftui_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_PhotosUI_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libSwiftUI.dylib" { count++ } END { print count + 0 }')
photosui_overlay_coretransferable_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_PhotosUI_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libCoreTransferable.dylib" { count++ } END { print count + 0 }')
[ "$photosui_overlay_base_load_count" -eq 1 ] \
    || die "PhotosUI overlay base load count $photosui_overlay_base_load_count, expected 1"
[ "$photosui_overlay_swiftui_load_count" -eq 1 ] \
    || die "PhotosUI overlay SwiftUI load count $photosui_overlay_swiftui_load_count, expected 1"
[ "$photosui_overlay_coretransferable_load_count" -eq 1 ] \
    || die "PhotosUI overlay CoreTransferable load count $photosui_overlay_coretransferable_load_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/lib_PhotosUI_SwiftUI.dylib" \
    | grep -Eq '/System/Library/Frameworks/(PhotosUI|_PhotosUI_SwiftUI)\.framework/'; then
    die 'portable PhotosUI overlay loads an Apple PhotosUI framework'
fi
printf '%s\tphotosui=%s\tswiftui=%s\tcoretransferable=%s\tapple-self-load=0\n' \
    _PhotosUI_SwiftUI "$photosui_overlay_base_load_count" \
    "$photosui_overlay_swiftui_load_count" \
    "$photosui_overlay_coretransferable_load_count" \
    >> "$FIRST_PARTY_LOAD_AUDIT"

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/lib_AuthenticationServices_SwiftUI.dylib \
    -rpath @loader_path \
    -o "$STAGE/lib/lib_AuthenticationServices_SwiftUI.dylib" \
    "$WORK/authenticationservices-swiftui.o" "${COMMON_LINK[@]}" \
    -lAuthenticationServices -lSwiftUI -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"
authenticationservices_overlay_base_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_AuthenticationServices_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libAuthenticationServices.dylib" { count++ } END { print count + 0 }')
authenticationservices_overlay_swiftui_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/lib_AuthenticationServices_SwiftUI.dylib" \
    | awk '$1 == "@rpath/libSwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$authenticationservices_overlay_base_load_count" -eq 1 ] \
    || die "AuthenticationServices overlay base load count $authenticationservices_overlay_base_load_count, expected 1"
[ "$authenticationservices_overlay_swiftui_load_count" -eq 1 ] \
    || die "AuthenticationServices overlay SwiftUI load count $authenticationservices_overlay_swiftui_load_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/lib_AuthenticationServices_SwiftUI.dylib" \
    | grep -Eq '/System/Library/Frameworks/(AuthenticationServices|_AuthenticationServices_SwiftUI)\.framework/'; then
    die 'portable AuthenticationServices overlay loads an Apple AuthenticationServices framework'
fi
printf '%s\tauthenticationservices=%s\tswiftui=%s\tapple-self-load=0\n' \
    _AuthenticationServices_SwiftUI \
    "$authenticationservices_overlay_base_load_count" \
    "$authenticationservices_overlay_swiftui_load_count" \
    >> "$FIRST_PARTY_LOAD_AUDIT"

swiftdata_swiftui_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libSwiftData.dylib" \
    | awk '$1 == "@rpath/libSwiftUI.dylib" { count++ } END { print count + 0 }')
swiftdata_observation_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libSwiftData.dylib" \
    | awk '$1 == "/usr/lib/swift/libswiftObservation.dylib" { count++ } END { print count + 0 }')
[ "$swiftdata_swiftui_load_count" -eq 1 ] \
    || die "libSwiftData SwiftUI load count $swiftdata_swiftui_load_count, expected 1"
[ "$swiftdata_observation_load_count" -eq 1 ] \
    || die "libSwiftData Observation load count $swiftdata_observation_load_count, expected 1"
if llvm-otool-18 -L "$STAGE/lib/libSwiftData.dylib" \
    | grep -Fq '/System/Library/Frameworks/SwiftData.framework/'; then
    die 'portable libSwiftData must not load Apple SwiftData.framework'
fi

echo '== compile/link/run standalone OSLog re-export gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name OSLogGuestRuntime -emit-object \
    -o "$WORK/oslog-guest-runtime.o" \
    "$W/full/oslog/tests/OSLogGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/OSLogGuestRuntime" \
    "$WORK/oslog-guest-runtime.o" "${COMMON_LINK[@]}" -lOSLog
oslog_gate_oslog_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/OSLogGuestRuntime" \
    | awk '$1 == "@rpath/libOSLog.dylib" { count++ } END { print count + 0 }')
oslog_gate_foundation_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/OSLogGuestRuntime" \
    | awk '$1 == "@rpath/libFoundation.dylib" { count++ } END { print count + 0 }')
oslog_gate_foundation_essentials_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/OSLogGuestRuntime" \
    | awk '$1 == "@rpath/libFoundationEssentials.dylib" { count++ } END { print count + 0 }')
[ "$oslog_gate_oslog_load_count" -eq 1 ] \
    || die "standalone OSLog gate load count $oslog_gate_oslog_load_count, expected 1"
[ "$oslog_gate_foundation_load_count" -eq 0 ] \
    || die "standalone OSLog gate direct Foundation load count $oslog_gate_foundation_load_count, expected 0"
[ "$oslog_gate_foundation_essentials_load_count" -eq 0 ] \
    || die "standalone OSLog gate direct FoundationEssentials load count $oslog_gate_foundation_essentials_load_count, expected 0"
{
    printf 'format\toslog-standalone-link-audit-v1\n'
    printf 'libOSLog-load-count\t%s\n' "$oslog_gate_oslog_load_count"
    printf 'direct-Foundation-load-count\t%s\n' \
        "$oslog_gate_foundation_load_count"
    printf 'direct-FoundationEssentials-load-count\t%s\n' \
        "$oslog_gate_foundation_essentials_load_count"
    printf 'os-runtime-resolution\tLC_REEXPORT_DYLIB\n'
} > "$STAGE/attestation/oslog-standalone-link.tsv"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/OSLogGuestRuntime
) 2>&1 | tee "$STAGE/attestation/oslog-runtime.log"
grep -Fq \
    'OSLOG_GUEST_MACHO_OK backend=standard-error signposts=visible reexport=os' \
    "$STAGE/attestation/oslog-runtime.log" \
    || die 'standalone OSLog runtime marker is missing'
grep -Fq \
    '[info] OpenUIKit.OSLogGuestRuntime:Standalone standalone OSLog diagnostic' \
    "$STAGE/attestation/oslog-runtime.log" \
    || die 'standalone OSLog Logger diagnostic is missing'
grep -Fq \
    '[signpost-event] OpenUIKit.OSLogGuestRuntime:Standalone StandaloneBoundary' \
    "$STAGE/attestation/oslog-runtime.log" \
    || die 'standalone OSLog signpost diagnostic is missing'

echo '== compile/link/run the standalone SwiftData macro and persistence gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${FOUNDATION_PLUGIN_FLAGS[@]}" "${SWIFTDATA_PLUGIN_FLAGS[@]}" \
    -module-name SwiftDataGuestRuntime -emit-object \
    -o "$WORK/swiftdata-guest-runtime.o" \
    "$W/full/swiftdata/tests/SwiftDataGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/SwiftDataGuestRuntime" \
    "$WORK/swiftdata-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lSwiftData -lSwiftUI -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "$SWIFTUI_RUNTIME_LINK_FLAG" "$OBSERVATION_DYLIB" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/SwiftDataGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'SwiftData runtime gate is not an ARM64 Mach-O executable'
swiftdata_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/SwiftDataGuestRuntime" \
    | awk '$1 == "@rpath/libSwiftData.dylib" { count++ } END { print count + 0 }')
[ "$swiftdata_gate_load_count" -eq 1 ] \
    || die "SwiftData gate load count $swiftdata_gate_load_count, expected 1"
swiftdata_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/SwiftDataGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$swiftdata_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "SwiftData gate Preview export count $swiftdata_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/SwiftDataGuestRuntime
) | tee "$STAGE/attestation/swiftdata-runtime.log"
grep -Fxq \
    'SWIFTDATA_GUEST_MACHO_OK macro=attached predicate=compound sort=reverse mutation=insert-delete query=live durable=fail-closed' \
    "$STAGE/attestation/swiftdata-runtime.log" \
    || die 'standalone SwiftData runtime marker is missing'

echo '== compile/link/run the standalone FoundationModels macro and service gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${FOUNDATIONMODELS_PLUGIN_FLAGS[@]}" -typecheck \
    -dump-macro-expansions \
    "$W/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift" \
    > "$STAGE/attestation/foundationmodels-macro-expansions.log" 2>&1
for expansion in \
    'static var generationSchema' \
    'var generatedContent' \
    'struct PartiallyGenerated' \
    'extension Tags: FoundationModels.Generable' \
    'guides: [.count(5)]'; do
    grep -Fq "$expansion" \
        "$STAGE/attestation/foundationmodels-macro-expansions.log" \
        || die "FoundationModels macro expansion is missing: $expansion"
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${FOUNDATIONMODELS_PLUGIN_FLAGS[@]}" \
    -module-name FoundationModelsGuestRuntime -emit-object \
    -o "$WORK/foundationmodels-guest-runtime.o" \
    "$W/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/FoundationModelsGuestRuntime" \
    "$WORK/foundationmodels-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lFoundationModels -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/FoundationModelsGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'FoundationModels runtime gate is not an ARM64 Mach-O executable'
foundationmodels_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/FoundationModelsGuestRuntime" \
    | awk '$1 == "@rpath/libFoundationModels.dylib" { count++ } END { print count + 0 }')
[ "$foundationmodels_gate_load_count" -eq 1 ] \
    || die "FoundationModels gate load count $foundationmodels_gate_load_count, expected 1"
cp "$W/full/foundationmodels/tests/foundationmodels-apple-26.1.txt" \
    "$STAGE/attestation/foundationmodels-apple-26.1.txt"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/FoundationModelsGuestRuntime
) | tee "$STAGE/attestation/foundationmodels-runtime.log"
grep -Fxq \
    'FOUNDATIONMODELS_GUEST_MACHO_OK macro=generable guide=count generated=roundtrip direct=fail-closed stream=fail-closed available=false' \
    "$STAGE/attestation/foundationmodels-runtime.log" \
    || die 'standalone FoundationModels runtime marker is missing'
head -n 4 "$STAGE/attestation/foundationmodels-runtime.log" \
    > "$WORK/foundationmodels-apple-comparable.txt"
cmp "$WORK/foundationmodels-apple-comparable.txt" \
    "$STAGE/attestation/foundationmodels-apple-26.1.txt" \
    || die 'FoundationModels generated-content output differs from Apple 26.1'

echo '== compile/link/run the standalone NaturalLanguage Apple-differential gate'
"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name NaturalLanguageGeneralizationRuntime -emit-object \
    -o "$WORK/naturallanguage-generalization-runtime.o" \
    "$W/full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/NaturalLanguageGeneralizationRuntime" \
    "$WORK/naturallanguage-generalization-runtime.o" "${COMMON_LINK[@]}" \
    -lNaturalLanguage -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/NaturalLanguageGeneralizationRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'NaturalLanguage generalization gate is not an ARM64 Mach-O executable'
naturallanguage_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/NaturalLanguageGeneralizationRuntime" \
    | awk '$1 == "@rpath/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')
[ "$naturallanguage_gate_load_count" -eq 1 ] \
    || die "NaturalLanguage gate load count $naturallanguage_gate_load_count, expected 1"
cp "$W/full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt" \
    "$STAGE/attestation/naturallanguage-generalization-apple-26.1.txt"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/NaturalLanguageGeneralizationRuntime
) | tee "$STAGE/attestation/naturallanguage-generalization-runtime.log"
cmp "$STAGE/attestation/naturallanguage-generalization-runtime.log" \
    "$STAGE/attestation/naturallanguage-generalization-apple-26.1.txt" \
    || die 'NaturalLanguage generalization output differs from Apple 26.1'
naturallanguage_generalization_rows=$(wc -l \
    < "$STAGE/attestation/naturallanguage-generalization-runtime.log" \
    | tr -d '[:space:]')
[ "$naturallanguage_generalization_rows" -eq 29 ] \
    || die "NaturalLanguage generalization row count $naturallanguage_generalization_rows, expected 29"
echo 'NATURALLANGUAGE_GUEST_MACHO_OK classifier=script,trigram hints=real constraints=real apple-differential=29/29'

echo '== compile/link/run the standalone UserNotifications service gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name UserNotificationsGuestRuntime -emit-object \
    -o "$WORK/usernotifications-guest-runtime.o" \
    "$W/full/usernotifications/tests/UserNotificationsHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/UserNotificationsGuestRuntime" \
    "$WORK/usernotifications-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lUserNotifications -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/UserNotificationsGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'UserNotifications runtime gate is not an ARM64 Mach-O executable'
usernotifications_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/UserNotificationsGuestRuntime" \
    | awk '$1 == "@rpath/libUserNotifications.dylib" { count++ } END { print count + 0 }')
[ "$usernotifications_gate_load_count" -eq 1 ] \
    || die "UserNotifications gate load count $usernotifications_gate_load_count, expected 1"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/UserNotificationsGuestRuntime
) | tee "$STAGE/attestation/usernotifications-runtime.log"
grep -Fxq \
    'USERNOTIFICATIONS_HOST_OK authorization=fail-closed scheduling=volatile delegate=async response=delivered badge=validated' \
    "$STAGE/attestation/usernotifications-runtime.log" \
    || die 'standalone UserNotifications runtime marker is missing'
printf '%s\n' \
    'USERNOTIFICATIONS_GUEST_MACHO_OK authorization=fail-closed scheduling=volatile delegate=async response=delivered badge=validated' \
    | tee -a "$STAGE/attestation/usernotifications-runtime.log"

echo '== typecheck Apple-shaped BackgroundTasks and CoreSpotlight corpus clients'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -swift-version 6 \
    -module-name BackgroundSpotlightCorpusConsumer -typecheck \
    "$W/full/corespotlight/tests/CorpusConsumerSurface.swift"

echo '== compile/link/run the standalone BackgroundTasks scheduler gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name BackgroundTasksGuestRuntime -emit-object \
    -o "$WORK/backgroundtasks-guest-runtime.o" \
    "$W/full/backgroundtasks/tests/BackgroundTasksHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/BackgroundTasksGuestRuntime" \
    "$WORK/backgroundtasks-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lBackgroundTasks -lDispatch \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
backgroundtasks_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/BackgroundTasksGuestRuntime" \
    | awk '$1 == "@rpath/libBackgroundTasks.dylib" { count++ } END { print count + 0 }')
[ "$backgroundtasks_gate_load_count" -eq 1 ] \
    || die "BackgroundTasks gate load count $backgroundtasks_gate_load_count, expected 1"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/BackgroundTasksGuestRuntime
) | tee "$STAGE/attestation/backgroundtasks-runtime.log"
grep -Fxq \
    'BACKGROUNDTASKS_HOST_OK requests=refresh,processing scheduler=register,copy,pending,cancel queue=honored lifecycle=launch,expire,complete errors=darwin-shaped' \
    "$STAGE/attestation/backgroundtasks-runtime.log" \
    || die 'standalone BackgroundTasks runtime marker is missing'

echo '== compile/link/run the standalone CoreSpotlight index gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreSpotlightGuestRuntime -emit-object \
    -o "$WORK/corespotlight-guest-runtime.o" \
    "$W/full/corespotlight/tests/CoreSpotlightHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreSpotlightGuestRuntime" \
    "$WORK/corespotlight-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lCoreSpotlight -lUniformTypeIdentifiers \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
corespotlight_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/CoreSpotlightGuestRuntime" \
    | awk '$1 == "@rpath/libCoreSpotlight.dylib" { count++ } END { print count + 0 }')
[ "$corespotlight_gate_load_count" -eq 1 ] \
    || die "CoreSpotlight gate load count $corespotlight_gate_load_count, expected 1"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreSpotlightGuestRuntime
) | tee "$STAGE/attestation/corespotlight-runtime.log"
grep -Fxq \
    'CORESPOTLIGHT_HOST_OK index=named,isolated crud=sync,async,domain,all snapshots=owned query=terms expiry=filtered batch=client-state app-entities=index,delete' \
    "$STAGE/attestation/corespotlight-runtime.log" \
    || die 'standalone CoreSpotlight runtime marker is missing'

echo '== compile/link/run the standalone QuickLook controller gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name QuickLookGuestRuntime -emit-object \
    -o "$WORK/quicklook-guest-runtime.o" \
    "$W/full/quicklook/tests/QuickLookGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/QuickLookGuestRuntime" \
    "$WORK/quicklook-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lQuickLook -lUIKit -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/QuickLookGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'QuickLook runtime gate is not an ARM64 Mach-O executable'
quicklook_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/QuickLookGuestRuntime" \
    | awk '$1 == "@rpath/libQuickLook.dylib" { count++ } END { print count + 0 }')
[ "$quicklook_gate_load_count" -eq 1 ] \
    || die "QuickLook gate load count $quicklook_gate_load_count, expected 1"
quicklook_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/QuickLookGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$quicklook_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "QuickLook gate Preview export count $quicklook_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/QuickLookGuestRuntime
) | tee "$STAGE/attestation/quicklook-runtime.log"
grep -Fxq \
    'QUICKLOOK_GUEST_MACHO_OK controller=items,indexed overlay=host-driven selection=synchronized unsupported=fail-closed' \
    "$STAGE/attestation/quicklook-runtime.log" \
    || die 'standalone QuickLook runtime marker is missing'

echo '== typecheck an ordinary QuickLook/SwiftUI cross-import consumer'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name QuickLookCrossImportConsumer -typecheck \
    "$W/full/quicklook/tests/IceCubesQuickLookConsumer.swift"

echo '== compile/link/run the standalone CoreMedia rational-time gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreMediaGuestRuntime -emit-object \
    -o "$WORK/coremedia-guest-runtime.o" \
    "$W/full/coremedia/tests/CoreMediaTranscript.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreMediaGuestRuntime" \
    "$WORK/coremedia-guest-runtime.o" "${COMMON_LINK[@]}" -lCoreMedia
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreMediaGuestRuntime
) | tee "$STAGE/attestation/coremedia-runtime.log"
grep -Fxq 'sum=5/6:0.8333333333333334' \
    "$STAGE/attestation/coremedia-runtime.log" \
    || die 'CoreMedia rational-addition marker is missing'
grep -Fxq 'sub=2/6:0.3333333333333333' \
    "$STAGE/attestation/coremedia-runtime.log" \
    || die 'CoreMedia rational-subtraction marker is missing'
grep -Fxq 'scaled=10/12:false' \
    "$STAGE/attestation/coremedia-runtime.log" \
    || die 'CoreMedia scale marker is missing'
grep -Fxq 'range=true:false' \
    "$STAGE/attestation/coremedia-runtime.log" \
    || die 'CoreMedia range marker is missing'

echo '== compile/link/run the standalone AVFoundation service gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AVFoundationGuestRuntime -emit-object \
    -o "$WORK/avfoundation-guest-runtime.o" \
    "$W/full/avfoundation/tests/AVFoundationHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AVFoundationGuestRuntime" \
    "$WORK/avfoundation-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lAVFoundation -lCoreMedia -lCoreGraphics -lOpenCoreGraphics \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/AVFoundationGuestRuntime
) | tee "$STAGE/attestation/avfoundation-runtime.log"
grep -Fxq \
    'AVFOUNDATION_HOST_OK time=rational player=host-driven audio=state export=fail-closed,host-driven frame=fail-closed,host-driven' \
    "$STAGE/attestation/avfoundation-runtime.log" \
    || die 'standalone AVFoundation runtime marker is missing'

echo '== compile/link/run the standalone Charts mark and interaction gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name ChartsGuestRuntime -emit-object \
    -o "$WORK/charts-guest-runtime.o" \
    "$W/full/charts/tests/ChartsHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/ChartsGuestRuntime" \
    "$WORK/charts-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lCharts -lSwiftUI -lUIKit -lFoundation \
    -lFoundationInternationalization -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
charts_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/ChartsGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$charts_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Charts gate Preview export count $charts_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/ChartsGuestRuntime
) | tee "$STAGE/attestation/charts-runtime.log"
grep -Fxq \
    'CHARTS_HOST_OK marks=bar,line,area,rule scalar=numeric,date interaction=fail-closed,host-driven stroke=retained rendering=basic' \
    "$STAGE/attestation/charts-runtime.log" \
    || die 'standalone Charts runtime marker is missing'

echo '== typecheck the exact-surface IceCubes Charts consumer'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IceCubesChartsConsumer -typecheck \
    "$W/full/charts/tests/IceCubesChartsConsumer.swift"

echo '== compile/link/run the standalone WidgetKit timeline and reload gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name WidgetKitGuestRuntime -emit-object \
    -o "$WORK/widgetkit-guest-runtime.o" \
    "$W/full/widgetkit/tests/WidgetKitHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/WidgetKitGuestRuntime" \
    "$WORK/widgetkit-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lWidgetKit -lAppIntents -lIntents -lSwiftUI -lUIKit \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/WidgetKitGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'WidgetKit runtime gate is not an ARM64 Mach-O executable'
widgetkit_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/WidgetKitGuestRuntime" \
    | awk '$1 == "@rpath/libWidgetKit.dylib" { count++ } END { print count + 0 }')
[ "$widgetkit_gate_load_count" -eq 1 ] \
    || die "WidgetKit gate load count $widgetkit_gate_load_count, expected 1"
widgetkit_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/WidgetKitGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$widgetkit_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "WidgetKit gate Preview export count $widgetkit_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/WidgetKitGuestRuntime
) | tee "$STAGE/attestation/widgetkit-runtime.log"
grep -Fxq \
    'WIDGETKIT_HOST_OK timeline=validated,scheduled providers=app-intent,sirikit reload=process-local,ordered configuration=retained presentation=host-driven' \
    "$STAGE/attestation/widgetkit-runtime.log" \
    || die 'standalone WidgetKit runtime marker is missing'

echo '== typecheck the exact-surface IceCubes WidgetKit consumer'
"${APP_CONSUMER_SWIFTC[@]}" -parse-as-library \
    "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IceCubesWidgetKitConsumer -typecheck \
    "$W/full/widgetkit/tests/IceCubesWidgetKitConsumer.swift"

echo '== typecheck the exact-surface Simplenote WidgetKit consumer'
"${APP_CONSUMER_SWIFTC[@]}" -parse-as-library \
    "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name SimplenoteWidgetKitConsumer -typecheck \
    "$W/full/widgetkit/tests/SimplenoteWidgetKitConsumer.swift"

echo '== compile/link/run the standalone CoreTransferable data and file gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreTransferableGuestRuntime -emit-object \
    -o "$WORK/coretransferable-guest-runtime.o" \
    "$W/full/coretransferable/tests/CoreTransferableHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreTransferableGuestRuntime" \
    "$WORK/coretransferable-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lCoreTransferable -lUniformTypeIdentifiers \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
coretransferable_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/CoreTransferableGuestRuntime" \
    | awk '$1 == "@rpath/libCoreTransferable.dylib" { count++ } END { print count + 0 }')
[ "$coretransferable_gate_load_count" -eq 1 ] \
    || die "CoreTransferable gate load count $coretransferable_gate_load_count, expected 1"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreTransferableGuestRuntime
) | tee "$STAGE/attestation/coretransferable-runtime.log"
grep -Fxq \
    'CORETRANSFERABLE_HOST_OK data=export file=import multi-representation=builder unsupported=fail-closed' \
    "$STAGE/attestation/coretransferable-runtime.log" \
    || die 'standalone CoreTransferable runtime marker is missing'

echo '== compile/link/run the standalone Photos authorization and asset gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name PhotosGuestRuntime -emit-object \
    -o "$WORK/photos-guest-runtime.o" \
    "$W/full/photos/tests/PhotosHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/PhotosGuestRuntime" \
    "$WORK/photos-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lPhotos -lImageIO -lCoreGraphics -lUIKit \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
photos_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/PhotosGuestRuntime" \
    | awk '$1 == "@rpath/libPhotos.dylib" { count++ } END { print count + 0 }')
[ "$photos_gate_load_count" -eq 1 ] \
    || die "Photos gate load count $photos_gate_load_count, expected 1"
photos_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/PhotosGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$photos_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Photos gate Preview export count $photos_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/PhotosGuestRuntime
) | tee "$STAGE/attestation/photos-runtime.log"
grep -Fxq \
    'PHOTOS_HOST_OK authorization=fail-closed,host-driven assets=volatile fetch=filtered,sorted,limited image=data,thumbnail' \
    "$STAGE/attestation/photos-runtime.log" \
    || die 'standalone Photos runtime marker is missing'

echo '== compile/link/run the standalone PhotosUI transfer and presentation gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name PhotosUIGuestRuntime -emit-object \
    -o "$WORK/photosui-guest-runtime.o" \
    "$W/full/photosui/tests/PhotosUIHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/PhotosUIGuestRuntime" \
    "$WORK/photosui-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -l_PhotosUI_SwiftUI -lPhotosUI -lPhotos -lCoreTransferable \
    -lUniformTypeIdentifiers -lSwiftUI -lUIKit \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
photosui_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/PhotosUIGuestRuntime" \
    | awk '$1 == "@rpath/lib_PhotosUI_SwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$photosui_gate_load_count" -eq 1 ] \
    || die "PhotosUI gate overlay load count $photosui_gate_load_count, expected 1"
photosui_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/PhotosUIGuestRuntime" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$photosui_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "PhotosUI gate Preview export count $photosui_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/PhotosUIGuestRuntime
) | tee "$STAGE/attestation/photosui-runtime.log"
grep -Fxq \
    'PHOTOSUI_HOST_OK filter=images,videos transfer=typed,async,completion presentation=fail-closed,host-driven selection=bounded,binding' \
    "$STAGE/attestation/photosui-runtime.log" \
    || die 'standalone PhotosUI runtime marker is missing'

echo '== typecheck an ordinary IceCubes PhotosUI/SwiftUI cross-import consumer'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IceCubesPhotosUIConsumer -typecheck \
    "$W/full/photosui/tests/IceCubesPhotosUIConsumer.swift"

echo '== compile/link/run Accelerate, Compression, CoreText, AdServices, zlib, and IOKit frontier gates'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AccelerateGuestRuntime -emit-object \
    -o "$WORK/accelerate-guest-runtime.o" \
    "$W/full/accelerate/tests/AccelerateGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AccelerateGuestRuntime" \
    "$WORK/accelerate-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lAccelerate -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CompressionGuestRuntime -emit-object \
    -o "$WORK/compression-guest-runtime.o" \
    "$W/full/compression/tests/CompressionGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CompressionGuestRuntime" \
    "$WORK/compression-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lCompression -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreTextGuestRuntime -emit-object \
    -o "$WORK/coretext-guest-runtime.o" \
    "$W/full/coretext/tests/CoreTextGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreTextGuestRuntime" \
    "$WORK/coretext-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lCoreText -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreTextFontManagerOracle -emit-object \
    -o "$WORK/coretext-font-manager-oracle.o" "$CORETEXT_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreTextFontManagerOracle" \
    "$WORK/coretext-font-manager-oracle.o" "${COMMON_LINK[@]}" \
    -lCoreText -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AdServicesGuestRuntime -emit-object \
    -o "$WORK/adservices-guest-runtime.o" \
    "$W/full/adservices/tests/AdServicesGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AdServicesGuestRuntime" \
    "$WORK/adservices-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lAdServices -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AdServicesInterfaceOracle -emit-object \
    -o "$WORK/adservices-interface-oracle.o" "$ADSERVICES_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AdServicesInterfaceOracle" \
    "$WORK/adservices-interface-oracle.o" "${COMMON_LINK[@]}" \
    -lAdServices -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name ZlibGuestRuntime -emit-object \
    -o "$WORK/zlib-guest-runtime.o" \
    "$W/full/zlib/tests/ZlibGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/ZlibGuestRuntime" \
    "$WORK/zlib-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lz -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name ZlibGzipOracle -emit-object \
    -o "$WORK/zlib-gzip-oracle.o" "$ZLIB_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/ZlibGzipOracle" \
    "$WORK/zlib-gzip-oracle.o" "${COMMON_LINK[@]}" \
    -lz -lFoundation -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG"

"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IOKitGuestRuntime -emit-object \
    -o "$WORK/iokit-guest-runtime.o" \
    "$W/full/iokit/tests/IOKitGuestRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/IOKitGuestRuntime" \
    "$WORK/iokit-guest-runtime.o" "${COMMON_LINK[@]}" \
    "$IOKIT_FRAMEWORK_BINARY" \
    -lswiftIOKit \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"

"${SWIFTC[@]}" -D PORTABLE_IOKIT -parse-as-library \
    "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IOKitInterfaceOracle -emit-object \
    -o "$WORK/iokit-interface-oracle.o" "$IOKIT_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/IOKitInterfaceOracle" \
    "$WORK/iokit-interface-oracle.o" "${COMMON_LINK[@]}" \
    "$IOKIT_FRAMEWORK_BINARY" \
    -lswiftIOKit \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"

for frontier_probe in AccelerateGuestRuntime CompressionGuestRuntime \
    CoreTextGuestRuntime CoreTextFontManagerOracle AdServicesGuestRuntime \
    AdServicesInterfaceOracle ZlibGuestRuntime ZlibGzipOracle \
    IOKitGuestRuntime IOKitInterfaceOracle; do
    llvm-otool-18 -hv "$STAGE/probe/$frontier_probe" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "$frontier_probe is not an ARM64 Mach-O executable"
done
cp "$ACCELERATE_GOLDEN" \
    "$STAGE/attestation/accelerate-box-convolve-apple.txt"
cp "$WORK/accelerate-native-oracle.log" \
    "$STAGE/attestation/accelerate-native-oracle.log"
cp "$W/full/compression/tests/compression-brotli-apple-2026-09-01.txt" \
    "$STAGE/attestation/compression-brotli-apple.txt"
cp "$CORETEXT_GOLDEN" "$STAGE/attestation/coretext-font-manager-apple.txt"
cp "$ADSERVICES_GOLDEN" "$STAGE/attestation/adservices-interface-apple.txt"
cp "$ZLIB_GOLDEN" "$STAGE/attestation/zlib-gzip-apple.txt"
cp "$WORK/zlib-native-oracle.log" \
    "$STAGE/attestation/zlib-native-oracle.log"
cp "$IOKIT_GOLDEN" "$STAGE/attestation/iokit-interface-apple.txt"
cp "$IOKIT_PORTABLE_GOLDEN" \
    "$STAGE/attestation/iokit-interface-portable.txt"

for iokit_probe in IOKitGuestRuntime IOKitInterfaceOracle; do
    iokit_load_count=$(llvm-otool-18 -L "$STAGE/probe/$iokit_probe" \
        | awk -v expected="$IOKIT_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    [ "$iokit_load_count" -eq 1 ] \
        || die "$iokit_probe IOKit framework load count $iokit_load_count, expected 1"
    swift_iokit_load_count=$(llvm-otool-18 -L "$STAGE/probe/$iokit_probe" \
        | awk -v expected="$SWIFT_IOKIT_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    [ "$swift_iokit_load_count" -eq 1 ] \
        || die "$iokit_probe Swift IOKit runtime load count $swift_iokit_load_count, expected 1"
done

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/AccelerateGuestRuntime
) | tee "$STAGE/attestation/accelerate-runtime.log"
grep -Fxq \
    'ACCELERATE_GUEST_OK vimage=box-convolve,argb8888 edge=extend apple-transcript=exact' \
    "$STAGE/attestation/accelerate-runtime.log" \
    || die 'Accelerate Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/CompressionGuestRuntime
) | tee "$STAGE/attestation/compression-runtime.log"
grep -Fxq \
    'COMPRESSION_GUEST_OK algorithm=brotli apple-payload=decoded roundtrip=exact bounds=256MiB' \
    "$STAGE/attestation/compression-runtime.log" \
    || die 'Compression Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/CoreTextGuestRuntime \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf" \
        "$WORK/coretext-guest-runtime-fonts"
) | tee "$STAGE/attestation/coretext-runtime.log"
grep -Fxq \
    'CORETEXT_GUEST_OK font-register=process duplicate-url=apple-exact errors=domain,codes' \
    "$STAGE/attestation/coretext-runtime.log" \
    || die 'CoreText Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/CoreTextFontManagerOracle \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf" \
        "$WORK/coretext-font-manager-oracle-fonts"
) | tee "$STAGE/attestation/coretext-font-manager-runtime.log"
cmp "$STAGE/attestation/coretext-font-manager-runtime.log" \
    "$STAGE/attestation/coretext-font-manager-apple.txt" \
    || die 'CoreText font-manager guest output differs from Apple'

echo '== compile/link/run the standalone NaturalLanguage classifier gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name NaturalLanguageGuestRuntime -emit-object \
    -o "$WORK/naturallanguage-guest-runtime.o" \
    "$W/full/naturallanguage/tests/NaturalLanguageHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/NaturalLanguageGuestRuntime" \
    "$WORK/naturallanguage-guest-runtime.o" "${COMMON_LINK[@]}" \
    -lNaturalLanguage -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
naturallanguage_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/NaturalLanguageGuestRuntime" \
    | awk '$1 == "@rpath/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')
[ "$naturallanguage_gate_load_count" -eq 1 ] \
    || die "NaturalLanguage gate load count $naturallanguage_gate_load_count, expected 1"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/NaturalLanguageGuestRuntime
) | tee "$STAGE/attestation/naturallanguage-runtime.log"
grep -Fxq \
    'NATURALLANGUAGE_HOST_OK constants=58 raw-tags=extensible state=replace,empty-noop,reset max=zero-unbounded corpus=en,de,fr,es,ja,zh-Hans,zh-Hant,ar confidence=conservative constraints=closed hints=prior' \
    "$STAGE/attestation/naturallanguage-runtime.log" \
    || die 'standalone NaturalLanguage runtime marker is missing'

echo '== typecheck untouched-consumer-shaped NaturalLanguage clients'
"${APP_CONSUMER_SWIFTC[@]}" -parse-as-library \
    "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IceCubesNaturalLanguageConsumers -typecheck \
    "$W/full/naturallanguage/tests/IceCubesNaturalLanguageConsumers.swift"

echo '== compile/link/run the standalone AuthenticationServices browser gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AuthenticationServicesGuestRuntime -emit-object \
    -o "$WORK/authenticationservices-guest-runtime.o" \
    "$W/full/authenticationservices/tests/AuthenticationServicesHostRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/AuthenticationServicesGuestRuntime" \
    "$WORK/authenticationservices-guest-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -l_AuthenticationServices_SwiftUI -lAuthenticationServices \
    -lSwiftUI -lUIKit -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}" \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
authenticationservices_gate_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/AuthenticationServicesGuestRuntime" \
    | awk '$1 == "@rpath/lib_AuthenticationServices_SwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$authenticationservices_gate_load_count" -eq 1 ] \
    || die "AuthenticationServices gate overlay load count $authenticationservices_gate_load_count, expected 1"
authenticationservices_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/AuthenticationServicesGuestRuntime" \
    "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$authenticationservices_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "AuthenticationServices gate Preview export count $authenticationservices_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/AuthenticationServicesGuestRuntime
) | tee "$STAGE/attestation/authenticationservices-runtime.log"
grep -Fxq \
    'AUTHENTICATIONSERVICES_HOST_OK environment=default startup=locked browser=host-driven callback=validated cancellation=once unavailable=fail-closed' \
    "$STAGE/attestation/authenticationservices-runtime.log" \
    || die 'standalone AuthenticationServices runtime marker is missing'

echo '== typecheck the IceCubes AuthenticationServices cross-import consumer'
"${APP_CONSUMER_SWIFTC[@]}" -parse-as-library \
    "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IceCubesAuthenticationServicesConsumer -typecheck \
    "$W/full/authenticationservices/tests/IceCubesAuthenticationServicesConsumer.swift"

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/AdServicesGuestRuntime
) | tee "$STAGE/attestation/adservices-runtime.log"
grep -Fxq \
    'AD_SERVICES_GUEST_MACHO_OK token=unavailable domain=com.apple.ap.adservices.attributionError code=3 policy=fail-closed' \
    "$STAGE/attestation/adservices-runtime.log" \
    || die 'AdServices Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/AdServicesInterfaceOracle
) | tee "$STAGE/attestation/adservices-interface-runtime.log"
cmp "$STAGE/attestation/adservices-interface-runtime.log" \
    "$STAGE/attestation/adservices-interface-apple.txt" \
    || die 'AdServices guest interface differs from Apple'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/ZlibGuestRuntime
) | tee "$STAGE/attestation/zlib-runtime.log"
grep -Fxq \
    'ZLIB_GUEST_MACHO_OK abi=112 gzip=exact bytes=77 version=1.2.12' \
    "$STAGE/attestation/zlib-runtime.log" \
    || die 'zlib Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/ZlibGzipOracle
) | tee "$STAGE/attestation/zlib-gzip-runtime.log"
cmp "$STAGE/attestation/zlib-gzip-runtime.log" \
    "$STAGE/attestation/zlib-gzip-apple.txt" \
    || die 'zlib gzip guest output differs from Apple'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/IOKitGuestRuntime
) | tee "$STAGE/attestation/iokit-runtime.log"
grep -Fxq \
    'IOKIT_GUEST_OK matching=nil services=unsupported iterator=nil properties=nil' \
    "$STAGE/attestation/iokit-runtime.log" \
    || die 'IOKit Mach-O runtime marker is missing'

(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/IOKitInterfaceOracle
) | tee "$STAGE/attestation/iokit-interface-runtime.log"
cmp "$STAGE/attestation/iokit-interface-runtime.log" \
    "$STAGE/attestation/iokit-interface-portable.txt" \
    || die 'IOKit portable Swift overlay interface or policy drifted'
tail -n 1 "$STAGE/attestation/iokit-interface-runtime.log" \
    | grep -Fxq 'missing=matching:nil' \
    || die 'IOKit portable missing-device policy is not fail-closed'

echo '== compile/link/run the production AppKit, SwiftUI, and StoreKit gates'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AppKitGuestRuntime -emit-object \
    -o "$WORK/appkit-guest-runtime.o" \
    "$W/full/appkit/tests/AppKitGuestRuntime.swift"
"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name AppKitInterfaceOracle -emit-object \
    -o "$WORK/appkit-interface-oracle.o" "$APPKIT_ORACLE"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name SwiftUIAppKitColorRuntime -emit-object \
    -o "$WORK/swiftui-appkit-color-runtime.o" \
    "$W/full/appkit/tests/SwiftUIAppKitColorRuntime.swift"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name StoreKitAppKitRuntime -emit-object \
    -o "$WORK/storekit-appkit-runtime.o" \
    "$W/full/appkit/tests/StoreKitAppKitRuntime.swift"

"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AppKitGuestRuntime" \
    "$WORK/appkit-guest-runtime.o" "${COMMON_LINK[@]}" \
    -F "$STAGE/frameworks" -framework AppKit \
    -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    -lCombine -lOpenCombine -lDispatch "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$OBSERVATION_DYLIB"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/AppKitInterfaceOracle" \
    "$WORK/appkit-interface-oracle.o" "${COMMON_LINK[@]}" \
    -F "$STAGE/frameworks" -framework AppKit \
    -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    -lCombine -lOpenCombine -lDispatch "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$OBSERVATION_DYLIB"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/SwiftUIAppKitColorRuntime" \
    "$WORK/swiftui-appkit-color-runtime.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -F "$STAGE/frameworks" -framework AppKit \
    -lSwiftUI -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols -lDispatch \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "$OBSERVATION_DYLIB" \
    "${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/StoreKitAppKitRuntime" \
    "$WORK/storekit-appkit-runtime.o" "${COMMON_LINK[@]}" \
    -F "$STAGE/frameworks" -framework AppKit \
    -lStoreKit -lUIKit -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics "$SWIFTUI_RUNTIME_LINK_FLAG"

for appkit_probe in AppKitGuestRuntime AppKitInterfaceOracle \
    SwiftUIAppKitColorRuntime StoreKitAppKitRuntime; do
    llvm-otool-18 -hv "$STAGE/probe/$appkit_probe" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "$appkit_probe is not an ARM64 Mach-O executable"
    appkit_probe_load_count=$(llvm-otool-18 -L \
        "$STAGE/probe/$appkit_probe" \
        | awk -v expected="$APPKIT_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    [ "$appkit_probe_load_count" -eq 1 ] \
        || die "$appkit_probe AppKit load count $appkit_probe_load_count, expected 1"
done

cp "$APPKIT_GOLDEN" "$STAGE/attestation/appkit-interface-apple.txt"
run_appkit_probe() {
    local name=$1
    (
        cd "$STAGE"
        LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
            MACHORUN_ROOT="$RUNTIME" \
            "$RUNTIME/machorun" "./probe/$name"
    ) | tee "$STAGE/attestation/$name.log"
}
run_appkit_probe AppKitGuestRuntime
run_appkit_probe AppKitInterfaceOracle
run_appkit_probe SwiftUIAppKitColorRuntime
run_appkit_probe StoreKitAppKitRuntime
grep -Fxq \
    'APPKIT_GUEST_MACHO_OK surface=application,alert,workspace,window,font,color ui=headless workspace=fail-closed alert=cancel-or-abort fonts=unavailable' \
    "$STAGE/attestation/AppKitGuestRuntime.log" \
    || die 'AppKit production cold runtime marker is missing'
cmp "$STAGE/attestation/AppKitInterfaceOracle.log" \
    "$STAGE/attestation/appkit-interface-apple.txt" \
    || die 'AppKit production interface differs from Apple'
grep -Fxq \
    'APPKIT_SWIFTUI_COLOR_MACHO_OK rgba=0.125,0.25,0.5,0.75 identity=AppKit.NSColor' \
    "$STAGE/attestation/SwiftUIAppKitColorRuntime.log" \
    || die 'SwiftUI/AppKit production color marker is missing'
grep -Fxq \
    'APPKIT_STOREKIT_MACHO_OK confirm-in=NSWindow purchase=fail-closed,payments-unavailable' \
    "$STAGE/attestation/StoreKitAppKitRuntime.log" \
    || die 'StoreKit/AppKit production fail-closed marker is missing'
{
    printf 'apple-differential\trows=10\tsha256=%s\n' \
        "$(hash_file "$STAGE/attestation/AppKitInterfaceOracle.log")"
    printf 'cold-runtime\tappkit=%s\tswiftui=%s\tstorekit=%s\n' \
        "$(hash_file "$STAGE/attestation/AppKitGuestRuntime.log")" \
        "$(hash_file "$STAGE/attestation/SwiftUIAppKitColorRuntime.log")" \
        "$(hash_file "$STAGE/attestation/StoreKitAppKitRuntime.log")"
} >> "$STAGE/attestation/appkit-framework.tsv"

echo '== compile/link/run the core package probe'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${OBSERVATION_PLUGIN_FLAGS[@]}" "${FOUNDATION_PLUGIN_FLAGS[@]}" \
    "${SWIFTDATA_PLUGIN_FLAGS[@]}" "${FOUNDATIONMODELS_PLUGIN_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" \
    "${OPENSWIFTUI_PLUGIN_FLAGS[@]}" \
    -module-name CoreGuestPackageProbe \
    -emit-object -o "$WORK/core-probe.o" \
    "$W/full/frameworks/CoreGuestPackageProbe.swift" \
    "$W/full/frameworks/FoundationHackersCompatibilityProbe.swift" \
    "$W/full/observation/tests/ObservationGuestRuntimeProbe.swift"
PROBE_LINK_EXTRA=()
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || PROBE_LINK_EXTRA+=("$STAGE/objects/developertoolsupport.o")
probe_dts_count=0
for input in "${PROBE_LINK_EXTRA[@]}"; do
    [ "$input" != "$STAGE/objects/developertoolsupport.o" ] \
        || probe_dts_count=$((probe_dts_count + 1))
done
[ "$probe_dts_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe DTS link count $probe_dts_count, expected $PREVIEW_ENABLED"
PROBE_EXPORT_FLAGS=(-exported_symbol __mh_execute_header)
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    staged_preview_definition_count=$(nm_symbol_count --defined-only \
        "$STAGE/objects/developertoolsupport.o" \
        "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    [ "$staged_preview_definition_count" -eq 1 ] \
        || die "staged Preview DTS initializer definition count $staged_preview_definition_count, expected 1"
    PROBE_EXPORT_FLAGS+=(-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
fi
"${LD[@]}" -dead_strip -ignore_auto_link \
    "${PROBE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreGuestPackageProbe" "$WORK/core-probe.o" \
    "${PROBE_LINK_EXTRA[@]}" "${COMMON_LINK[@]}" \
    -lWebKit -lIntentsUI -lIntents -lCoreImage -lQuartzCore -lDispatch \
    -lUIKit -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lSwiftUI -lSymbols \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit \
    -lAudioToolbox -lCoreHaptics -lPassKit -lCoreGraphics -lImageIO \
    -lLinkPresentation -lMessageUI -lMobileCoreServices -lSecurity -lCryptoKit \
    -lCommonCrypto -lAppIntents -lWidgetKit -lOSLog \
    -lUniformTypeIdentifiers -lSwiftData \
    -lFoundationModels -lNaturalLanguage \
    -lUserNotifications -lBackgroundTasks -lCoreSpotlight \
    -lQuickLook -l_QuickLook_SwiftUI \
    -lCoreMedia -lAVFoundation -lAVKit -lCharts \
    -lCoreTransferable -lPhotos -lPhotosUI -l_PhotosUI_SwiftUI \
    -lAccelerate -lCompression -lCoreText -lAdServices -lz \
    -lAuthenticationServices -l_AuthenticationServices_SwiftUI \
    "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$OBSERVATION_DYLIB"

for dylib in FoundationEssentials FoundationInternationalization \
    OpenCoreGraphics OpenUIKit OpenCombine Dispatch \
    Combine Symbols SwiftUI _QuickLook_SwiftUI _PhotosUI_SwiftUI \
    _AuthenticationServices_SwiftUI Foundation UIKit CoreImage QuartzCore \
    Intents IntentsUI WebKit \
    "${FIRST_PARTY_FRAMEWORKS[@]}"; do
    llvm-otool-18 -hv "$STAGE/lib/lib$dylib.dylib" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "lib$dylib is not an ARM64 Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$STAGE/lib/lib$dylib.dylib" | tail -n 1)
    [ "$actual_id" = "@rpath/lib$dylib.dylib" ] \
        || die "lib$dylib install name changed: $actual_id"
done
llvm-otool-18 -hv "$STAGE/lib/libz.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'libz is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$STAGE/lib/libz.dylib" | tail -n 1)" = \
    @rpath/libz.dylib ] || die 'libz install name drifted'
llvm-otool-18 -hv "$STAGE/lib/lib_FoundationICU.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'lib_FoundationICU is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$STAGE/lib/lib_FoundationICU.dylib" | tail -n 1)" = \
    @rpath/lib_FoundationICU.dylib ] || die 'lib_FoundationICU install name drifted'
if llvm-otool-18 -L "$STAGE/lib/libUIKit.dylib" \
    | grep -Fq DeveloperToolsSupport; then
    die 'libUIKit must not load a DeveloperToolsSupport dylib'
fi
probe_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/CoreGuestPackageProbe" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
probe_dts_export_count=$(nm_developer_tools_support_count --defined-only \
    "$STAGE/probe/CoreGuestPackageProbe")
[ "$probe_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe Preview initializer export count $probe_preview_export_count, expected $PREVIEW_ENABLED"
[ "$probe_dts_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe DeveloperToolsSupport export count $probe_dts_export_count, expected $PREVIEW_ENABLED"
{
    printf 'format\tcore-probe-link-audit-v1\n'
    printf 'developer-tools-support-object-count\t%s\n' "$probe_dts_count"
    printf 'libSwiftUI-preview-initializer-import-count\t%s\n' \
        "$swiftui_preview_import_count"
    printf 'libUIKit-developer-tools-support-load-count\t0\n'
    printf 'libUIKit-preview-initializer-import-count\t%s\n' \
        "$uikit_preview_import_count"
    printf 'executable-preview-initializer-export-count\t%s\n' \
        "$probe_preview_export_count"
    printf 'runtime-preview-body-evaluation\t%s\n' \
        "$([ "$PREVIEW_ENABLED" -eq 1 ] && printf enabled || printf disabled)"
} > "$STAGE/attestation/probe-link-audit.tsv"
llvm-otool-18 -hv "$STAGE/probe/CoreGuestPackageProbe" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'core package probe is not an ARM64 Mach-O executable'
probe_observation_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/CoreGuestPackageProbe" \
    | awk '$1 == "/usr/lib/swift/libswiftObservation.dylib" { count++ } \
        END { print count + 0 }')
[ "$probe_observation_load_count" -eq 1 ] \
    || die "core probe Observation load count $probe_observation_load_count, expected 1"

perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 --executable "$STAGE/probe/CoreGuestPackageProbe" \
    --package "$STAGE" --guest-root "$STAGE/guest-root" \
    > "$STAGE/attestation/runtime-closure.tsv"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreGuestPackageProbe \
        "$STAGE/resources/OpenUIKit" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf"
) | tee "$STAGE/attestation/runtime.log"
grep -Fq 'CORE_GUEST_PACKAGE_MACHO_OK notification=shared,publisher,userdefaults combine=delivered resources=loaded fonts=system,bold intents=donated shortcuts=stored appintents=process-local foundation=locks,filehandle,characters,strings,ranges,attributed,objc,number-bridge,data-search,cfurl,url-bridge,cache,reexports,byte-count internationalization=icu-fr,number,idna data-platform=lock,kvs,relative-time-icu,filesystem,storekit-model observation=macro,reexport,registrar,tracking,ignored,one-shot graphics=coreimage,quartzcore,tgmath imageio=static,incremental,animated-gif symbols=values,markers,swiftui-render intentsui=host-driven swiftui-app=constructed first-party=portable-38 zlib=gzip-host-v1 foundationmodels=generated-content,fail-closed naturallanguage=classifier,apple-29 oslog=standard-error,signposts security=keychain,random cryptokit=hashes,nonce,ed25519-fail-closed commoncrypto=sha256 uniform-types=tags,conformance swiftdata=volatile,fail-closed-durable usernotifications=fail-closed,volatile backgroundtasks=scheduler,host-driven corespotlight=index,query,app-entities quicklook=local-image,host-driven media=rational,state,host-driven,fail-closed charts=basic,fail-closed widgetkit=timelines,process-local,host-driven coretransferable=data,file,fail-closed photos=authorization,volatile,host-driven photosui=transfer,binding,host-driven naturallanguage=deterministic,confidence-gated authenticationservices=host-driven,fail-closed webkit=state,kvo,engine-unavailable preview=' \
    "$STAGE/attestation/runtime.log" || die 'core package runtime marker is missing'

echo '== compile/link/run the real Dispatch and Swift-concurrency Mach-O gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name DispatchMachORuntime -emit-object \
    -o "$WORK/dispatch-macho-runtime.o" \
    "$W/full/dispatch/tests/DispatchMachORuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/DispatchMachORuntime" \
    "$WORK/dispatch-macho-runtime.o" "${COMMON_LINK[@]}" \
    -lDispatch -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/DispatchMachORuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Dispatch runtime gate is not an ARM64 Mach-O executable'
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/DispatchMachORuntime
) | tee "$STAGE/attestation/dispatch-runtime.log"
grep -Fx \
    'OPEN_DISPATCH_MACHO_OK async-main=drained taskgroup=8 detached=42 global=17 main=23 after=29 scheduler=immediate,delayed,cancelled,receive-on vouchers=null' \
    "$STAGE/attestation/dispatch-runtime.log" >/dev/null \
    || die 'real Dispatch/Swift-concurrency Mach-O runtime marker is missing'

echo '== compile/link/run the SwiftUI-only Foundation/Combine/Dispatch reexport gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name SwiftUIFoundationReexportProbe -emit-object \
    -o "$WORK/swiftui-foundation-reexport-probe.o" \
    "$W/full/frameworks/SwiftUIFoundationReexportProbe.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    "${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/SwiftUIFoundationReexportProbe" \
    "$WORK/swiftui-foundation-reexport-probe.o" \
    "${PREVIEW_STANDALONE_LINK_INPUTS[@]}" "${COMMON_LINK[@]}" \
    -lSwiftUI -lDispatch -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    -lCombine -lOpenCombine "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/SwiftUIFoundationReexportProbe" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'SwiftUI Foundation reexport gate is not an ARM64 Mach-O executable'
swiftui_reexport_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/SwiftUIFoundationReexportProbe" \
    "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
[ "$swiftui_reexport_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "SwiftUI reexport gate Preview export count $swiftui_reexport_preview_export_count, expected $PREVIEW_ENABLED"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/SwiftUIFoundationReexportProbe
) | tee "$STAGE/attestation/swiftui-foundation-reexport-runtime.log"
grep -Fx \
    'SWIFTUI_FOUNDATION_REEXPORT_MACHO_OK import=swiftui-only notification=publisher dispatch=scheduler' \
    "$STAGE/attestation/swiftui-foundation-reexport-runtime.log" >/dev/null \
    || die 'SwiftUI Foundation/Combine/Dispatch reexport marker is missing'

echo '== compile/link/run the full async Foundation URLSession cold gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name FoundationURLSessionRuntime -emit-object \
    -o "$WORK/foundation-urlsession-runtime.o" \
    "$W/full/foundation/tests/FoundationURLSessionRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/FoundationURLSessionRuntime" \
    "$WORK/foundation-urlsession-runtime.o" "${COMMON_LINK[@]}" \
    -lDispatch -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/FoundationURLSessionRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Foundation URLSession runtime gate is not an ARM64 Mach-O executable'
(
    set -e
    server_port_file=$WORK/foundation-urlsession-runtime.port
    server_log=$WORK/foundation-urlsession-server.log
    python3 -B "$W/full/foundation/tests/url_session_test_server.py" \
        --port-file "$server_port_file" >"$server_log" 2>&1 &
    server_pid=$!
    trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
    for _ in $(seq 1 200); do
        [ ! -s "$server_port_file" ] || break
        sleep 0.01
    done
    [ -s "$server_port_file" ] \
        || die 'Foundation URLSession test server did not publish its port'
    server_port=$(tr -d '[:space:]' < "$server_port_file")
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/FoundationURLSessionRuntime \
        "http://127.0.0.1:$server_port"
) | tee "$STAGE/attestation/foundation-urlsession-runtime.log"
grep -Fx \
    'FOUNDATION_URLSESSION_MACHO_OK delegate=retained configuration=isolated cookies=host-domain-path-expiry-delete redirect=set-cookie-post-get status500=response final-url=preserved concurrency=parallel input-stream=bounded urlprotocol=intercepted-cache-hit-redirect-refused timeouts=configuration-request https=not-requested' \
    "$STAGE/attestation/foundation-urlsession-runtime.log" >/dev/null \
    || die 'full async Foundation URLSession Mach-O runtime marker is missing'

echo '== compile/link/run the Apple-differential NSURL and NSCache cold gate'
"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name FoundationCacheRuntime -emit-object \
    -o "$WORK/foundation-cache-runtime.o" \
    "$FOUNDATION_CACHE_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/FoundationCacheRuntime" \
    "$WORK/foundation-cache-runtime.o" "${COMMON_LINK[@]}" \
    -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/FoundationCacheRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Foundation cache runtime gate is not an ARM64 Mach-O executable'
cp "$FOUNDATION_CACHE_GOLDEN" \
    "$STAGE/attestation/foundation-cache-apple.txt"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/FoundationCacheRuntime
) | tee "$STAGE/attestation/foundation-cache-runtime.log"
cmp "$STAGE/attestation/foundation-cache-runtime.log" \
    "$STAGE/attestation/foundation-cache-apple.txt" \
    || die 'Foundation NSURL/NSCache guest output differs from Apple'
foundation_cache_rows=$(wc -l \
    < "$STAGE/attestation/foundation-cache-runtime.log" \
    | tr -d '[:space:]')
[ "$foundation_cache_rows" -eq 43 ] \
    || die "Foundation cache runtime row count $foundation_cache_rows, expected 43"
echo 'FOUNDATION_CACHE_MACHO_OK rows=43 apple-differential=exact'

echo '== compile/link/run the Apple-differential ByteCountFormatter cold gate'
"${SWIFTC[@]}" "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name FoundationByteCountFormatterRuntime -emit-object \
    -o "$WORK/foundation-byte-count-runtime.o" \
    "$FOUNDATION_BYTE_COUNT_ORACLE"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/FoundationByteCountFormatterRuntime" \
    "$WORK/foundation-byte-count-runtime.o" "${COMMON_LINK[@]}" \
    -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/FoundationByteCountFormatterRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Foundation byte-count runtime gate is not an ARM64 Mach-O executable'
cp "$FOUNDATION_BYTE_COUNT_GOLDEN" \
    "$STAGE/attestation/foundation-byte-count-apple.txt"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/FoundationByteCountFormatterRuntime
) | tee "$STAGE/attestation/foundation-byte-count-runtime.log"
cmp "$STAGE/attestation/foundation-byte-count-runtime.log" \
    "$STAGE/attestation/foundation-byte-count-apple.txt" \
    || die 'Foundation ByteCountFormatter guest output differs from Apple'
foundation_byte_count_rows=$(wc -l \
    < "$STAGE/attestation/foundation-byte-count-runtime.log" \
    | tr -d '[:space:]')
[ "$foundation_byte_count_rows" -eq 86 ] \
    || die "Foundation byte-count runtime row count $foundation_byte_count_rows, expected 86"
echo 'FOUNDATION_BYTE_COUNT_MACHO_OK rows=86 apple-differential=exact'

echo '== write relocatable compile/link contracts'
COMPILE_ARGUMENTS=(
    -target "$TARGET" -sdk sdk -runtime-compatibility-version none
    -F frameworks
    -Xfrontend -enable-cross-import-overlays
    -Xfrontend -disable-objc-attr-requires-foundation-module
    -load-plugin-library host-tools/swift/host/plugins/libObservationMacros.so
    -load-plugin-library host-tools/swift/host/plugins/libFoundationMacros.so
    -load-plugin-library host-tools/swift/host/plugins/libSwiftDataMacros.so
    -load-plugin-library host-tools/swift/host/plugins/libFoundationModelsMacros.so
    -load-plugin-library host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so
    -load-plugin-library host-tools/swift/host/plugins/libOpenSwiftUIMacros.so
    -I modules
    -Xcc -Iinclude/CPortableIO
    -Xcc -Iinclude/CSTBTrueType
    -Xcc -Iinclude/CHostClock
    -Xcc -Iinclude/COpenCombineHelpers
    -Xcc -Iinclude/CQuartz
    -Xcc -fmodule-map-file=include/CoreImage/module.modulemap
    -Xcc -Iinclude/CoreImage
    -Xcc -fmodule-map-file=include/COpenURLTransport/module.modulemap
    -Xcc -Iinclude/COpenURLTransport
    -Xcc -fmodule-map-file=include/COpenRelativeTime/module.modulemap
    -Xcc -Iinclude/COpenRelativeTime
    -Xcc -fmodule-map-file=include/COpenDispatch/module.modulemap
    -Xcc -Iinclude/COpenDispatch
    -Xcc -fmodule-map-file=include/CCommonCrypto/module.modulemap
    -Xcc -Iinclude/CCommonCrypto
    -Xcc -fmodule-map-file=include/COpenAccelerate/module.modulemap
    -Xcc -Iinclude/COpenAccelerate
    -Xcc -fmodule-map-file=include/COpenCompression/module.modulemap
    -Xcc -Iinclude/COpenCompression
    -Xcc -fmodule-map-file=include/zlib/module.modulemap
    -Xcc -Iinclude/zlib
    -Xcc -fmodule-map-file=include/COpenFoundationCore/module.modulemap
    -Xcc -Iinclude/COpenFoundationCore
    -Xcc -fmodule-map-file=include/FoundationICU/_foundation_unicode/module.modulemap
    -Xcc -Iinclude/FoundationICU
    -Xcc -fmodule-map-file=include/_FoundationCShims/module.modulemap
    -Xcc -Iinclude/_FoundationCShims
)
LINK_ARGUMENTS=(
    -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk
    -F frameworks -framework AppKit -framework IOKit
    -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift
    -lswiftCore -lswiftObjectiveC -lswiftIOKit "${SWIFTUI_RUNTIME_LINK_FLAG}"
    guest-root/darwin/usr/lib/swift/libswiftObservation.dylib
    guest-root/darwin/usr/lib/libswiftcompat.dylib
    -Lsdk/usr/lib -lSystem -lobjc
    guest-root/darwin/usr/lib/libquartz.dylib
    guest-root/darwin/usr/lib/libSystem.B.dylib
    -lWebKit -lCoreImage -lQuartzCore -lDispatch -lUIKit -lFoundation
    -lFoundationInternationalization -lFoundationEssentials -lSwiftUI -lSymbols
    -l_QuickLook_SwiftUI -l_PhotosUI_SwiftUI \
    -l_AuthenticationServices_SwiftUI
    -lIntentsUI -lIntents -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit
    -lAudioToolbox -lCoreHaptics -lPassKit -lCoreGraphics -lImageIO
    -lLinkPresentation -lMessageUI -lMobileCoreServices -lSecurity -lCryptoKit
    -lCommonCrypto -lAppIntents -lWidgetKit -lOSLog \
    -lUniformTypeIdentifiers -lSwiftData
    -lFoundationModels
    -lUserNotifications -lBackgroundTasks -lCoreSpotlight \
    -lQuickLook -lCoreMedia -lAVFoundation -lAVKit -lCharts
    -lCoreTransferable -lPhotos -lPhotosUI -lAccelerate -lCompression -lCoreText
    -lAdServices -lz
    -lNaturalLanguage -lAuthenticationServices
)
printf '%s\0' "${COMPILE_ARGUMENTS[@]}" > "$STAGE/compile-flags.rsp"
printf '%s\0' "${LINK_ARGUMENTS[@]}" > "$STAGE/link-inputs.rsp"

if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    printf '%s\0' -load-plugin-executable \
        '${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros' -j1 \
        > "$STAGE/preview-plugin-load-flag.rsp"
    {
        printf 'format\tcore-preview-input-v2\n'
        printf 'module-name\tDeveloperToolsSupport\n'
        printf 'module-path\tmodules/DeveloperToolsSupport.swiftmodule\n'
        printf 'module-sha256\t%s\n' "$PREVIEW_MODULE_SHA"
        printf 'object-path\tobjects/developertoolsupport.o\n'
        printf 'object-sha256\t%s\n' "$PREVIEW_OBJECT_SHA"
        printf 'plugin-basename\tOpenUIKitPreviewMacros-tool\n'
        printf 'plugin-sha256\t%s\n' "$PREVIEW_PLUGIN_SHA"
        printf 'plugin-elf-class\tELF64\n'
        printf 'plugin-elf-machine\tAArch64\n'
        printf 'plugin-toolchain\t%s\n' "$PREVIEW_TOOLCHAIN"
        printf 'plugin-swiftsyntax-revision\t%s\n' \
            "$EXPECTED_PREVIEW_SWIFTSYNTAX_REVISION"
        printf 'plugin-registration\tOpenUIKitPreviewMacros\n'
        printf 'plugin-load-flags\tpreview-plugin-load-flag.rsp\n'
        printf 'plugin-driver-job-count\t1\n'
    } > "$STAGE/attestation/preview-input.tsv"
fi

echo '== exhaustive tree attestations'
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/sdk" \
    --logical-root sdk --output "$STAGE/attestation/sdk-tree.tsv"
cmp "$WORK/sdk.pre.tsv" "$STAGE/attestation/sdk-tree.tsv" \
    || die 'packaged SDK tree differs from the bracketed input SDK'
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/include" \
    --logical-root include --reject-symlinks \
    --output "$STAGE/attestation/include-tree.tsv"
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/guest-root" \
    --logical-root guest-root --output "$STAGE/attestation/guest-root-tree.tsv"
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$STAGE/resources/OpenUIKit" --logical-root resources/OpenUIKit \
    --reject-symlinks --output "$STAGE/attestation/openuikit-resources-tree.tsv"
cmp "$WORK/openuikit-resources.pre.tsv" \
    <(awk -F '\t' '$2 !~ /^resources\/OpenUIKit\/fonts(\/|$)/' \
        "$STAGE/attestation/openuikit-resources-tree.tsv") \
    || die 'staged OpenUIKit resource tree differs from source before fonts'

cp "$WORK/foundation-sources.pre.tsv" "$STAGE/attestation/foundation-sources.tsv"
cp "$WORK/observation-sources.pre.tsv" \
    "$STAGE/attestation/observation-sources.tsv"
cp "$WORK/intents-sources.pre.tsv" "$STAGE/attestation/intents-sources.tsv"
cp "$WORK/graphics-sources.pre.tsv" "$STAGE/attestation/graphics-sources.tsv"
cp "$WORK/appkit-sources.pre.tsv" "$STAGE/attestation/appkit-sources.tsv"
cp "$WORK/webkit-sources.pre.tsv" "$STAGE/attestation/webkit-sources.tsv"
cp "$WORK/foundation-undefined-symbols.txt" \
    "$STAGE/attestation/foundation-undefined-symbols.txt"
cp "$WORK/foundation-runtime-exports.txt" \
    "$STAGE/attestation/foundation-runtime-exports.txt"
cp "$WORK/foundation-bindings.txt" \
    "$STAGE/attestation/foundation-bindings.txt"
cp "$WORK/appkit-exports.txt" "$STAGE/attestation/appkit-exports.txt"
cp "$WORK/appkit-imports.txt" "$STAGE/attestation/appkit-imports.txt"
cp "$WORK/appkit-loads.txt" "$STAGE/attestation/appkit-loads.txt"
cp "$WORK/appkit-load-identities.txt" \
    "$STAGE/attestation/appkit-load-identities.txt"
cp "$FULL/foundation/essentials/removefile-compat-tests.log" \
    "$STAGE/attestation/removefile-compat-tests.log"
cp "$WORK/group-lookup-macho.log" \
    "$STAGE/attestation/group-lookup-macho.log"
cp "$WORK/xattr-macho.log" \
    "$STAGE/attestation/xattr-macho.log"
cp "$FTS_GOLDEN" "$STAGE/attestation/fts-apple.txt"
cp "$FTS_SUMMARY" "$STAGE/attestation/fts-apple-summary.txt"
cp "$WORK/fts-macho.log" "$STAGE/attestation/fts-macho.log"
cp "$STATFS_GOLDEN" "$STAGE/attestation/statfs-apple.txt"
cp "$STATFS_SUMMARY" "$STAGE/attestation/statfs-apple-summary.txt"
cp "$WORK/statfs-macho.log" "$STAGE/attestation/statfs-macho.log"
cp "$COPYFILE_GOLDEN" "$STAGE/attestation/copyfile-apple.txt"
cp "$COPYFILE_SUMMARY" "$STAGE/attestation/copyfile-apple-summary.txt"
cp "$WORK/copyfile-macho.log" "$STAGE/attestation/copyfile-macho.log"
cp "$WORK/copyfile-xattr-unavailable-macho.log" \
    "$STAGE/attestation/copyfile-xattr-unavailable-macho.log"
cp "$WORK/libsystem-compat-macho.log" \
    "$STAGE/attestation/libsystem-compat-macho.log"
cp "$WORK/first-party-sources.pre.tsv" \
    "$STAGE/attestation/first-party-sources.tsv"
cp "$SOURCE_SET_ATTEST" "$STAGE/attestation/source-sets.tsv"
{
    printf 'format\tcore-input-provenance-v1\n'
    printf 'support\tcommit=%s\ttree=%s\tbase=%s\n' \
        "$SUPPORT_COMMIT" "$SUPPORT_TREE" "$EXPECTED_SUPPORT_BASE"
    printf 'OpenUIKit\tcommit=%s\ttree=%s\tSwift=%s\tOpenCoreGraphics=%s\tSymbols=%s\tSwiftUI=%s\tDeveloperToolsSupport=%s\tOpenUIKitPreviewMacros=%s\tOpenSwiftUIMacros=%s\tCQuartzCPP=%s\n' \
        "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" \
        "$EXPECTED_UIKIT_SWIFT_COUNT" "$EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT" \
        "$EXPECTED_SYMBOLS_SWIFT_COUNT" "$EXPECTED_SWIFTUI_SWIFT_COUNT" \
        "$EXPECTED_DEVELOPER_TOOLS_SUPPORT_SWIFT_COUNT" \
        "$EXPECTED_OPENUIKIT_PREVIEW_MACROS_SWIFT_COUNT" \
        "$EXPECTED_OPENSWIFTUI_MACROS_SWIFT_COUNT" \
        "$EXPECTED_CQUARTZ_CPP_COUNT"
    printf 'AppKit\tsources=%s\tswiftui-interop=%s\texports=%s\texport-sha256=%s\timport-sha256=%s\tapple-golden=%s\tload-contract=%s\n' \
        "$EXPECTED_APPKIT_SOURCE_COUNT" \
        "$EXPECTED_SWIFTUI_APPKIT_SOURCE_COUNT" \
        "$EXPECTED_APPKIT_EXPORT_COUNT" "$EXPECTED_APPKIT_EXPORT_SHA" \
        "$EXPECTED_APPKIT_IMPORT_SHA" "$(hash_file "$APPKIT_GOLDEN")" \
        "$(hash_file "$APPKIT_LOAD_IDENTITIES")"
    printf 'swift-foundation\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE"
    printf 'swift-foundation-icu\tcommit=%s\ttree=%s\tcpp=%s\theaders=%s\n' \
        "$EXPECTED_FOUNDATION_ICU_COMMIT" "$EXPECTED_FOUNDATION_ICU_TREE" \
        "$EXPECTED_FOUNDATION_ICU_CPP_COUNT" \
        "$EXPECTED_FOUNDATION_ICU_HEADER_COUNT"
    printf 'FoundationInternationalization\tswift=%s\tbuild=%s\tbridge=%s\thost=%s\tthreading=%s\n' \
        "$EXPECTED_FOUNDATION_INTL_SWIFT_COUNT" \
        "$(hash_file "$FOUNDATION_INTERNATIONALIZATION_BUILDER")" \
        "$(hash_file "$W/full/foundationinternationalization/OpenFoundationInternationalizationBridge.c")" \
        "$(hash_file "$W/full/foundationinternationalization/OpenFoundationInternationalizationHost.c")" \
        "$(hash_file "$W/full/foundationinternationalization/FoundationICUCXXThreading.cpp")"
    printf 'FoundationEssentials-removefile\theader=%s\timplementation=%s\ttests=%s\n' \
        "$(hash_file "$W/full/foundation/removefile_compat.h")" \
        "$(hash_file "$W/full/foundation/removefile_compat.c")" \
        "$(hash_file "$W/full/foundation/removefile_compat_tests.c")"
    printf 'FoundationEssentials-group-lookup\tlibSystem-source=%s\tfixture=%s\tgolden=%s\tnative-source=%s\n' \
        "$(hash_file "$MACHORUN/darwin/src/posix.c")" \
        "$EXPECTED_MACHORUN_GROUP_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_GROUP_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_GROUP_SOURCE_SHA"
    printf 'FoundationEssentials-xattr\tlibSystem-source=%s\tfixture=%s\tgolden=%s\ttest-source=%s\n' \
        "$(hash_file "$MACHORUN/darwin/src/posix.c")" \
        "$EXPECTED_MACHORUN_XATTR_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_XATTR_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_XATTR_SOURCE_SHA"
    printf 'FoundationEssentials-fts\tlibSystem-source=%s\tfixture=%s\tgolden=%s\tstderr=%s\texit=%s\tapple-source=%s\tapple-summary=%s\n' \
        "$EXPECTED_MACHORUN_FTS_LIBSYSTEM_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_FTS_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_FTS_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_FTS_STDERR_SHA" \
        "$EXPECTED_MACHORUN_FTS_EXIT_SHA" \
        "$EXPECTED_MACHORUN_FTS_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_FTS_SUMMARY_SHA"
    printf 'FoundationEssentials-copyfile\tlibSystem-source=%s\tfixture=%s\tgolden=%s\tstderr=%s\texit=%s\tapple-source=%s\tapple-summary=%s\txattr-unavailable-gate=%s\n' \
        "$EXPECTED_MACHORUN_COPYFILE_LIBSYSTEM_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_STDERR_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_EXIT_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_SUMMARY_SHA" \
        "$EXPECTED_MACHORUN_COPYFILE_XATTR_GATE_SHA"
    printf 'FoundationEssentials-statfs\tlibSystem-source=%s\tfixture=%s\tgolden=%s\tstderr=%s\texit=%s\tapple-source=%s\tapple-summary=%s\n' \
        "$EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_STATFS_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_STATFS_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_STATFS_STDERR_SHA" \
        "$EXPECTED_MACHORUN_STATFS_EXIT_SHA" \
        "$EXPECTED_MACHORUN_STATFS_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_STATFS_SUMMARY_SHA"
    printf 'FoundationEssentials-libSystem-compat\tquota=%s,%s,%s\tuname=%s,%s,%s\n' \
        "$EXPECTED_MACHORUN_QUOTA_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_QUOTA_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_QUOTA_SOURCE_SHA" \
        "$EXPECTED_MACHORUN_UNAME_FIXTURE_SHA" \
        "$EXPECTED_MACHORUN_UNAME_GOLDEN_SHA" \
        "$EXPECTED_MACHORUN_UNAME_SOURCE_SHA"
    printf 'swift-collections\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE"
    printf 'OpenCombine\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE"
    printf 'Observation\tupstream=%s\tsources=%s\tplugin=%s\ttoolchain=%s\n' \
        "$EXPECTED_OBSERVATION_UPSTREAM_COMMIT" \
        "$(hash_file "$OBSERVATION_SOURCES_MANIFEST")" \
        "$EXPECTED_OBSERVATION_PLUGIN_SHA" "$OBSERVATION_TOOLCHAIN"
    printf 'compiler-plugins\tObservationMacros=%s\tFoundationMacros=%s\tSwiftDataMacros=%s\tFoundationModelsMacros=%s\tOpenUIKitPreviewMacros=%s\tOpenSwiftUIMacros=%s\tmanifest=%s\n' \
        "$(hash_file "$STAGED_OBSERVATION_PLUGIN")" \
        "$(hash_file "$STAGED_FOUNDATION_PLUGIN")" \
        "$(hash_file "$STAGED_SWIFTDATA_PLUGIN")" \
        "$(hash_file "$STAGED_FOUNDATIONMODELS_PLUGIN")" \
        "$(hash_file "$STAGED_OPENUIKIT_PREVIEW_PLUGIN")" \
        "$(hash_file "$STAGED_OPENSWIFTUI_PLUGIN")" \
        "$(hash_file "$STAGE/attestation/compiler-plugins.tsv")"
    printf 'FoundationEssentials-predicate-keypath\tpatch=%s\tupstream=%s\n' \
        "$(hash_file "$W/full/foundation/patches/FoundationEssentials-PredicateFinalClassKeyPath.patch")" \
        'swiftlang/swift-foundation#92b1b021'
    printf 'Foundation-CFError\theader=%s\tmodule-map=%s\tbridge=%s\n' \
        "$(hash_file "$COPEN_FOUNDATION_CORE_INCLUDE/OpenFoundationCFError.h")" \
        "$(hash_file "$COPEN_FOUNDATION_CORE_INCLUDE/module.modulemap")" \
        "$(hash_file "$W/full/foundation/CFError+Error.swift")"
    printf 'machorun\tcommit=%s\ttree=%s\tloader-sha256=%s\n' \
        "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" \
        "$(hash_file "$MACHORUN/build/machorun")"
    printf 'machorun-runtime\tlibswiftCore-sha256=%s\tlibobjc-sha256=%s\tcontract=%s\tbuild-full-stage=%s\n' \
        "$(hash_file "$SWIFT_CORE_RUNTIME")" \
        "$(hash_file "$OBJC_RUNTIME")" \
        "$(hash_file "$STAGE/attestation/swift-core-runtime.tsv")" \
        "$(hash_file "$STAGE/attestation/build-full-swift-core-stage.json")"
    printf 'font\tsystem\tcontainer:/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf\t%s\n' \
        "$EXPECTED_SYSTEM_FONT"
    printf 'font\tbold\tcontainer:/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf\t%s\n' \
        "$EXPECTED_BOLD_FONT"
    printf 'sdk-dangling-exclusions\t%s\tcount=9\n' \
        "$(hash_file "$SDK_DANGLING_EXCLUSIONS")"
    printf 'first-party-policy\t%s\tframeworks=7\tsources=7\n' \
        "$(hash_file "$FIRST_PARTY_PROVENANCE_POLICY")"
    printf 'url-transport\theader=%s\tbridge=%s\thost=%s\thost-tests=%s\n' \
        "$(hash_file "$W/full/urltransport/include/OpenURLTransportABI.h")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportBridge.c")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportHost.c")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportHostTests.c")"
    printf 'foundation-cache\toracle=%s\tapple-golden=%s\trows=43\n' \
        "$(hash_file "$FOUNDATION_CACHE_ORACLE")" \
        "$(hash_file "$FOUNDATION_CACHE_GOLDEN")"
    printf 'foundation-byte-count\toracle=%s\tapple-golden=%s\trows=86\n' \
        "$(hash_file "$FOUNDATION_BYTE_COUNT_ORACLE")" \
        "$(hash_file "$FOUNDATION_BYTE_COUNT_GOLDEN")"
    printf 'frontier-frameworks\tframeworks=31\tsources=35\tinputs=108\n'
    printf 'quicklook-overlay\tsources=1\tcross-import-metadata=1\n'
    printf 'photosui-overlay\tsources=1\tcross-import-metadata=1\n'
    printf 'relative-time\theader=%s\tbridge=%s\thost=%s\thost-tests=%s\n' \
        "$(hash_file "$W/full/relativetime/include/OpenRelativeTimeABI.h")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeBridge.c")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeHost.c")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeHostTests.c")"
    printf 'dispatch\theader=%s\tmodule-map=%s\tbridge=%s\thost=%s\thost-tests=%s\tswift=%s\truntime-gate=%s\n' \
        "$(hash_file "$W/full/dispatch/include/OpenDispatchABI.h")" \
        "$(hash_file "$W/full/dispatch/include/module.modulemap")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchBridge.c")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchHost.c")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchHostTests.c")" \
        "$(hash_file "$W/full/dispatch/Dispatch.swift")" \
        "$(hash_file "$W/full/dispatch/tests/DispatchMachORuntime.swift")"
    printf 'dispatch-host-runtime\tlibdispatch=%s\tlibBlocksRuntime=%s\tglibc-minimum=2.38\n' \
        "$EXPECTED_HOST_DISPATCH_SHA256" \
        "$EXPECTED_HOST_BLOCKS_RUNTIME_SHA256"
    printf 'accelerate\theader=%s\tmodule-map=%s\tc=%s\tapple-golden=%s\n' \
        "$(hash_file "$W/full/accelerate/include/Accelerate.h")" \
        "$(hash_file "$W/full/accelerate/include/module.modulemap")" \
        "$(hash_file "$W/full/accelerate/Accelerate.c")" \
        "$(hash_file "$ACCELERATE_GOLDEN")"
    printf 'compression\theader=%s\tmodule-map=%s\tbridge=%s\thost=%s\tapple-golden=%s\n' \
        "$(hash_file "$W/full/compression/include/OpenCompressionABI.h")" \
        "$(hash_file "$W/full/compression/include/module.modulemap")" \
        "$(hash_file "$W/full/compression/OpenCompressionBridge.c")" \
        "$(hash_file "$W/full/compression/OpenCompressionHost.c")" \
        "$(hash_file "$W/full/compression/tests/compression-brotli-apple-2026-09-01.txt")"
    printf 'coretext\toracle=%s\tapple-golden=%s\n' \
        "$(hash_file "$CORETEXT_ORACLE")" "$(hash_file "$CORETEXT_GOLDEN")"
    printf 'adservices\toracle=%s\tapple-golden=%s\tpolicy=fail-closed\n' \
        "$(hash_file "$ADSERVICES_ORACLE")" "$(hash_file "$ADSERVICES_GOLDEN")"
    printf 'zlib\theader=%s\tmodule-map=%s\tabi-header=%s\tbridge=%s\thost=%s\tapple-golden=%s\n' \
        "$(hash_file "$W/full/zlib/include/zlib/zlib.h")" \
        "$(hash_file "$W/full/zlib/include/zlib/module.modulemap")" \
        "$(hash_file "$W/full/zlib/include/COpenZlib/OpenZlibABI.h")" \
        "$(hash_file "$W/full/zlib/OpenZlibBridge.c")" \
        "$(hash_file "$W/full/zlib/OpenZlibHost.c")" \
        "$(hash_file "$ZLIB_GOLDEN")"
    printf 'iokit\theader=%s\tmodule-map=%s\tc=%s\tswift-overlay=%s\thost-tests=%s\toracle=%s\tapple-golden=%s\tportable-golden=%s\tswift-runtime=%s\tswift-runtime-header=%s\tswift-runtime-exports=%s\tpolicy=fail-closed\n' \
        "$(hash_file "$W/full/iokit/include/IOKit.h")" \
        "$(hash_file "$W/full/iokit/include/module.modulemap")" \
        "$(hash_file "$W/full/iokit/IOKit.c")" \
        "$(hash_file "$W/full/iokit/IOKit.swift")" \
        "$(hash_file "$IOKIT_HOST_TEST")" \
        "$(hash_file "$IOKIT_ORACLE")" \
        "$(hash_file "$IOKIT_GOLDEN")" \
        "$(hash_file "$IOKIT_PORTABLE_GOLDEN")" \
        "$(hash_file "$W/full/iokit/OpenSwiftIOKitRuntime.c")" \
        "$(hash_file "$W/full/iokit/OpenSwiftIOKitRuntime.h")" \
        "$(hash_file "$SWIFT_IOKIT_EXPORTS")"
    printf 'toolchain\tswiftc\t%s\n' "$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
    printf 'toolchain\tclang\t%s\n' "$(clang-18 --version | head -1)"
    [ "$PREVIEW_ENABLED" -eq 0 ] || printf 'preview\tmodule=%s\tobject=%s\tplugin=%s\n' \
        "$PREVIEW_MODULE_SHA" "$PREVIEW_OBJECT_SHA" "$PREVIEW_PLUGIN_SHA"
} > "$STAGE/attestation/input-provenance.tsv"

ARTIFACT_LEDGER=$STAGE/attestation/artifacts.tsv
printf 'format\tcore-artifacts-v1\n' > "$ARTIFACT_LEDGER"
record_artifact() {
    local category=$1 name=$2 role=$3 relative=$4 size
    [ -f "$STAGE/$relative" ] && [ ! -L "$STAGE/$relative" ] \
        || die "artifact is not a regular file: $relative"
    size=$(wc -c < "$STAGE/$relative" | tr -d '[:space:]')
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$category" "$name" "$role" \
        "$relative" "$(hash_file "$STAGE/$relative")" "$size" \
        >> "$ARTIFACT_LEDGER"
}
record_module_family() {
    local category=$1 name=$2 file suffix role
    for file in "$STAGE/modules/$name".*; do
        [ -f "$file" ] || continue
        suffix=${file#"$STAGE/modules/$name."}
        role=$suffix
        [ "$suffix" != abi.json ] || role=abi-json
        record_artifact "$category" "$name" "$role" "modules/$(basename "$file")"
    done
}
for framework in FoundationEssentials FoundationInternationalization \
    OpenCoreGraphics OpenUIKit OpenCombine Dispatch \
    Combine Symbols SwiftUI _QuickLook_SwiftUI _PhotosUI_SwiftUI \
    _AuthenticationServices_SwiftUI Foundation UIKit CoreImage QuartzCore \
    Intents IntentsUI WebKit \
    "${FIRST_PARTY_FRAMEWORKS[@]}"; do
    record_module_family framework "$framework"
    record_artifact framework "$framework" dylib "lib/lib$framework.dylib"
done
record_artifact framework AppKit abi-json \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.abi.json
record_artifact framework AppKit private-swiftinterface \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.private.swiftinterface
record_artifact framework AppKit swiftdoc \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.swiftdoc
record_artifact framework AppKit swiftinterface \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.swiftinterface
record_artifact framework AppKit swiftmodule \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.swiftmodule
record_artifact framework AppKit swiftsourceinfo \
    frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule/arm64-apple-macos.swiftsourceinfo
record_artifact framework AppKit dylib \
    frameworks/AppKit.framework/Versions/C/AppKit
record_artifact module-metadata QuickLook cross-import-overlay \
    modules/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay
record_artifact module-metadata PhotosUI cross-import-overlay \
    modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay
record_artifact module-metadata AuthenticationServices cross-import-overlay \
    modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay
record_module_family framework Observation
record_artifact runtime Observation dylib \
    guest-root/darwin/usr/lib/swift/libswiftObservation.dylib
record_artifact host-tool ObservationMacros plugin \
    host-tools/swift/host/plugins/libObservationMacros.so
record_artifact host-tool FoundationMacros plugin \
    host-tools/swift/host/plugins/libFoundationMacros.so
record_artifact host-tool SwiftDataMacros plugin \
    host-tools/swift/host/plugins/libSwiftDataMacros.so
record_artifact host-tool FoundationModelsMacros plugin \
    host-tools/swift/host/plugins/libFoundationModelsMacros.so
record_artifact host-tool OpenUIKitPreviewMacros plugin \
    host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so
record_artifact host-tool OpenSwiftUIMacros plugin \
    host-tools/swift/host/plugins/libOpenSwiftUIMacros.so
for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    record_artifact host-tool ObservationMacros dependency \
        "host-tools/swift/host/$library"
done
for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    record_artifact host-tool ObservationMacros dependency \
        "host-tools/swift/linux/$library"
done
record_artifact module-dependency _FoundationICU dylib \
    lib/lib_FoundationICU.dylib
record_artifact module-dependency _FoundationICU module-map \
    include/FoundationICU/_foundation_unicode/module.modulemap
record_artifact include CoreImage umbrella-header include/CoreImage/CoreImage.h
record_artifact include CoreImage submodule-header \
    include/CoreImage/CIFilterBuiltins.h
record_artifact include CoreImage module-map include/CoreImage/module.modulemap
record_artifact include COpenDispatch abi-header \
    include/COpenDispatch/OpenDispatchABI.h
record_artifact include COpenDispatch module-map \
    include/COpenDispatch/module.modulemap
record_artifact include CCommonCrypto abi-header \
    include/CCommonCrypto/CommonDigest.h
record_artifact include CCommonCrypto module-map \
    include/CCommonCrypto/module.modulemap
record_artifact include COpenAccelerate abi-header \
    include/COpenAccelerate/Accelerate.h
record_artifact include COpenAccelerate module-map \
    include/COpenAccelerate/module.modulemap
record_artifact include COpenCompression abi-header \
    include/COpenCompression/OpenCompressionABI.h
record_artifact include COpenCompression module-map \
    include/COpenCompression/module.modulemap
record_artifact include COpenZlib abi-header \
    include/COpenZlib/OpenZlibABI.h
record_artifact include COpenZlib module-map \
    include/COpenZlib/module.modulemap
record_artifact include zlib abi-header include/zlib/zlib.h
record_artifact include zlib module-map include/zlib/module.modulemap
record_artifact include IOKit framework-header \
    frameworks/IOKit.framework/Headers/IOKit.h
record_artifact include IOKit framework-module-map \
    frameworks/IOKit.framework/Modules/module.modulemap
record_artifact framework IOKit c-dylib frameworks/IOKit.framework/IOKit
record_module_family framework IOKit
record_artifact include COpenFoundationCore opaque-header \
    include/COpenFoundationCore/OpenFoundationCFError.h
record_artifact include COpenFoundationCore module-map \
    include/COpenFoundationCore/module.modulemap
for dependency in InternalCollectionsUtilities OrderedCollections _RopeModule os \
    DeveloperToolsSupport; do
    record_module_family module-dependency "$dependency"
done
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    record_artifact object DeveloperToolsSupport object \
        objects/developertoolsupport.o
fi
record_artifact runtime CQuartz dylib guest-root/darwin/usr/lib/libquartz.dylib
record_artifact runtime OpenURLTransport darwin-bridge \
    guest-root/darwin/usr/lib/libOpenURLTransport.dylib
record_artifact runtime OpenURLTransport linux-helper \
    guest-root/host/libOpenURLTransportHost.so
record_artifact runtime OpenRelativeTime darwin-bridge \
    guest-root/darwin/usr/lib/libOpenRelativeTime.dylib
record_artifact runtime OpenRelativeTime linux-helper \
    guest-root/host/libOpenRelativeTimeHost.so
record_artifact runtime OpenDispatch linux-helper \
    guest-root/host/libOpenDispatchHost.so
record_artifact runtime OpenDispatch darwin-bridge \
    guest-root/darwin/usr/lib/libOpenDispatch.dylib
record_artifact runtime OpenDispatch linux-libdispatch \
    guest-root/host/libdispatch.so
record_artifact runtime OpenDispatch linux-blocks-runtime \
    guest-root/host/libBlocksRuntime.so
record_artifact runtime Compression linux-helper \
    guest-root/host/libOpenCompressionHost.so
record_artifact runtime Compression darwin-bridge \
    guest-root/darwin/usr/lib/libOpenCompression.dylib
record_artifact runtime zlib darwin-dylib lib/libz.dylib
record_artifact runtime zlib darwin-bridge \
    guest-root/darwin/usr/lib/libOpenZlib.dylib
record_artifact runtime zlib linux-helper guest-root/host/libOpenZlibHost.so
record_artifact runtime IOKit framework-dylib \
    guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
record_artifact runtime AppKit framework-dylib \
    guest-root/darwin/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
record_artifact runtime SwiftIOKit overlay-dylib \
    guest-root/darwin/usr/lib/swift/libswiftIOKit.dylib
record_artifact runtime OpenFoundationInternationalization darwin-bridge \
    guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib
record_artifact runtime OpenFoundationInternationalization linux-helper \
    guest-root/host/libOpenFoundationInternationalizationHost.so
record_artifact runtime machorun executable guest-root/machorun
record_artifact runtime ObjectiveC dylib \
    guest-root/darwin/usr/lib/libobjc.A.dylib
record_artifact resource OpenUIKit system-font \
    resources/OpenUIKit/fonts/DejaVuSans.ttf
record_artifact resource OpenUIKit bold-font \
    resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf
while IFS= read -r resource; do
    relative=${resource#"$STAGE/"}
    case "$relative" in resources/OpenUIKit/fonts/*) continue ;; esac
    record_artifact resource OpenUIKit runtime-resource "$relative"
done < <(find "$STAGE/resources/OpenUIKit" -type f | LC_ALL=C sort)
record_artifact probe CoreGuestPackageProbe executable probe/CoreGuestPackageProbe
record_artifact probe OSLogGuestRuntime executable probe/OSLogGuestRuntime
record_artifact probe SwiftDataGuestRuntime executable \
    probe/SwiftDataGuestRuntime
record_artifact probe FoundationModelsGuestRuntime executable \
    probe/FoundationModelsGuestRuntime
record_artifact probe NaturalLanguageGeneralizationRuntime executable \
    probe/NaturalLanguageGeneralizationRuntime
record_artifact probe UserNotificationsGuestRuntime executable \
    probe/UserNotificationsGuestRuntime
record_artifact probe BackgroundTasksGuestRuntime executable \
    probe/BackgroundTasksGuestRuntime
record_artifact probe CoreSpotlightGuestRuntime executable \
    probe/CoreSpotlightGuestRuntime
record_artifact probe QuickLookGuestRuntime executable \
    probe/QuickLookGuestRuntime
record_artifact probe CoreMediaGuestRuntime executable \
    probe/CoreMediaGuestRuntime
record_artifact probe AVFoundationGuestRuntime executable \
    probe/AVFoundationGuestRuntime
record_artifact probe ChartsGuestRuntime executable \
    probe/ChartsGuestRuntime
record_artifact probe WidgetKitGuestRuntime executable \
    probe/WidgetKitGuestRuntime
record_artifact probe CoreTransferableGuestRuntime executable \
    probe/CoreTransferableGuestRuntime
record_artifact probe PhotosGuestRuntime executable \
    probe/PhotosGuestRuntime
record_artifact probe PhotosUIGuestRuntime executable \
    probe/PhotosUIGuestRuntime
record_artifact probe AccelerateGuestRuntime executable \
    probe/AccelerateGuestRuntime
record_artifact probe CompressionGuestRuntime executable \
    probe/CompressionGuestRuntime
record_artifact probe CoreTextGuestRuntime executable \
    probe/CoreTextGuestRuntime
record_artifact probe CoreTextFontManagerOracle executable \
    probe/CoreTextFontManagerOracle
record_artifact probe AdServicesGuestRuntime executable \
    probe/AdServicesGuestRuntime
record_artifact probe AdServicesInterfaceOracle executable \
    probe/AdServicesInterfaceOracle
record_artifact probe ZlibGuestRuntime executable probe/ZlibGuestRuntime
record_artifact probe ZlibGzipOracle executable probe/ZlibGzipOracle
record_artifact probe IOKitGuestRuntime executable probe/IOKitGuestRuntime
record_artifact probe IOKitInterfaceOracle executable \
    probe/IOKitInterfaceOracle
record_artifact probe NaturalLanguageGuestRuntime executable \
    probe/NaturalLanguageGuestRuntime
record_artifact probe AuthenticationServicesGuestRuntime executable \
    probe/AuthenticationServicesGuestRuntime
record_artifact probe AppKitGuestRuntime executable probe/AppKitGuestRuntime
record_artifact probe AppKitInterfaceOracle executable probe/AppKitInterfaceOracle
record_artifact probe SwiftUIAppKitColorRuntime executable \
    probe/SwiftUIAppKitColorRuntime
record_artifact probe StoreKitAppKitRuntime executable \
    probe/StoreKitAppKitRuntime
record_artifact probe DispatchMachORuntime executable \
    probe/DispatchMachORuntime
record_artifact probe SwiftUIFoundationReexportProbe executable \
    probe/SwiftUIFoundationReexportProbe
record_artifact probe FoundationURLSessionRuntime executable \
    probe/FoundationURLSessionRuntime
record_artifact probe FoundationCacheRuntime executable \
    probe/FoundationCacheRuntime
record_artifact probe FoundationByteCountFormatterRuntime executable \
    probe/FoundationByteCountFormatterRuntime
record_artifact attestation runtime runtime-log attestation/runtime.log
record_artifact attestation OSLog runtime-log attestation/oslog-runtime.log
record_artifact attestation OSLog link-audit \
    attestation/oslog-standalone-link.tsv
record_artifact attestation SwiftData runtime-log \
    attestation/swiftdata-runtime.log
record_artifact attestation FoundationModels runtime-log \
    attestation/foundationmodels-runtime.log
record_artifact attestation FoundationModels macro-expansions \
    attestation/foundationmodels-macro-expansions.log
record_artifact attestation FoundationModels apple-golden \
    attestation/foundationmodels-apple-26.1.txt
record_artifact attestation NaturalLanguage runtime-log \
    attestation/naturallanguage-generalization-runtime.log
record_artifact attestation NaturalLanguage apple-golden \
    attestation/naturallanguage-generalization-apple-26.1.txt
record_artifact attestation UserNotifications runtime-log \
    attestation/usernotifications-runtime.log
record_artifact attestation BackgroundTasks runtime-log \
    attestation/backgroundtasks-runtime.log
record_artifact attestation CoreSpotlight runtime-log \
    attestation/corespotlight-runtime.log
record_artifact attestation QuickLook runtime-log \
    attestation/quicklook-runtime.log
record_artifact attestation CoreMedia runtime-log \
    attestation/coremedia-runtime.log
record_artifact attestation AVFoundation runtime-log \
    attestation/avfoundation-runtime.log
record_artifact attestation Charts runtime-log \
    attestation/charts-runtime.log
record_artifact attestation WidgetKit runtime-log \
    attestation/widgetkit-runtime.log
record_artifact attestation CoreTransferable runtime-log \
    attestation/coretransferable-runtime.log
record_artifact attestation Photos runtime-log \
    attestation/photos-runtime.log
record_artifact attestation PhotosUI runtime-log \
    attestation/photosui-runtime.log
record_artifact attestation Accelerate apple-golden \
    attestation/accelerate-box-convolve-apple.txt
record_artifact attestation Accelerate native-oracle-log \
    attestation/accelerate-native-oracle.log
record_artifact attestation Accelerate runtime-log \
    attestation/accelerate-runtime.log
record_artifact attestation Compression apple-golden \
    attestation/compression-brotli-apple.txt
record_artifact attestation Compression abi \
    attestation/open-compression-abi.tsv
record_artifact attestation Compression host \
    attestation/open-compression-host.tsv
record_artifact attestation Compression host-test-log \
    attestation/open-compression-host-test.log
record_artifact attestation Compression runtime-log \
    attestation/compression-runtime.log
record_artifact attestation CoreText apple-golden \
    attestation/coretext-font-manager-apple.txt
record_artifact attestation CoreText runtime-log \
    attestation/coretext-runtime.log
record_artifact attestation CoreText apple-differential-log \
    attestation/coretext-font-manager-runtime.log
record_artifact attestation AdServices apple-golden \
    attestation/adservices-interface-apple.txt
record_artifact attestation AdServices runtime-log \
    attestation/adservices-runtime.log
record_artifact attestation AdServices apple-differential-log \
    attestation/adservices-interface-runtime.log
record_artifact attestation zlib apple-golden \
    attestation/zlib-gzip-apple.txt
record_artifact attestation zlib abi attestation/open-zlib-abi.tsv
record_artifact attestation zlib host attestation/open-zlib-host.tsv
record_artifact attestation zlib host-test-log \
    attestation/open-zlib-host-test.log
record_artifact attestation zlib native-oracle-log \
    attestation/zlib-native-oracle.log
record_artifact attestation zlib runtime-log attestation/zlib-runtime.log
record_artifact attestation zlib apple-differential-log \
    attestation/zlib-gzip-runtime.log
record_artifact attestation IOKit apple-golden \
    attestation/iokit-interface-apple.txt
record_artifact attestation IOKit portable-golden \
    attestation/iokit-interface-portable.txt
record_artifact attestation IOKit framework-contract \
    attestation/iokit-framework.tsv
record_artifact attestation IOKit host-test-log \
    attestation/iokit-host-test.log
record_artifact attestation SwiftIOKit runtime-contract \
    attestation/swift-iokit-runtime.tsv
record_artifact attestation SwiftIOKit host-test-log \
    attestation/swift-iokit-host-test.log
record_artifact attestation IOKit runtime-log attestation/iokit-runtime.log
record_artifact attestation IOKit portable-interface-log \
    attestation/iokit-interface-runtime.log
record_artifact attestation NaturalLanguage runtime-log \
    attestation/naturallanguage-runtime.log
record_artifact attestation AuthenticationServices runtime-log \
    attestation/authenticationservices-runtime.log
record_artifact attestation AppKit sources-manifest \
    attestation/appkit-sources.tsv
record_artifact attestation AppKit framework-contract \
    attestation/appkit-framework.tsv
record_artifact attestation AppKit exports \
    attestation/appkit-exports.txt
record_artifact attestation AppKit imports \
    attestation/appkit-imports.txt
record_artifact attestation AppKit loads \
    attestation/appkit-loads.txt
record_artifact attestation AppKit load-identities \
    attestation/appkit-load-identities.txt
record_artifact attestation AppKit apple-golden \
    attestation/appkit-interface-apple.txt
record_artifact attestation AppKit runtime-log \
    attestation/AppKitGuestRuntime.log
record_artifact attestation AppKit apple-differential-log \
    attestation/AppKitInterfaceOracle.log
record_artifact attestation AppKit swiftui-runtime-log \
    attestation/SwiftUIAppKitColorRuntime.log
record_artifact attestation AppKit storekit-runtime-log \
    attestation/StoreKitAppKitRuntime.log
record_artifact attestation dispatch host \
    attestation/open-dispatch-host.tsv
record_artifact attestation dispatch host-test-log \
    attestation/open-dispatch-host-test.log
record_artifact attestation dispatch runtime-log \
    attestation/dispatch-runtime.log
record_artifact attestation SwiftUI reexport-runtime-log \
    attestation/swiftui-foundation-reexport-runtime.log
record_artifact attestation SwiftUI compiler-plugin-log \
    attestation/swiftui-compiler-plugins.log
record_artifact attestation foundation-urlsession runtime-log \
    attestation/foundation-urlsession-runtime.log
record_artifact attestation foundation-cache apple-golden \
    attestation/foundation-cache-apple.txt
record_artifact attestation foundation-cache runtime-log \
    attestation/foundation-cache-runtime.log
record_artifact attestation foundation-byte-count apple-golden \
    attestation/foundation-byte-count-apple.txt
record_artifact attestation foundation-byte-count runtime-log \
    attestation/foundation-byte-count-runtime.log
record_artifact attestation contracts compile-rsp compile-flags.rsp
record_artifact attestation contracts link-rsp link-inputs.rsp
record_artifact attestation source-sets manifest attestation/source-sets.tsv
record_artifact attestation foundation-sources manifest \
    attestation/foundation-sources.tsv
record_artifact attestation observation-sources manifest \
    attestation/observation-sources.tsv
record_artifact attestation observation-macro-plugin closure \
    attestation/observation-macro-plugin.tsv
record_artifact attestation compiler-plugins manifest \
    attestation/compiler-plugins.tsv
record_artifact attestation intents-sources manifest \
    attestation/intents-sources.tsv
record_artifact attestation graphics-sources manifest \
    attestation/graphics-sources.tsv
record_artifact attestation webkit-sources manifest \
    attestation/webkit-sources.tsv
record_artifact attestation webkit-dylib-loads manifest \
    attestation/webkit-dylib-loads.tsv
record_artifact attestation foundation-undefined-symbols undefined-symbols \
    attestation/foundation-undefined-symbols.txt
record_artifact attestation foundation-runtime-exports defined-symbols \
    attestation/foundation-runtime-exports.txt
record_artifact attestation foundation-bindings dyld-bind-audit \
    attestation/foundation-bindings.txt
record_artifact attestation FoundationEssentials removefile-semantics \
    attestation/removefile-compat-tests.log
record_artifact attestation FoundationEssentials group-lookup-semantics \
    attestation/group-lookup-macho.log
record_artifact attestation FoundationEssentials xattr-semantics \
    attestation/xattr-macho.log
record_artifact attestation FoundationEssentials fts-apple-golden \
    attestation/fts-apple.txt
record_artifact attestation FoundationEssentials fts-apple-binary-summary \
    attestation/fts-apple-summary.txt
record_artifact attestation FoundationEssentials fts-runtime-semantics \
    attestation/fts-macho.log
record_artifact attestation FoundationEssentials statfs-apple-golden \
    attestation/statfs-apple.txt
record_artifact attestation FoundationEssentials statfs-apple-binary-summary \
    attestation/statfs-apple-summary.txt
record_artifact attestation FoundationEssentials statfs-runtime-semantics \
    attestation/statfs-macho.log
record_artifact attestation FoundationEssentials copyfile-apple-golden \
    attestation/copyfile-apple.txt
record_artifact attestation FoundationEssentials copyfile-apple-binary-summary \
    attestation/copyfile-apple-summary.txt
record_artifact attestation FoundationEssentials copyfile-runtime-semantics \
    attestation/copyfile-macho.log
record_artifact attestation FoundationEssentials copyfile-xattr-unavailable-semantics \
    attestation/copyfile-xattr-unavailable-macho.log
record_artifact attestation FoundationEssentials libSystem-compat-semantics \
    attestation/libsystem-compat-macho.log
record_artifact attestation first-party-sources manifest \
    attestation/first-party-sources.tsv
record_artifact attestation first-party-dylib-loads manifest \
    attestation/first-party-dylib-loads.tsv
record_artifact attestation input-provenance manifest \
    attestation/input-provenance.tsv
record_artifact attestation Swift-core runtime-contract \
    attestation/swift-core-runtime.tsv
record_artifact attestation Swift-core build-full-stage \
    attestation/build-full-swift-core-stage.json
record_artifact attestation url-transport abi \
    attestation/url-transport-abi.tsv
record_artifact attestation url-transport host \
    attestation/url-transport-host.tsv
record_artifact attestation relative-time abi \
    attestation/relative-time-abi.tsv
record_artifact attestation relative-time host \
    attestation/relative-time-host.tsv
record_artifact attestation FoundationInternationalization sources \
    attestation/foundation-internationalization-sources.tsv
record_artifact attestation FoundationInternationalization abi \
    attestation/foundation-internationalization-abi.tsv
record_artifact attestation FoundationInternationalization host \
    attestation/foundation-internationalization-host.tsv
record_artifact attestation sdk-tree manifest attestation/sdk-tree.tsv
record_artifact attestation sdk-dangling-symlinks manifest \
    attestation/sdk-dangling-symlinks.tsv
record_artifact attestation sdk-dangling-exclusions manifest \
    attestation/sdk-dangling-symlink-exclusions.tsv
record_artifact attestation include-tree manifest attestation/include-tree.tsv
record_artifact attestation guest-root-tree manifest \
    attestation/guest-root-tree.tsv
record_artifact attestation resources-tree manifest \
    attestation/openuikit-resources-tree.tsv
record_artifact attestation runtime-closure manifest \
    attestation/runtime-closure.tsv
record_artifact attestation probe-link manifest attestation/probe-link-audit.tsv
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    record_artifact attestation preview load-rsp preview-plugin-load-flag.rsp
    record_artifact attestation preview manifest attestation/preview-input.tsv
fi

echo '== post-build input bracket'
assert_clean_commit "$UIKIT" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" post-OpenUIKit
require_hash "$MACHORUN/darwin/usr/lib/swift/libswiftCore.dylib" \
    "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256" post-machorun-Swift-core
require_hash "$MACHORUN/darwin/usr/lib/libobjc.A.dylib" \
    "$EXPECTED_MACHORUN_OBJC_SHA256" post-machorun-Objective-C-runtime
assert_clean_commit "$MACHORUN" "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" post-machorun
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE" post-swift-foundation
assert_clean_commit "$SWIFT_FOUNDATION_ICU" "$EXPECTED_FOUNDATION_ICU_COMMIT" \
    "$EXPECTED_FOUNDATION_ICU_TREE" post-swift-foundation-icu
assert_clean_commit "$SWIFT_COLLECTIONS" "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE" post-swift-collections
assert_clean_commit "$OPENCOMBINE_SOURCE" "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE" post-OpenCombine
[ "$SUPPORT_COMMIT" = "$(git -C "$W" rev-parse HEAD)" ] \
    && [ "$SUPPORT_TREE" = "$(git -C "$W" rev-parse HEAD^{tree})" ] \
    && [ -z "$(git -C "$W" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'support checkout changed during build'
python3 "$MANIFEST_TOOL" foundation-sources \
    --support-root "$W" --manifest "$FOUNDATION_SOURCES_MANIFEST" \
    --output "$WORK/foundation-sources.post.tsv"
cmp "$WORK/foundation-sources.pre.tsv" "$WORK/foundation-sources.post.tsv" \
    || die 'Foundation source manifest/files changed during build'
write_observation_sources_attestation "$WORK/observation-sources.post.tsv"
cmp "$WORK/observation-sources.pre.tsv" "$WORK/observation-sources.post.tsv" \
    || die 'Observation source manifest/files changed during build'
python3 -B "$WEBKIT_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$WEBKIT_PROVENANCE_POLICY" \
    --output "$WORK/webkit-sources.post.tsv"
cmp "$WORK/webkit-sources.pre.tsv" "$WORK/webkit-sources.post.tsv" \
    || die 'WebKit source manifest/files changed during build'
{
    printf 'format\tframework-guest-sources-v1\n'
    printf 'manifest\tIntents\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTS_SOURCES_MANIFEST")" "${#INTENTS_SOURCES[@]}"
    for relative in "${INTENTS_SOURCES[@]}"; do
        printf 'source\tIntents\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
    printf 'manifest\tIntentsUI\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTSUI_SOURCES_MANIFEST")" "${#INTENTSUI_SOURCES[@]}"
    for relative in "${INTENTSUI_SOURCES[@]}"; do
        printf 'source\tIntentsUI\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
} > "$WORK/intents-sources.post.tsv"
cmp "$WORK/intents-sources.pre.tsv" "$WORK/intents-sources.post.tsv" \
    || die 'Intents/IntentsUI source manifests/files changed during build'

write_graphics_sources_attestation "$WORK/graphics-sources.post.tsv"
cmp "$WORK/graphics-sources.pre.tsv" "$WORK/graphics-sources.post.tsv" \
    || die 'CoreImage/QuartzCore source manifests/files changed during build'

write_appkit_sources_attestation "$WORK/appkit-sources.post.tsv"
cmp "$WORK/appkit-sources.pre.tsv" "$WORK/appkit-sources.post.tsv" \
    || die 'AppKit production source manifests/files changed during build'

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.post.tsv"
append_frontier_sources "$WORK/first-party-sources.post.tsv"
cmp "$WORK/first-party-sources.pre.tsv" "$WORK/first-party-sources.post.tsv" \
    || die 'first-party source manifests/files changed during build'
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$UIKIT/Sources/OpenUIKit/Resources" \
    --logical-root resources/OpenUIKit --reject-symlinks \
    --output "$WORK/openuikit-resources.post.tsv"
cmp "$WORK/openuikit-resources.pre.tsv" "$WORK/openuikit-resources.post.tsv" \
    || die 'OpenUIKit resources changed during build'
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$SYS" --logical-root sdk \
    --dangling-exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk.post.tsv"
cmp "$WORK/sdk.pre.tsv" "$WORK/sdk.post.tsv" \
    || die 'SDK input changed during build'
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$SYS" --exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk-dangling.post.tsv"
cmp "$WORK/sdk-dangling.pre.tsv" "$WORK/sdk-dangling.post.tsv" \
    || die 'SDK dangling-symlink input changed during build'
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT" post-system-font
require_hash "$BOLD_FONT" "$EXPECTED_BOLD_FONT" post-bold-font
require_hash "$FOUNDATION_CACHE_ORACLE" \
    "$EXPECTED_FOUNDATION_CACHE_ORACLE_SHA256" post-Foundation-cache-oracle
require_hash "$FOUNDATION_CACHE_GOLDEN" \
    "$EXPECTED_FOUNDATION_CACHE_GOLDEN_SHA256" post-Foundation-cache-Apple-golden
require_hash "$FOUNDATION_BYTE_COUNT_ORACLE" \
    "$EXPECTED_FOUNDATION_BYTE_COUNT_ORACLE_SHA256" post-Foundation-byte-count-oracle
require_hash "$FOUNDATION_BYTE_COUNT_GOLDEN" \
    "$EXPECTED_FOUNDATION_BYTE_COUNT_GOLDEN_SHA256" post-Foundation-byte-count-Apple-golden
require_hash "$OBSERVATION_MACRO_PLUGIN" "$EXPECTED_OBSERVATION_PLUGIN_SHA" \
    post-Observation-macro-plugin
require_hash "$FOUNDATION_MACRO_PLUGIN" "$EXPECTED_FOUNDATION_PLUGIN_SHA" \
    post-Foundation-macro-plugin
for index in "${!OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_HOST_LIBS[$index]}
    require_hash "/usr/lib/swift/host/$library" \
        "${OBSERVATION_PLUGIN_HOST_HASHES[$index]}" \
        "post-Observation-plugin-host-$library"
done
for index in "${!OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_LINUX_LIBS[$index]}
    require_hash "/usr/lib/swift/linux/$library" \
        "${OBSERVATION_PLUGIN_LINUX_HASHES[$index]}" \
        "post-Observation-plugin-linux-$library"
done
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    require_hash "$DEVELOPER_TOOLS_SUPPORT_MODULE" "$PREVIEW_MODULE_SHA" post-DTS-module
    require_hash "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_OBJECT_SHA" post-DTS-object
    require_hash "$PREVIEW_MACRO_PLUGIN" "$PREVIEW_PLUGIN_SHA" post-preview-plugin
fi

WRITE_ARGS=(
    write --package-root "$STAGE"
    --artifact-ledger "$ARTIFACT_LEDGER"
    --artifact-ledger-relative attestation/artifacts.tsv
    --input-provenance attestation/input-provenance.tsv
    --source-sets attestation/source-sets.tsv
    --foundation-sources attestation/foundation-sources.tsv
    --intents-sources attestation/intents-sources.tsv
    --graphics-sources attestation/graphics-sources.tsv
    --appkit-sources attestation/appkit-sources.tsv
    --webkit-sources attestation/webkit-sources.tsv
    --first-party-sources attestation/first-party-sources.tsv
    --first-party-dylib-loads attestation/first-party-dylib-loads.tsv
    --sdk-inventory attestation/sdk-tree.tsv
    --sdk-dangling-symlinks attestation/sdk-dangling-symlinks.tsv
    --sdk-dangling-exclusions attestation/sdk-dangling-symlink-exclusions.tsv
    --include-inventory attestation/include-tree.tsv
    --guest-inventory attestation/guest-root-tree.tsv
    --resource-inventory attestation/openuikit-resources-tree.tsv
    --runtime-closure attestation/runtime-closure.tsv
    --compiler-plugins attestation/compiler-plugins.tsv
    --compile-rsp compile-flags.rsp --link-rsp link-inputs.rsp
)
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || WRITE_ARGS+=(--preview-attestation attestation/preview-input.tsv \
        --external-preview-plugin "$PREVIEW_MACRO_PLUGIN")
python3 "$MANIFEST_TOOL" "${WRITE_ARGS[@]}"
VERIFY_PREVIEW_ARGS=()
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || VERIFY_PREVIEW_ARGS=(--preview-plugin "$PREVIEW_MACRO_PLUGIN")
python3 "$MANIFEST_TOOL" verify --package-root "$STAGE" \
    "${VERIFY_PREVIEW_ARGS[@]}"
{
    printf 'format\tcore-package-complete-v1\n'
    printf 'core-package-json\t%s\n' \
        "$(hash_file "$STAGE/attestation/core-package.json")"
    printf 'artifacts\t%s\n' "$(hash_file "$ARTIFACT_LEDGER")"
    printf 'runtime-closure\t%s\n' \
        "$(hash_file "$STAGE/attestation/runtime-closure.tsv")"
    printf 'runtime-log\t%s\n' "$(hash_file "$STAGE/attestation/runtime.log")"
} > "$STAGE/PACKAGE_COMPLETE"

mv -- "$STAGE" "$OUTPUT_ROOT"
python3 "$MANIFEST_TOOL" verify --package-root "$OUTPUT_ROOT" \
    "${VERIFY_PREVIEW_ARGS[@]}"
SUCCESS=1
echo "CORE_GUEST_PACKAGE_OK output=$OUTPUT_ROOT target=$TARGET preview=$PREVIEW_ENABLED"
