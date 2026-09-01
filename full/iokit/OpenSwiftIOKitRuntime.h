#ifndef OPENUIKIT_SWIFT_IOKIT_RUNTIME_H
#define OPENUIKIT_SWIFT_IOKIT_RUNTIME_H

#include <stdint.h>

// Complete public symbol/value contract from the Xcode 26.1 macOS SDK's
// libswiftIOKit.tbd and IOKit/IOReturn.h. Values use the common IOKit system
// and subsystem bits (0xe0000000) plus the published return code.
#define OPEN_SWIFT_IOKIT_CONSTANTS(X) \
    X(Busy, "_$s5IOKit13kIOReturnBusys5Int32Vvg", 0x2d5u) \
    X(Error, "_$s5IOKit14kIOReturnErrors5Int32Vvg", 0x2bcu) \
    X(Aborted, "_$s5IOKit16kIOReturnAborteds5Int32Vvg", 0x2ebu) \
    X(IOError, "_$s5IOKit16kIOReturnIOErrors5Int32Vvg", 0x2cau) \
    X(Invalid, "_$s5IOKit16kIOReturnInvalids5Int32Vvg", 0x001u) \
    X(NoMedia, "_$s5IOKit16kIOReturnNoMedias5Int32Vvg", 0x2e4u) \
    X(NoPower, "_$s5IOKit16kIOReturnNoPowers5Int32Vvg", 0x2e3u) \
    X(NoSpace, "_$s5IOKit16kIOReturnNoSpaces5Int32Vvg", 0x2dbu) \
    X(NotOpen, "_$s5IOKit16kIOReturnNotOpens5Int32Vvg", 0x2cdu) \
    X(Offline, "_$s5IOKit16kIOReturnOfflines5Int32Vvg", 0x2d7u) \
    X(Overrun, "_$s5IOKit16kIOReturnOverruns5Int32Vvg", 0x2e8u) \
    X(Timeout, "_$s5IOKit16kIOReturnTimeouts5Int32Vvg", 0x2d6u) \
    X(VMError, "_$s5IOKit16kIOReturnVMErrors5Int32Vvg", 0x2c8u) \
    X(BadMedia, "_$s5IOKit17kIOReturnBadMedias5Int32Vvg", 0x2d1u) \
    X(DMAError, "_$s5IOKit17kIOReturnDMAErrors5Int32Vvg", 0x2d4u) \
    X(IPCError, "_$s5IOKit17kIOReturnIPCErrors5Int32Vvg", 0x2bfu) \
    X(NoDevice, "_$s5IOKit17kIOReturnNoDevices5Int32Vvg", 0x2c0u) \
    X(NoFrames, "_$s5IOKit17kIOReturnNoFramess5Int32Vvg", 0x2e0u) \
    X(NoMemory, "_$s5IOKit17kIOReturnNoMemorys5Int32Vvg", 0x2bdu) \
    X(NotFound, "_$s5IOKit17kIOReturnNotFounds5Int32Vvg", 0x2f0u) \
    X(NotReady, "_$s5IOKit17kIOReturnNotReadys5Int32Vvg", 0x2d8u) \
    X(RLDError, "_$s5IOKit17kIOReturnRLDErrors5Int32Vvg", 0x2d3u) \
    X(Underrun, "_$s5IOKit17kIOReturnUnderruns5Int32Vvg", 0x2e7u) \
    X(IsoTooNew, "_$s5IOKit18kIOReturnIsoTooNews5Int32Vvg", 0x2efu) \
    X(IsoTooOld, "_$s5IOKit18kIOReturnIsoTooOlds5Int32Vvg", 0x2eeu) \
    X(StillOpen, "_$s5IOKit18kIOReturnStillOpens5Int32Vvg", 0x2d2u) \
    X(CannotLock, "_$s5IOKit19kIOReturnCannotLocks5Int32Vvg", 0x2ccu) \
    X(CannotWire, "_$s5IOKit19kIOReturnCannotWires5Int32Vvg", 0x2deu) \
    X(LockedRead, "_$s5IOKit19kIOReturnLockedReads5Int32Vvg", 0x2c3u) \
    X(NoChannels, "_$s5IOKit19kIOReturnNoChannelss5Int32Vvg", 0x2dau) \
    X(NotAligned, "_$s5IOKit19kIOReturnNotAligneds5Int32Vvg", 0x2d0u) \
    X(PortExists, "_$s5IOKit19kIOReturnPortExistss5Int32Vvg", 0x2ddu) \
    X(BadArgument, "_$s5IOKit20kIOReturnBadArguments5Int32Vvg", 0x2c2u) \
    X(DeviceError, "_$s5IOKit20kIOReturnDeviceErrors5Int32Vvg", 0x2e9u) \
    X(LockedWrite, "_$s5IOKit20kIOReturnLockedWrites5Int32Vvg", 0x2c4u) \
    X(NoBandwidth, "_$s5IOKit20kIOReturnNoBandwidths5Int32Vvg", 0x2ecu) \
    X(NoInterrupt, "_$s5IOKit20kIOReturnNoInterrupts5Int32Vvg", 0x2dfu) \
    X(NoResources, "_$s5IOKit20kIOReturnNoResourcess5Int32Vvg", 0x2beu) \
    X(NotAttached, "_$s5IOKit20kIOReturnNotAttacheds5Int32Vvg", 0x2d9u) \
    X(NotReadable, "_$s5IOKit20kIOReturnNotReadables5Int32Vvg", 0x2ceu) \
    X(NotWritable, "_$s5IOKit20kIOReturnNotWritables5Int32Vvg", 0x2cfu) \
    X(Unsupported, "_$s5IOKit20kIOReturnUnsupporteds5Int32Vvg", 0x2c7u) \
    X(BadMessageID, "_$s5IOKit21kIOReturnBadMessageIDs5Int32Vvg", 0x2c6u) \
    X(NoCompletion, "_$s5IOKit21kIOReturnNoCompletions5Int32Vvg", 0x2eau) \
    X(NotPermitted, "_$s5IOKit21kIOReturnNotPermitteds5Int32Vvg", 0x2e2u) \
    X(InternalError, "_$s5IOKit22kIOReturnInternalErrors5Int32Vvg", 0x2c9u) \
    X(NotPrivileged, "_$s5IOKit22kIOReturnNotPrivilegeds5Int32Vvg", 0x2c1u) \
    X(NotResponding, "_$s5IOKit22kIOReturnNotRespondings5Int32Vvg", 0x2edu) \
    X(ExclusiveAccess, "_$s5IOKit24kIOReturnExclusiveAccesss5Int32Vvg", 0x2c5u) \
    X(MessageTooLarge, "_$s5IOKit24kIOReturnMessageTooLarges5Int32Vvg", 0x2e1u) \
    X(UnsupportedMode, "_$s5IOKit24kIOReturnUnsupportedModes5Int32Vvg", 0x2e6u) \
    X(UnformattedMedia, "_$s5IOKit25kIOReturnUnformattedMedias5Int32Vvg", 0x2e5u)

#define OPEN_SWIFT_IOKIT_COMMON_ERROR(code) \
    ((int32_t)(UINT32_C(0xe0000000) | (uint32_t)(code)))

#endif
