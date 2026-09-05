#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atDepthExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atPCMBlob(
    rate: Float64 = 44100,
    channels: UInt32 = 1,
    bits: UInt32 = 16,
    flags: UInt32 = 12
) -> [UInt8] {
    var blob = [UInt8](repeating: 0, count: 40)
    let bytesPerFrame = (bits / 8) * channels
    blob.withUnsafeMutableBytes { raw in
        let p = raw.baseAddress!
        p.storeBytes(of: rate, toByteOffset: 0, as: Float64.self)
        p.storeBytes(of: UInt32(0x6C70_636D), toByteOffset: 8, as: UInt32.self)
        p.storeBytes(of: flags, toByteOffset: 12, as: UInt32.self)
        p.storeBytes(of: bytesPerFrame, toByteOffset: 16, as: UInt32.self)
        p.storeBytes(of: UInt32(1), toByteOffset: 20, as: UInt32.self)
        p.storeBytes(of: bytesPerFrame, toByteOffset: 24, as: UInt32.self)
        p.storeBytes(of: channels, toByteOffset: 28, as: UInt32.self)
        p.storeBytes(of: bits, toByteOffset: 32, as: UInt32.self)
    }
    return blob
}

#if canImport(CoreFoundation)
private func atDepthFileURL(_ path: String) -> CFURL {
    path.withCString { cstr in
        CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
            path.utf8.count,
            false
        )!
    }
}
#endif

func testAudioFilePropertyIDsExact() {
    atDepthExpect(kAudioFilePropertyFileFormat == 0x6666_6D74, "ffmt")
    atDepthExpect(kAudioFilePropertyDataFormat == 0x6466_6D74, "dfmt")
    atDepthExpect(kAudioFilePropertyIsOptimized == 0x6F70_746D, "optm")
    atDepthExpect(kAudioFilePropertyMagicCookieData == 0x6D67_6963, "mgic")
    atDepthExpect(kAudioFilePropertyAudioDataByteCount == 0x6263_6E74, "bcnt")
    atDepthExpect(kAudioFilePropertyAudioDataPacketCount == 0x7063_6E74, "pcnt")
    atDepthExpect(kAudioFilePropertyMaximumPacketSize == 0x7073_7A65, "psze")
    atDepthExpect(kAudioFilePropertyDataOffset == 0x646F_6666, "doff")
    atDepthExpect(kAudioFilePropertyChannelLayout == 0x636D_6170, "cmap")
    atDepthExpect(kAudioFilePropertyDeferSizeUpdates == 0x6473_7A75, "dszu")
    atDepthExpect(kAudioFilePropertyDataFormatName == 0x666E_6D65, "fnme")
    atDepthExpect(kAudioFilePropertyMarkerList == 0x6D6B_6C73, "mkls")
    atDepthExpect(kAudioFilePropertyRegionList == 0x7267_6C73, "rgls")
    atDepthExpect(kAudioFilePropertyPacketToFrame == 0x706B_6672, "pkfr")
    atDepthExpect(kAudioFilePropertyFrameToPacket == 0x6672_706B, "frpk")
    atDepthExpect(kAudioFilePropertyPacketToByte == 0x706B_6279, "pkby")
    atDepthExpect(kAudioFilePropertyByteToPacket == 0x6279_706B, "bypk")
    atDepthExpect(kAudioFilePropertyChunkIDs == 0x6368_6964, "chid")
    atDepthExpect(kAudioFilePropertyInfoDictionary == 0x696E_666F, "info")
    atDepthExpect(kAudioFilePropertyPacketTableInfo == 0x706E_666F, "pnfo")
    atDepthExpect(kAudioFilePropertyFormatList == 0x666C_7374, "flst")
    atDepthExpect(kAudioFilePropertyPacketSizeUpperBound == 0x706B_7562, "pkub")
    atDepthExpect(kAudioFilePropertyEstimatedDuration == 0x6564_7572, "edur")
    atDepthExpect(kAudioFilePropertyBitRate == 0x6272_6174, "brat")
    atDepthExpect(kAudioFilePropertyID3Tag == 0x6964_3374, "id3t")
    atDepthExpect(kAudioFilePropertySourceBitDepth == 0x7362_7464, "sbtd")
    atDepthExpect(kAudioFilePropertyAlbumArtwork == 0x6161_7274, "aart")
    atDepthExpect(kAudioFilePropertyAudioTrackCount == 0x6174_6374, "atct")
    atDepthExpect(kAudioFilePropertyUseAudioTrack == 0x7561_746B, "uatk")
    atDepthExpect(kAudioFilePropertyID3TagOffset == 0x6964_336F, "id3o")
    atDepthExpect(kAudioFilePropertyNextIndependentPacket == 0x6E69_6E64, "nind")
    atDepthExpect(kAudioFilePropertyPreviousIndependentPacket == 0x7069_6E64, "pind")
    atDepthExpect(kAudioFilePropertyPacketToDependencyInfo == 0x7064_6570, "pdep")
    atDepthExpect(kAudioFilePropertyPacketToRollDistance == 0x7072_6C6C, "prll")
    atDepthExpect(kAudioFilePropertyRestrictsRandomAccess == 0x7272_616E, "rran")
    atDepthExpect(kAudioFilePropertyPacketRangeByteCountUpperBound == 0x7072_7562, "prub")
    atDepthExpect(kAudioFilePropertyReserveDuration == 0x7273_7276, "rsrv")
}

func testExtAudioFilePropertyIDsExact() {
    atDepthExpect(kExtAudioFileProperty_FileDataFormat == 0x6666_6D74, "ffmt")
    atDepthExpect(kExtAudioFileProperty_ClientDataFormat == 0x6366_6D74, "cfmt")
    atDepthExpect(kExtAudioFileProperty_FileChannelLayout == 0x6663_6C6F, "fclo")
    atDepthExpect(kExtAudioFileProperty_ClientChannelLayout == 0x6363_6C6F, "cclo")
    atDepthExpect(kExtAudioFileProperty_CodecManufacturer == 0x636D_616E, "cman")
    atDepthExpect(kExtAudioFileProperty_AudioConverter == 0x6163_6E76, "acnv")
    atDepthExpect(kExtAudioFileProperty_AudioFile == 0x6166_696C, "afil")
    atDepthExpect(kExtAudioFileProperty_FileMaxPacketSize == 0x666D_7073, "fmps")
    atDepthExpect(kExtAudioFileProperty_ClientMaxPacketSize == 0x636D_7073, "cmps")
    atDepthExpect(kExtAudioFileProperty_FileLengthFrames == 0x2366_726D, "#frm")
    atDepthExpect(kExtAudioFileProperty_ConverterConfig == 0x6163_6366, "accf")
    atDepthExpect(kExtAudioFileProperty_IOBufferSizeBytes == 0x696F_6273, "iobs")
    atDepthExpect(kExtAudioFileProperty_IOBuffer == 0x696F_6266, "iobf")
    atDepthExpect(kExtAudioFileProperty_PacketTable == 0x7870_7469, "xpti")
}

func testAudioQueuePropertyIDsExact() {
    atDepthExpect(kAudioQueueProperty_IsRunning == 0x6171_726E, "aqrn")
    atDepthExpect(kAudioQueueProperty_StreamDescription == 0x6171_6674, "aqft")
    atDepthExpect(kAudioQueueProperty_CurrentDevice == 0x6171_6364, "aqcd")
    atDepthExpect(kAudioQueueProperty_MagicCookie == 0x6171_6D63, "aqmc")
    atDepthExpect(kAudioQueueProperty_MaximumOutputPacketSize == 0x786F_7073, "xops")
    atDepthExpect(kAudioQueueProperty_ChannelLayout == 0x6171_636C, "aqcl")
    atDepthExpect(kAudioQueueProperty_EnableLevelMetering == 0x6171_6D65, "aqme")
    atDepthExpect(kAudioQueueProperty_CurrentLevelMeter == 0x6171_6D76, "aqmv")
    atDepthExpect(kAudioQueueProperty_CurrentLevelMeterDB == 0x6171_6D64, "aqmd")
    atDepthExpect(kAudioQueueProperty_DecodeBufferSizeFrames == 0x6463_6266, "dcbf")
    atDepthExpect(kAudioQueueProperty_ConverterError == 0x7163_7665, "qcve")
    atDepthExpect(kAudioQueueProperty_EnableTimePitch == 0x715F_7470, "q_tp")
    atDepthExpect(kAudioQueueProperty_TimePitchAlgorithm == 0x7174_7061, "qtpa")
    atDepthExpect(kAudioQueueProperty_TimePitchBypass == 0x7174_7062, "qtpb")
    atDepthExpect(kAudioQueueProperty_HardwareCodecPolicy == 0x6171_6370, "aqcp")
    atDepthExpect(kAudioQueueProperty_ChannelAssignments == 0x6171_6361, "aqca")
    atDepthExpect(kAudioQueueDeviceProperty_SampleRate == 0x6171_7372, "aqsr")
    atDepthExpect(kAudioQueueDeviceProperty_NumberChannels == 0x6171_6463, "aqdc")
}

func testAudioConverterPropertyIDsExact() {
    atDepthExpect(kAudioConverterChannelMap == 0x6368_6D70, "chmp")
    atDepthExpect(kAudioConverterCurrentInputStreamDescription == 0x6163_6964, "acid")
    atDepthExpect(kAudioConverterCurrentOutputStreamDescription == 0x6163_6F64, "acod")
    atDepthExpect(kAudioConverterCodecQuality == 0x6364_7175, "cdqu")
    atDepthExpect(kAudioConverterPrimeMethod == 0x7072_6D6D, "prmm")
    atDepthExpect(kAudioConverterPrimeInfo == 0x7072_696D, "prim")
    atDepthExpect(kAudioConverterQuality_Max == 0x7F, "max")
    atDepthExpect(kAudioConverterQuality_Min == 0, "min")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity_Linear == 0x6C69_6E65, "line")
    atDepthExpect(AudioConverterOptions.unbuffered.rawValue == 1, "unbuffered")
}

func testAudioFormatPropertyIDsExact() {
    atDepthExpect(kAudioFormatProperty_FormatInfo == 0x666D_7469, "fmti")
    atDepthExpect(kAudioFormatProperty_FormatName == 0x666E_616D, "fnam")
    atDepthExpect(kAudioFormatProperty_FormatIsVBR == 0x6676_6272, "fvbr")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutName == 0x6C6F_6E6D, "lonm")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutSimpleName == 0x6C73_6E6D, "lsnm")
    atDepthExpect(kAudioFormatUnsupportedPropertyError == Int32(bitPattern: 0x7072_6F70), "prop")
    atDepthExpect(kAudioFormatUnspecifiedError == Int32(bitPattern: 0x7768_6174), "what")
}

func testCAFChunkAndMarkerIDsExact() {
    atDepthExpect(kCAF_FileType == 0x6361_6666, "caff")
    atDepthExpect(kCAF_FileVersion_Initial == 1, "v1")
    atDepthExpect(kCAF_StreamDescriptionChunkID == 0x6465_7363, "desc")
    atDepthExpect(kCAF_AudioDataChunkID == 0x6461_7461, "data")
    atDepthExpect(kCAF_ChannelLayoutChunkID == 0x6368_616E, "chan")
    atDepthExpect(kCAF_PacketTableChunkID == 0x7061_6B74, "pakt")
    atDepthExpect(kCAF_MagicCookieID == 0x6B75_6B69, "kuki")
    atDepthExpect(kCAF_FillerChunkID == 0x6672_6565, "free")
    atDepthExpect(kCAFMarkerType_Generic == 0, "generic")
    atDepthExpect(kCAF_SMPTE_TimeTypeNone == 0, "smpte none")
    atDepthExpect(CAFFormatFlags.linearPCMFormatFlagIsFloat.rawValue == 1, "float")
    atDepthExpect(CAFFormatFlags.linearPCMFormatFlagIsLittleEndian.rawValue == 2, "le")
    var header = CAFFileHeader()
    atDepthExpect(header.mFileType == kCAF_FileType, "header type")
    header = CAFFileHeader(mFileType: kCAF_FileType, mFileVersion: 1, mFileFlags: 0)
    atDepthExpect(header.mFileVersion == 1, "version")
}

func testAudioUnitPropertyAndScopeIDsExact() {
    atDepthExpect(kAudioUnitScope_Global == 0, "global")
    atDepthExpect(kAudioUnitScope_Input == 1, "input")
    atDepthExpect(kAudioUnitScope_Output == 2, "output")
    atDepthExpect(kAudioUnitProperty_ClassInfo == 0, "class")
    atDepthExpect(kAudioUnitProperty_StreamFormat == 8, "asbd")
    atDepthExpect(kAudioUnitProperty_ElementCount == 11, "elements")
    atDepthExpect(kAudioUnitProperty_SetRenderCallback == 23, "callback")
    atDepthExpect(kAudioUnitProperty_MeteringMode == 3007, "meter")
    atDepthExpect(kAudioUnitProperty_ScheduleAudioSlice == 3300, "slice")
    atDepthExpect(AudioUnitRenderActionFlags.unitRenderAction_PreRender.rawValue == 1 << 2, "prerender")
    atDepthExpect(AudioUnitParameterUnit.hertz.rawValue == 8, "hz")
    atDepthExpect(AudioUnitParameterOptions.flag_CanRamp.rawValue == 1 << 24, "ramp")
}

func testAudioSessionDeprecatedConstants() {
    atDepthExpect(kAudioSessionNoError == 0, "ok")
    atDepthExpect(kAudioSessionCategory_PlayAndRecord == 0x706C_6172, "plar")
    atDepthExpect(kAudioSessionMode_Default == 0x6466_6C74, "dflt")
    atDepthExpect(kAudioSessionBeginInterruption == 1, "begin")
    atDepthExpect(kAudioSessionRouteChangeReason_NewDeviceAvailable == 1, "new device")
}

func testAudioFormatGetPropertyPCM() {
    let blob = atPCMBlob()
    var size: UInt32 = 40
    var out = [UInt8](repeating: 0, count: 40)
    let status = blob.withUnsafeBytes { src in
        out.withUnsafeMutableBytes { dst in
            AudioFormatGetProperty(
                kAudioFormatProperty_FormatInfo,
                40,
                src.baseAddress,
                &size,
                dst.baseAddress
            )
        }
    }
    atDepthExpect(status == 0, "format info")
    atDepthExpect(size == 40, "size")
    var vbrSize: UInt32 = 4
    var vbr: UInt32 = 99
    blob.withUnsafeBytes { src in
        _ = AudioFormatGetProperty(
            kAudioFormatProperty_FormatIsVBR,
            40,
            src.baseAddress,
            &vbrSize,
            &vbr
        )
    }
    atDepthExpect(vbr == 0, "pcm is not vbr")
}

func testAudioConverterPCMRoundTrip() {
    let source = atPCMBlob(bits: 16, flags: 12)
    let dest = atPCMBlob(bits: 32, flags: 9) // float packed
    var converter: AudioConverterRef?
    let created = source.withUnsafeBytes { s in
        dest.withUnsafeBytes { d in
            AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
        }
    }
    atDepthExpect(created == 0, "converter new")
    atDepthExpect(AudioConverterReset(converter) == 0, "reset")
    var map: [Int32] = [0]
    atDepthExpect(
        AudioConverterSetProperty(converter, kAudioConverterChannelMap, 4, &map) == 0,
        "channel map"
    )
    var infoSize: UInt32 = 0
    var writable: UInt8 = 0
    atDepthExpect(
        AudioConverterGetPropertyInfo(converter, kAudioConverterChannelMap, &infoSize, &writable) == 0,
        "prop info"
    )
    let samples: [Int16] = [0, 16384, -16384, 32767]
    var output = [Float32](repeating: 0, count: 4)
    var outSize = UInt32(MemoryLayout<Float32>.size * 4)
    let status = samples.withUnsafeBytes { inRaw in
        output.withUnsafeMutableBytes { outRaw in
            AudioConverterConvertBuffer(
                converter,
                UInt32(inRaw.count),
                inRaw.baseAddress,
                &outSize,
                outRaw.baseAddress
            )
        }
    }
    atDepthExpect(status == 0, "convert")
    atDepthExpect(abs(output[0]) < 0.001, "zero")
    atDepthExpect(output[1] > 0.4 && output[1] < 0.6, "half")
    atDepthExpect(AudioConverterDispose(converter) == 0, "dispose")
}

func testAudioConverterCompressedFailClosed() {
    var source = atPCMBlob()
    source.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(0x6161_6330), toByteOffset: 8, as: UInt32.self) // 'aac0'
    }
    let dest = atPCMBlob()
    var converter: AudioConverterRef?
    let status = source.withUnsafeBytes { s in
        dest.withUnsafeBytes { d in
            AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
        }
    }
    atDepthExpect(status == kAudioConverterErr_FormatNotSupported, "compressed fail-closed")
    atDepthExpect(converter == nil, "no converter")
}

func testAudioQueueOfflineCallbackCadence() {
    let format = atPCMBlob(channels: 1)
    final class Box: @unchecked Sendable {
        var count = 0
    }
    let box = Box()
    let callback: AudioQueueOutputCallback = { user, _, _ in
        if let user {
            Unmanaged<Box>.fromOpaque(user).takeUnretainedValue().count += 1
        }
    }
    var queue: AudioQueueRef?
    let user = Unmanaged.passUnretained(box).toOpaque()
    atDepthExpect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, callback, user, nil, nil, 0, &queue)
        } == 0,
        "new output"
    )
    var buffer: AudioQueueBufferRef?
    atDepthExpect(AudioQueueAllocateBuffer(queue, 64, &buffer) == 0, "alloc")
    buffer!.pointee.mAudioDataByteSize = 64
    atDepthExpect(AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == 0, "enqueue")
    atDepthExpect(AudioQueueStart(queue, nil) == 0, "start")
    atDepthExpect(box.count == 1, "callback once")
    var running: UInt32 = 0
    var size: UInt32 = 4
    atDepthExpect(AudioQueueGetProperty(queue, kAudioQueueProperty_IsRunning, &running, &size) == 0, "running")
    atDepthExpect(running == 1, "is running")
    var propSize: UInt32 = 0
    atDepthExpect(AudioQueueGetPropertySize(queue, kAudioQueueProperty_IsRunning, &propSize) == 0, "size")
    atDepthExpect(AudioQueueStop(queue, true) == 0, "stop")
    atDepthExpect(AudioQueueDispose(queue, true) == 0, "dispose")
}

func testAudioQueueInvalidFormat() {
    var blob = atPCMBlob()
    blob.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(0x6161_6331), toByteOffset: 8, as: UInt32.self)
    }
    var queue: AudioQueueRef?
    let status = blob.withUnsafeBytes { raw in
        AudioQueueNewOutput(raw.baseAddress, nil, nil, nil, nil, 0, &queue)
    }
    atDepthExpect(status == kAudioQueueErr_CodecNotFound, "codec")
}

func testAudioComponentBuiltInsAndUnits() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_GenericOutput,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    atDepthExpect(component != nil, "generic output")
    var instance: AudioComponentInstance?
    atDepthExpect(AudioComponentInstanceNew(component, &instance) == 0, "instantiate")
    atDepthExpect(AudioUnitInitialize(instance) == 0, "init")
    var list = [UInt8](repeating: 0, count: 24)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(256), toByteOffset: 12, as: UInt32.self)
        var storage = [Int16](repeating: 99, count: 128)
        storage.withUnsafeMutableBytes { samples in
            raw.baseAddress!.storeBytes(
                of: UInt(bitPattern: samples.baseAddress),
                toByteOffset: 16,
                as: UInt.self
            )
            var flags = AudioUnitRenderActionFlags()
            let status = AudioUnitRender(instance, &flags, nil, 0, 8, raw.baseAddress)
            atDepthExpect(status == 0, "render generic")
            atDepthExpect(flags.contains(.unitRenderAction_OutputIsSilence), "silence flag")
        }
    }
    atDepthExpect(AudioComponentInstanceDispose(instance) == 0, "dispose")

    var remote = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_RemoteIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let remoteComp = AudioComponentFindNext(nil, &remote)
    var remoteInst: AudioComponentInstance?
    atDepthExpect(AudioComponentInstanceNew(remoteComp, &remoteInst) == 0, "remote exists")
    atDepthExpect(AudioUnitInitialize(remoteInst) == kAudioUnitErr_FailedInitialization, "remote fail-closed")
    _ = AudioComponentInstanceDispose(remoteInst)
}

func testAudioUnitMixerOffline() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var mixer: AudioComponentInstance?
    atDepthExpect(AudioComponentInstanceNew(component, &mixer) == 0, "mixer")
    atDepthExpect(AudioUnitInitialize(mixer) == 0, "init mixer")
    var count: UInt32 = 0
    var size: UInt32 = 4
    atDepthExpect(
        AudioUnitGetProperty(mixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &count, &size) == 0,
        "element count"
    )
    atDepthExpect(count == 2, "two inputs")
    atDepthExpect(AudioUnitSetParameter(mixer, 0, kAudioUnitScope_Input, 0, 0.5, 0) == 0, "set param")
    var value: AudioUnitParameterValue = 0
    atDepthExpect(AudioUnitGetParameter(mixer, 0, kAudioUnitScope_Input, 0, &value) == 0, "get param")
    atDepthExpect(value == 0.5, "param stored")
    _ = AudioComponentInstanceDispose(mixer)
}

func testAudioFileWAVRoundTrip() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atPCMBlob(channels: 1)
    var file: AudioFileID?
    atDepthExpect(
        format.withUnsafeBytes { raw in
            AudioFileCreateWithURL(
                atDepthFileURL(path.path),
                kAudioFileWAVEType,
                raw.baseAddress,
                [],
                &file
            )
        } == 0,
        "create wav"
    )
    var packets: UInt32 = 4
    let samples: [Int16] = [0, 1, -1, 2]
    atDepthExpect(
        samples.withUnsafeBytes { raw in
            AudioFileWritePackets(file, false, 8, nil, 0, &packets, raw.baseAddress)
        } == 0,
        "write"
    )
    atDepthExpect(AudioFileClose(file) == 0, "close")
    var opened: AudioFileID?
    atDepthExpect(
        AudioFileOpenURL(atDepthFileURL(path.path), .readPermission, kAudioFileWAVEType, &opened) == 0,
        "reopen"
    )
    var propSize: UInt32 = 4
    var fileType: UInt32 = 0
    atDepthExpect(
        AudioFileGetProperty(opened, kAudioFilePropertyFileFormat, &propSize, &fileType) == 0,
        "file format"
    )
    atDepthExpect(fileType == kAudioFileWAVEType, "wave")
    var readPackets: UInt32 = 4
    var readBytes: UInt32 = 0
    var out = [Int16](repeating: 0, count: 4)
    atDepthExpect(
        out.withUnsafeMutableBytes { raw in
            AudioFileReadPackets(opened, false, &readBytes, nil, 0, &readPackets, raw.baseAddress)
        } == 0,
        "read"
    )
    atDepthExpect(out == samples, "round trip")
    atDepthExpect(AudioFileClose(opened) == 0, "close2")
#endif
}

func testExtAudioFileClientFormat() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atPCMBlob(channels: 1)
    var file: AudioFileID?
    format.withUnsafeBytes { raw in
        _ = AudioFileCreateWithURL(atDepthFileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
    }
    var packets: UInt32 = 8
    let samples: [Int16] = [0, 100, 200, 300, 400, 500, 600, 700]
    samples.withUnsafeBytes { raw in
        _ = AudioFileWritePackets(file, false, 16, nil, 0, &packets, raw.baseAddress)
    }
    _ = AudioFileClose(file)
    var ext: ExtAudioFileRef?
    atDepthExpect(ExtAudioFileOpenURL(atDepthFileURL(path.path), &ext) == 0, "ext open")
    let floatFormat = atPCMBlob(channels: 1, bits: 32, flags: 9)
    atDepthExpect(
        floatFormat.withUnsafeBytes { raw in
            ExtAudioFileSetProperty(
                ext,
                kExtAudioFileProperty_ClientDataFormat,
                40,
                raw.baseAddress
            )
        } == 0,
        "client format"
    )
    var frames: UInt32 = 8
    var list = [UInt8](repeating: 0, count: 24)
    var floats = [Float32](repeating: 0, count: 8)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(32), toByteOffset: 12, as: UInt32.self)
        floats.withUnsafeMutableBytes { samplesRaw in
            raw.baseAddress!.storeBytes(
                of: UInt(bitPattern: samplesRaw.baseAddress),
                toByteOffset: 16,
                as: UInt.self
            )
            atDepthExpect(ExtAudioFileRead(ext, &frames, raw.baseAddress) == 0, "ext read")
        }
    }
    atDepthExpect(frames == 8, "frames")
    atDepthExpect(floats[1] > 0, "converted")
    atDepthExpect(ExtAudioFileDispose(ext) == 0, "dispose")
#endif
}

func testMusicSequenceSMFParseAndPlayerTime() {
#if canImport(CoreFoundation)
    // Minimal type-0 SMF: tempo 120 and one note-on.
    let smf: [UInt8] = [
        0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x60,
        0x4D, 0x54, 0x72, 0x6B, 0x00, 0x00, 0x00, 0x11,
        0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,
        0x00, 0x90, 0x3C, 0x40,
        0x60, 0x80, 0x3C, 0x00,
        0x00, 0xFF, 0x2F, 0x00,
    ]
    var sequence: MusicSequence?
    atDepthExpect(NewMusicSequence(&sequence) == 0, "seq")
    let data = smf.withUnsafeBufferPointer { buffer in
        CFDataCreate(kCFAllocatorDefault, buffer.baseAddress, buffer.count)!
    }
    atDepthExpect(MusicSequenceFileLoadData(sequence, data, .midiType, []) == 0, "load smf")
    var count: UInt32 = 0
    atDepthExpect(MusicSequenceGetTrackCount(sequence, &count) == 0, "count")
    var player: MusicPlayer?
    atDepthExpect(NewMusicPlayer(&player) == 0, "player")
    atDepthExpect(MusicPlayerSetSequence(player, sequence) == 0, "attach")
    atDepthExpect(MusicPlayerStart(player) == 0, "start")
    var playing: UInt8 = 0
    atDepthExpect(MusicPlayerIsPlaying(player, &playing) == 0 && playing == 1, "playing")
    usleep(20_000)
    var time: MusicTimeStamp = 0
    atDepthExpect(MusicPlayerGetTime(player, &time) == 0, "time")
    atDepthExpect(time > 0, "time advanced")
    atDepthExpect(MusicPlayerStop(player) == 0, "stop")
    atDepthExpect(DisposeMusicPlayer(player) == 0, "dispose player")
    atDepthExpect(DisposeMusicSequence(sequence) == 0, "dispose seq")
#endif
}

func testAudioServicesCreateValidWAV() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-sound-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atPCMBlob(channels: 1)
    var file: AudioFileID?
    format.withUnsafeBytes { raw in
        _ = AudioFileCreateWithURL(atDepthFileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
    }
    var packets: UInt32 = 1
    var sample: Int16 = 0
    _ = AudioFileWritePackets(file, false, 2, nil, 0, &packets, &sample)
    _ = AudioFileClose(file)
    var sound: SystemSoundID = 0
    atDepthExpect(
        AudioServicesCreateSystemSoundID(atDepthFileURL(path.path), &sound) == kAudioServicesNoError,
        "create sound"
    )
    atDepthExpect(sound != 0, "id assigned")
    atDepthExpect(AudioServicesDisposeSystemSoundID(sound) == 0, "dispose")
#endif
}

func testAudioToolboxConstantCatalog() {
    atDepthExpect(AUEventSampleTimeImmediate == -1, "AUEventSampleTimeImmediate")
    atDepthExpect(kAUGraphErr_CannotDoInCurrentContext == -10863, "kAUGraphErr_CannotDoInCurrentContext")
    atDepthExpect(kAUGraphErr_InvalidAudioUnit == -10864, "kAUGraphErr_InvalidAudioUnit")
    atDepthExpect(kAUGraphErr_InvalidConnection == -10861, "kAUGraphErr_InvalidConnection")
    atDepthExpect(kAUGraphErr_NodeNotFound == -10860, "kAUGraphErr_NodeNotFound")
    atDepthExpect(kAUGraphErr_OutputNodeErr == -10862, "kAUGraphErr_OutputNodeErr")
    atDepthExpect(kAudioComponentErr_DuplicateDescription == -66752, "kAudioComponentErr_DuplicateDescription")
    atDepthExpect(kAudioComponentErr_InitializationTimedOut == -66747, "kAudioComponentErr_InitializationTimedOut")
    atDepthExpect(kAudioComponentErr_InstanceInvalidated == -66749, "kAudioComponentErr_InstanceInvalidated")
    atDepthExpect(kAudioComponentErr_InstanceTimedOut == -66754, "kAudioComponentErr_InstanceTimedOut")
    atDepthExpect(kAudioComponentErr_InvalidFormat == -66746, "kAudioComponentErr_InvalidFormat")
    atDepthExpect(kAudioComponentErr_NotPermitted == -66748, "kAudioComponentErr_NotPermitted")
    atDepthExpect(kAudioComponentErr_TooManyInstances == -66750, "kAudioComponentErr_TooManyInstances")
    atDepthExpect(kAudioComponentErr_UnsupportedType == -66751, "kAudioComponentErr_UnsupportedType")
    atDepthExpect(kAudioConverterApplicableEncodeBitRates == 1634034290, "kAudioConverterApplicableEncodeBitRates")
    atDepthExpect(kAudioConverterApplicableEncodeSampleRates == 1634038642, "kAudioConverterApplicableEncodeSampleRates")
    atDepthExpect(kAudioConverterAvailableEncodeBitRates == 1986355826, "kAudioConverterAvailableEncodeBitRates")
    atDepthExpect(kAudioConverterAvailableEncodeChannelLayoutTags == 1634034540, "kAudioConverterAvailableEncodeChannelLayoutTags")
    atDepthExpect(kAudioConverterAvailableEncodeSampleRates == 1986360178, "kAudioConverterAvailableEncodeSampleRates")
    atDepthExpect(kAudioConverterChannelMap == 1667788144, "kAudioConverterChannelMap")
    atDepthExpect(kAudioConverterCodecQuality == 1667527029, "kAudioConverterCodecQuality")
    atDepthExpect(kAudioConverterCompressionMagicCookie == 1668114275, "kAudioConverterCompressionMagicCookie")
    atDepthExpect(kAudioConverterCurrentInputStreamDescription == 1633904996, "kAudioConverterCurrentInputStreamDescription")
    atDepthExpect(kAudioConverterCurrentOutputStreamDescription == 1633906532, "kAudioConverterCurrentOutputStreamDescription")
    atDepthExpect(kAudioConverterDecompressionMagicCookie == 1684891491, "kAudioConverterDecompressionMagicCookie")
    atDepthExpect(kAudioConverterEncodeAdjustableSampleRate == 1634366322, "kAudioConverterEncodeAdjustableSampleRate")
    atDepthExpect(kAudioConverterEncodeBitRate == 1651663220, "kAudioConverterEncodeBitRate")
    atDepthExpect(kAudioConverterErr_BadPropertySizeError == 561211770, "kAudioConverterErr_BadPropertySizeError")
    atDepthExpect(kAudioConverterErr_FormatNotSupported == 1718449215, "kAudioConverterErr_FormatNotSupported")
    atDepthExpect(kAudioConverterErr_HardwareInUse == 1752656245, "kAudioConverterErr_HardwareInUse")
    atDepthExpect(kAudioConverterErr_InputSampleRateOutOfRange == 560558962, "kAudioConverterErr_InputSampleRateOutOfRange")
    atDepthExpect(kAudioConverterErr_InvalidInputSize == 1768846202, "kAudioConverterErr_InvalidInputSize")
    atDepthExpect(kAudioConverterErr_InvalidOutputSize == 1869902714, "kAudioConverterErr_InvalidOutputSize")
    atDepthExpect(kAudioConverterErr_NoHardwarePermission == 1885696621, "kAudioConverterErr_NoHardwarePermission")
    atDepthExpect(kAudioConverterErr_OperationNotSupported == 1869627199, "kAudioConverterErr_OperationNotSupported")
    atDepthExpect(kAudioConverterErr_OutputSampleRateOutOfRange == 560952178, "kAudioConverterErr_OutputSampleRateOutOfRange")
    atDepthExpect(kAudioConverterErr_PropertyNotSupported == 1886547824, "kAudioConverterErr_PropertyNotSupported")
    atDepthExpect(kAudioConverterErr_RequiresPacketDescriptionsError == 561015652, "kAudioConverterErr_RequiresPacketDescriptionsError")
    atDepthExpect(kAudioConverterErr_UnspecifiedError == 2003329396, "kAudioConverterErr_UnspecifiedError")
    atDepthExpect(kAudioConverterInputChannelLayout == 1768123424, "kAudioConverterInputChannelLayout")
    atDepthExpect(kAudioConverterOutputChannelLayout == 1868786720, "kAudioConverterOutputChannelLayout")
    atDepthExpect(kAudioConverterPrimeInfo == 1886546285, "kAudioConverterPrimeInfo")
    atDepthExpect(kAudioConverterPrimeMethod == 1886547309, "kAudioConverterPrimeMethod")
    atDepthExpect(kAudioConverterPropertyBitDepthHint == 1633903204, "kAudioConverterPropertyBitDepthHint")
    atDepthExpect(kAudioConverterPropertyCalculateInputBufferSize == 1667850867, "kAudioConverterPropertyCalculateInputBufferSize")
    atDepthExpect(kAudioConverterPropertyCalculateOutputBufferSize == 1668244083, "kAudioConverterPropertyCalculateOutputBufferSize")
    atDepthExpect(kAudioConverterPropertyCanResumeFromInterruption == 1668441705, "kAudioConverterPropertyCanResumeFromInterruption")
    atDepthExpect(kAudioConverterPropertyChannelMixMap == 1835884912, "kAudioConverterPropertyChannelMixMap")
    atDepthExpect(kAudioConverterPropertyFormatList == 1718383476, "kAudioConverterPropertyFormatList")
    atDepthExpect(kAudioConverterPropertyInputCodecParameters == 1768121456, "kAudioConverterPropertyInputCodecParameters")
    atDepthExpect(kAudioConverterPropertyMaximumInputBufferSize == 2020172403, "kAudioConverterPropertyMaximumInputBufferSize")
    atDepthExpect(kAudioConverterPropertyMaximumInputPacketSize == 2020175987, "kAudioConverterPropertyMaximumInputPacketSize")
    atDepthExpect(kAudioConverterPropertyMaximumOutputPacketSize == 2020569203, "kAudioConverterPropertyMaximumOutputPacketSize")
    atDepthExpect(kAudioConverterPropertyMinimumInputBufferSize == 1835623027, "kAudioConverterPropertyMinimumInputBufferSize")
    atDepthExpect(kAudioConverterPropertyMinimumOutputBufferSize == 1836016243, "kAudioConverterPropertyMinimumOutputBufferSize")
    atDepthExpect(kAudioConverterPropertyOutputCodecParameters == 1868784752, "kAudioConverterPropertyOutputCodecParameters")
    atDepthExpect(kAudioConverterPropertyPerformDownmix == 1684892024, "kAudioConverterPropertyPerformDownmix")
    atDepthExpect(kAudioConverterPropertySettings == 1633906803, "kAudioConverterPropertySettings")
    atDepthExpect(kAudioConverterQuality_High == 96, "kAudioConverterQuality_High")
    atDepthExpect(kAudioConverterQuality_Low == 32, "kAudioConverterQuality_Low")
    atDepthExpect(kAudioConverterQuality_Max == 127, "kAudioConverterQuality_Max")
    atDepthExpect(kAudioConverterQuality_Medium == 64, "kAudioConverterQuality_Medium")
    atDepthExpect(kAudioConverterQuality_Min == 0, "kAudioConverterQuality_Min")
    atDepthExpect(kAudioConverterSampleRateConverterAlgorithm == 1936876393, "kAudioConverterSampleRateConverterAlgorithm")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity == 1936876385, "kAudioConverterSampleRateConverterComplexity")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity_Linear == 1818848869, "kAudioConverterSampleRateConverterComplexity_Linear")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity_Mastering == 1650553971, "kAudioConverterSampleRateConverterComplexity_Mastering")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity_MinimumPhase == 1835626096, "kAudioConverterSampleRateConverterComplexity_MinimumPhase")
    atDepthExpect(kAudioConverterSampleRateConverterComplexity_Normal == 1852797549, "kAudioConverterSampleRateConverterComplexity_Normal")
    atDepthExpect(kAudioConverterSampleRateConverterInitialPhase == 1936876400, "kAudioConverterSampleRateConverterInitialPhase")
    atDepthExpect(kAudioConverterSampleRateConverterQuality == 1936876401, "kAudioConverterSampleRateConverterQuality")
    atDepthExpect(kAudioFile3GP2Type == 862416946, "kAudioFile3GP2Type")
    atDepthExpect(kAudioFile3GPType == 862417008, "kAudioFile3GPType")
    atDepthExpect(kAudioFileAAC_ADTSType == 1633973363, "kAudioFileAAC_ADTSType")
    atDepthExpect(kAudioFileAC3Type == 1633889587, "kAudioFileAC3Type")
    atDepthExpect(kAudioFileAIFCType == 1095321155, "kAudioFileAIFCType")
    atDepthExpect(kAudioFileAIFFType == 1095321158, "kAudioFileAIFFType")
    atDepthExpect(kAudioFileAMRType == 1634562662, "kAudioFileAMRType")
    atDepthExpect(kAudioFileBW64Type == 1113011764, "kAudioFileBW64Type")
    atDepthExpect(kAudioFileBadPropertySizeError == 561211770, "kAudioFileBadPropertySizeError")
    atDepthExpect(kAudioFileCAFType == 1667327590, "kAudioFileCAFType")
    atDepthExpect(kAudioFileDoesNotAllow64BitDataSizeError == 1868981823, "kAudioFileDoesNotAllow64BitDataSizeError")
    atDepthExpect(kAudioFileEndOfFileError == -39, "kAudioFileEndOfFileError")
    atDepthExpect(kAudioFileFLACType == 1718378851, "kAudioFileFLACType")
    atDepthExpect(kAudioFileFileNotFoundError == -43, "kAudioFileFileNotFoundError")
    atDepthExpect(kAudioFileInvalidChunkError == 1667787583, "kAudioFileInvalidChunkError")
    atDepthExpect(kAudioFileInvalidFileError == 1685348671, "kAudioFileInvalidFileError")
    atDepthExpect(kAudioFileInvalidPacketOffsetError == 1885563711, "kAudioFileInvalidPacketOffsetError")
    atDepthExpect(kAudioFileLATMInLOASType == 1819238771, "kAudioFileLATMInLOASType")
    atDepthExpect(kAudioFileM4AType == 1832149350, "kAudioFileM4AType")
    atDepthExpect(kAudioFileM4BType == 1832149606, "kAudioFileM4BType")
    atDepthExpect(kAudioFileMP1Type == 1297106737, "kAudioFileMP1Type")
    atDepthExpect(kAudioFileMP2Type == 1297106738, "kAudioFileMP2Type")
    atDepthExpect(kAudioFileMP3Type == 1297106739, "kAudioFileMP3Type")
    atDepthExpect(kAudioFileMPEG4Type == 1836069990, "kAudioFileMPEG4Type")
    atDepthExpect(kAudioFileNextType == 1315264596, "kAudioFileNextType")
    atDepthExpect(kAudioFileNotOpenError == -38, "kAudioFileNotOpenError")
    atDepthExpect(kAudioFileNotOptimizedError == 1869640813, "kAudioFileNotOptimizedError")
    atDepthExpect(kAudioFileOperationNotSupportedError == 1869627199, "kAudioFileOperationNotSupportedError")
    atDepthExpect(kAudioFilePermissionsError == 1886547263, "kAudioFilePermissionsError")
    atDepthExpect(kAudioFilePositionError == -40, "kAudioFilePositionError")
    atDepthExpect(kAudioFilePropertyAlbumArtwork == 1633776244, "kAudioFilePropertyAlbumArtwork")
    atDepthExpect(kAudioFilePropertyAudioDataByteCount == 1650683508, "kAudioFilePropertyAudioDataByteCount")
    atDepthExpect(kAudioFilePropertyAudioDataPacketCount == 1885564532, "kAudioFilePropertyAudioDataPacketCount")
    atDepthExpect(kAudioFilePropertyAudioTrackCount == 1635017588, "kAudioFilePropertyAudioTrackCount")
    atDepthExpect(kAudioFilePropertyBitRate == 1651663220, "kAudioFilePropertyBitRate")
    atDepthExpect(kAudioFilePropertyByteToPacket == 1652125803, "kAudioFilePropertyByteToPacket")
    atDepthExpect(kAudioFilePropertyChannelLayout == 1668112752, "kAudioFilePropertyChannelLayout")
    atDepthExpect(kAudioFilePropertyChunkIDs == 1667787108, "kAudioFilePropertyChunkIDs")
    atDepthExpect(kAudioFilePropertyDataFormat == 1684434292, "kAudioFilePropertyDataFormat")
    atDepthExpect(kAudioFilePropertyDataFormatName == 1718512997, "kAudioFilePropertyDataFormatName")
    atDepthExpect(kAudioFilePropertyDataOffset == 1685022310, "kAudioFilePropertyDataOffset")
    atDepthExpect(kAudioFilePropertyDeferSizeUpdates == 1685289589, "kAudioFilePropertyDeferSizeUpdates")
    atDepthExpect(kAudioFilePropertyEstimatedDuration == 1701082482, "kAudioFilePropertyEstimatedDuration")
    atDepthExpect(kAudioFilePropertyFileFormat == 1717988724, "kAudioFilePropertyFileFormat")
    atDepthExpect(kAudioFilePropertyFormatList == 1718383476, "kAudioFilePropertyFormatList")
    atDepthExpect(kAudioFilePropertyFrameToPacket == 1718775915, "kAudioFilePropertyFrameToPacket")
    atDepthExpect(kAudioFilePropertyID3Tag == 1768174452, "kAudioFilePropertyID3Tag")
    atDepthExpect(kAudioFilePropertyID3TagOffset == 1768174447, "kAudioFilePropertyID3TagOffset")
    atDepthExpect(kAudioFilePropertyInfoDictionary == 1768842863, "kAudioFilePropertyInfoDictionary")
    atDepthExpect(kAudioFilePropertyIsOptimized == 1869640813, "kAudioFilePropertyIsOptimized")
    atDepthExpect(kAudioFilePropertyMagicCookieData == 1835493731, "kAudioFilePropertyMagicCookieData")
    atDepthExpect(kAudioFilePropertyMarkerList == 1835756659, "kAudioFilePropertyMarkerList")
    atDepthExpect(kAudioFilePropertyMaximumPacketSize == 1886616165, "kAudioFilePropertyMaximumPacketSize")
    atDepthExpect(kAudioFilePropertyNextIndependentPacket == 1852403300, "kAudioFilePropertyNextIndependentPacket")
    atDepthExpect(kAudioFilePropertyPacketRangeByteCountUpperBound == 1886549346, "kAudioFilePropertyPacketRangeByteCountUpperBound")
    atDepthExpect(kAudioFilePropertyPacketSizeUpperBound == 1886090594, "kAudioFilePropertyPacketSizeUpperBound")
    atDepthExpect(kAudioFilePropertyPacketTableInfo == 1886283375, "kAudioFilePropertyPacketTableInfo")
    atDepthExpect(kAudioFilePropertyPacketToByte == 1886085753, "kAudioFilePropertyPacketToByte")
    atDepthExpect(kAudioFilePropertyPacketToDependencyInfo == 1885627760, "kAudioFilePropertyPacketToDependencyInfo")
    atDepthExpect(kAudioFilePropertyPacketToFrame == 1886086770, "kAudioFilePropertyPacketToFrame")
    atDepthExpect(kAudioFilePropertyPacketToRollDistance == 1886547052, "kAudioFilePropertyPacketToRollDistance")
    atDepthExpect(kAudioFilePropertyPreviousIndependentPacket == 1885957732, "kAudioFilePropertyPreviousIndependentPacket")
    atDepthExpect(kAudioFilePropertyRegionList == 1919380595, "kAudioFilePropertyRegionList")
    atDepthExpect(kAudioFilePropertyReserveDuration == 1920168566, "kAudioFilePropertyReserveDuration")
    atDepthExpect(kAudioFilePropertyRestrictsRandomAccess == 1920098670, "kAudioFilePropertyRestrictsRandomAccess")
    atDepthExpect(kAudioFilePropertySourceBitDepth == 1935832164, "kAudioFilePropertySourceBitDepth")
    atDepthExpect(kAudioFilePropertyUseAudioTrack == 1969321067, "kAudioFilePropertyUseAudioTrack")
    atDepthExpect(kAudioFileRF64Type == 1380333108, "kAudioFileRF64Type")
    atDepthExpect(kAudioFileSoundDesigner2Type == 1399075430, "kAudioFileSoundDesigner2Type")
    atDepthExpect(kAudioFileUnspecifiedError == 2003334207, "kAudioFileUnspecifiedError")
    atDepthExpect(kAudioFileUnsupportedDataFormatError == 1718449215, "kAudioFileUnsupportedDataFormatError")
    atDepthExpect(kAudioFileUnsupportedFileTypeError == 1954115647, "kAudioFileUnsupportedFileTypeError")
    atDepthExpect(kAudioFileUnsupportedPropertyError == 1886681407, "kAudioFileUnsupportedPropertyError")
    atDepthExpect(kAudioFileWAVEType == 1463899717, "kAudioFileWAVEType")
    atDepthExpect(kAudioFileWave64Type == 1463170150, "kAudioFileWave64Type")
    atDepthExpect(kAudioFormatBadPropertySizeError == 561211770, "kAudioFormatBadPropertySizeError")
    atDepthExpect(kAudioFormatBadSpecifierSizeError == 561213539, "kAudioFormatBadSpecifierSizeError")
    atDepthExpect(kAudioFormatProperty_ASBDFromESDS == 1702064996, "kAudioFormatProperty_ASBDFromESDS")
    atDepthExpect(kAudioFormatProperty_ASBDFromMPEGPacket == 1633971568, "kAudioFormatProperty_ASBDFromMPEGPacket")
    atDepthExpect(kAudioFormatProperty_AreChannelLayoutsEquivalent == 1667786097, "kAudioFormatProperty_AreChannelLayoutsEquivalent")
    atDepthExpect(kAudioFormatProperty_AvailableDecodeNumberChannels == 1986293347, "kAudioFormatProperty_AvailableDecodeNumberChannels")
    atDepthExpect(kAudioFormatProperty_AvailableEncodeBitRates == 1634034290, "kAudioFormatProperty_AvailableEncodeBitRates")
    atDepthExpect(kAudioFormatProperty_AvailableEncodeChannelLayoutTags == 1634034540, "kAudioFormatProperty_AvailableEncodeChannelLayoutTags")
    atDepthExpect(kAudioFormatProperty_AvailableEncodeNumberChannels == 1635151459, "kAudioFormatProperty_AvailableEncodeNumberChannels")
    atDepthExpect(kAudioFormatProperty_AvailableEncodeSampleRates == 1634038642, "kAudioFormatProperty_AvailableEncodeSampleRates")
    atDepthExpect(kAudioFormatProperty_BalanceFade == 1650551910, "kAudioFormatProperty_BalanceFade")
    atDepthExpect(kAudioFormatProperty_BitmapForLayoutTag == 1651340391, "kAudioFormatProperty_BitmapForLayoutTag")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutForBitmap == 1668116578, "kAudioFormatProperty_ChannelLayoutForBitmap")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutForTag == 1668116588, "kAudioFormatProperty_ChannelLayoutForTag")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutFromESDS == 1702060908, "kAudioFormatProperty_ChannelLayoutFromESDS")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutHash == 1667786849, "kAudioFormatProperty_ChannelLayoutHash")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutName == 1819242093, "kAudioFormatProperty_ChannelLayoutName")
    atDepthExpect(kAudioFormatProperty_ChannelLayoutSimpleName == 1819504237, "kAudioFormatProperty_ChannelLayoutSimpleName")
    atDepthExpect(kAudioFormatProperty_ChannelMap == 1667788144, "kAudioFormatProperty_ChannelMap")
    atDepthExpect(kAudioFormatProperty_ChannelName == 1668178285, "kAudioFormatProperty_ChannelName")
    atDepthExpect(kAudioFormatProperty_ChannelShortName == 1668509293, "kAudioFormatProperty_ChannelShortName")
    atDepthExpect(kAudioFormatProperty_DecodeFormatIDs == 1633904998, "kAudioFormatProperty_DecodeFormatIDs")
    atDepthExpect(kAudioFormatProperty_Decoders == 1635148901, "kAudioFormatProperty_Decoders")
    atDepthExpect(kAudioFormatProperty_EncodeFormatIDs == 1633906534, "kAudioFormatProperty_EncodeFormatIDs")
    atDepthExpect(kAudioFormatProperty_Encoders == 1635149166, "kAudioFormatProperty_Encoders")
    atDepthExpect(kAudioFormatProperty_FirstPlayableFormatFromList == 1718642284, "kAudioFormatProperty_FirstPlayableFormatFromList")
    atDepthExpect(kAudioFormatProperty_FormatEmploysDependentPackets == 1717855600, "kAudioFormatProperty_FormatEmploysDependentPackets")
    atDepthExpect(kAudioFormatProperty_FormatInfo == 1718449257, "kAudioFormatProperty_FormatInfo")
    atDepthExpect(kAudioFormatProperty_FormatIsEncrypted == 1668446576, "kAudioFormatProperty_FormatIsEncrypted")
    atDepthExpect(kAudioFormatProperty_FormatIsExternallyFramed == 1717925990, "kAudioFormatProperty_FormatIsExternallyFramed")
    atDepthExpect(kAudioFormatProperty_FormatIsVBR == 1719034482, "kAudioFormatProperty_FormatIsVBR")
    atDepthExpect(kAudioFormatProperty_FormatList == 1718383476, "kAudioFormatProperty_FormatList")
    atDepthExpect(kAudioFormatProperty_FormatName == 1718509933, "kAudioFormatProperty_FormatName")
    atDepthExpect(kAudioFormatProperty_HardwareCodecCapabilities == 1752654691, "kAudioFormatProperty_HardwareCodecCapabilities")
    atDepthExpect(kAudioFormatProperty_ID3TagSize == 1768174451, "kAudioFormatProperty_ID3TagSize")
    atDepthExpect(kAudioFormatProperty_ID3TagToDictionary == 1768174436, "kAudioFormatProperty_ID3TagToDictionary")
    atDepthExpect(kAudioFormatProperty_MatrixMixMap == 1835884912, "kAudioFormatProperty_MatrixMixMap")
    atDepthExpect(kAudioFormatProperty_NumberOfChannelsForLayout == 1852008557, "kAudioFormatProperty_NumberOfChannelsForLayout")
    atDepthExpect(kAudioFormatProperty_OutputFormatList == 1868983411, "kAudioFormatProperty_OutputFormatList")
    atDepthExpect(kAudioFormatProperty_PanningMatrix == 1885433453, "kAudioFormatProperty_PanningMatrix")
    atDepthExpect(kAudioFormatProperty_TagForChannelLayout == 1668116596, "kAudioFormatProperty_TagForChannelLayout")
    atDepthExpect(kAudioFormatProperty_TagsForNumberOfChannels == 1952540515, "kAudioFormatProperty_TagsForNumberOfChannels")
    atDepthExpect(kAudioFormatProperty_ValidateChannelLayout == 1986093932, "kAudioFormatProperty_ValidateChannelLayout")
    atDepthExpect(kAudioFormatUnknownFormatError == 560226676, "kAudioFormatUnknownFormatError")
    atDepthExpect(kAudioFormatUnspecifiedError == 2003329396, "kAudioFormatUnspecifiedError")
    atDepthExpect(kAudioFormatUnsupportedDataFormatError == 1718449215, "kAudioFormatUnsupportedDataFormatError")
    atDepthExpect(kAudioFormatUnsupportedPropertyError == 1886547824, "kAudioFormatUnsupportedPropertyError")
    atDepthExpect(kAudioQueueDeviceProperty_NumberChannels == 1634821219, "kAudioQueueDeviceProperty_NumberChannels")
    atDepthExpect(kAudioQueueDeviceProperty_SampleRate == 1634825074, "kAudioQueueDeviceProperty_SampleRate")
    atDepthExpect(kAudioQueueErr_BufferEmpty == -66686, "kAudioQueueErr_BufferEmpty")
    atDepthExpect(kAudioQueueErr_BufferEnqueuedTwice == -66666, "kAudioQueueErr_BufferEnqueuedTwice")
    atDepthExpect(kAudioQueueErr_BufferInQueue == -66679, "kAudioQueueErr_BufferInQueue")
    atDepthExpect(kAudioQueueErr_CannotStart == -66681, "kAudioQueueErr_CannotStart")
    atDepthExpect(kAudioQueueErr_CannotStartYet == -66665, "kAudioQueueErr_CannotStartYet")
    atDepthExpect(kAudioQueueErr_CodecNotFound == -66673, "kAudioQueueErr_CodecNotFound")
    atDepthExpect(kAudioQueueErr_DisposalPending == -66685, "kAudioQueueErr_DisposalPending")
    atDepthExpect(kAudioQueueErr_EnqueueDuringReset == -66632, "kAudioQueueErr_EnqueueDuringReset")
    atDepthExpect(kAudioQueueErr_InvalidBuffer == -66687, "kAudioQueueErr_InvalidBuffer")
    atDepthExpect(kAudioQueueErr_InvalidCodecAccess == -66672, "kAudioQueueErr_InvalidCodecAccess")
    atDepthExpect(kAudioQueueErr_InvalidDevice == -66680, "kAudioQueueErr_InvalidDevice")
    atDepthExpect(kAudioQueueErr_InvalidOfflineMode == -66626, "kAudioQueueErr_InvalidOfflineMode")
    atDepthExpect(kAudioQueueErr_InvalidParameter == -66682, "kAudioQueueErr_InvalidParameter")
    atDepthExpect(kAudioQueueErr_InvalidProperty == -66684, "kAudioQueueErr_InvalidProperty")
    atDepthExpect(kAudioQueueErr_InvalidPropertySize == -66683, "kAudioQueueErr_InvalidPropertySize")
    atDepthExpect(kAudioQueueErr_InvalidPropertyValue == -66675, "kAudioQueueErr_InvalidPropertyValue")
    atDepthExpect(kAudioQueueErr_InvalidQueueType == -66677, "kAudioQueueErr_InvalidQueueType")
    atDepthExpect(kAudioQueueErr_InvalidRunState == -66678, "kAudioQueueErr_InvalidRunState")
    atDepthExpect(kAudioQueueErr_InvalidTapContext == -66669, "kAudioQueueErr_InvalidTapContext")
    atDepthExpect(kAudioQueueErr_InvalidTapType == -66667, "kAudioQueueErr_InvalidTapType")
    atDepthExpect(kAudioQueueErr_Permissions == -66676, "kAudioQueueErr_Permissions")
    atDepthExpect(kAudioQueueErr_PrimeTimedOut == -66674, "kAudioQueueErr_PrimeTimedOut")
    atDepthExpect(kAudioQueueErr_QueueInvalidated == -66671, "kAudioQueueErr_QueueInvalidated")
    atDepthExpect(kAudioQueueErr_RecordUnderrun == -66668, "kAudioQueueErr_RecordUnderrun")
    atDepthExpect(kAudioQueueErr_TooManyTaps == -66670, "kAudioQueueErr_TooManyTaps")
    atDepthExpect(kAudioQueueHardwareCodecPolicy_Default == 0, "kAudioQueueHardwareCodecPolicy_Default")
    atDepthExpect(kAudioQueueProperty_ChannelAssignments == 1634820961, "kAudioQueueProperty_ChannelAssignments")
    atDepthExpect(kAudioQueueProperty_ChannelLayout == 1634820972, "kAudioQueueProperty_ChannelLayout")
    atDepthExpect(kAudioQueueProperty_ConverterError == 1902343781, "kAudioQueueProperty_ConverterError")
    atDepthExpect(kAudioQueueProperty_CurrentDevice == 1634820964, "kAudioQueueProperty_CurrentDevice")
    atDepthExpect(kAudioQueueProperty_CurrentLevelMeter == 1634823542, "kAudioQueueProperty_CurrentLevelMeter")
    atDepthExpect(kAudioQueueProperty_CurrentLevelMeterDB == 1634823524, "kAudioQueueProperty_CurrentLevelMeterDB")
    atDepthExpect(kAudioQueueProperty_DecodeBufferSizeFrames == 1684234854, "kAudioQueueProperty_DecodeBufferSizeFrames")
    atDepthExpect(kAudioQueueProperty_EnableLevelMetering == 1634823525, "kAudioQueueProperty_EnableLevelMetering")
    atDepthExpect(kAudioQueueProperty_EnableTimePitch == 1902081136, "kAudioQueueProperty_EnableTimePitch")
    atDepthExpect(kAudioQueueProperty_HardwareCodecPolicy == 1634820976, "kAudioQueueProperty_HardwareCodecPolicy")
    atDepthExpect(kAudioQueueProperty_IsRunning == 1634824814, "kAudioQueueProperty_IsRunning")
    atDepthExpect(kAudioQueueProperty_MagicCookie == 1634823523, "kAudioQueueProperty_MagicCookie")
    atDepthExpect(kAudioQueueProperty_MaximumOutputPacketSize == 2020569203, "kAudioQueueProperty_MaximumOutputPacketSize")
    atDepthExpect(kAudioQueueProperty_StreamDescription == 1634821748, "kAudioQueueProperty_StreamDescription")
    atDepthExpect(kAudioQueueProperty_TimePitchAlgorithm == 1903456353, "kAudioQueueProperty_TimePitchAlgorithm")
    atDepthExpect(kAudioQueueProperty_TimePitchBypass == 1903456354, "kAudioQueueProperty_TimePitchBypass")
    atDepthExpect(kAudioQueueTimePitchAlgorithm_LowQualityZeroLatency == 1819376236, "kAudioQueueTimePitchAlgorithm_LowQualityZeroLatency")
    atDepthExpect(kAudioQueueTimePitchAlgorithm_Spectral == 1936745827, "kAudioQueueTimePitchAlgorithm_Spectral")
    atDepthExpect(kAudioQueueTimePitchAlgorithm_TimeDomain == 1953064047, "kAudioQueueTimePitchAlgorithm_TimeDomain")
    atDepthExpect(kAudioQueueTimePitchAlgorithm_Varispeed == 1987276900, "kAudioQueueTimePitchAlgorithm_Varispeed")
    atDepthExpect(kAudioServicesBadPropertySizeError == 561211770, "kAudioServicesBadPropertySizeError")
    atDepthExpect(kAudioServicesBadSpecifierSizeError == 561213539, "kAudioServicesBadSpecifierSizeError")
    atDepthExpect(kAudioServicesNoError == 0, "kAudioServicesNoError")
    atDepthExpect(kAudioServicesNoHardwareError == -1500, "kAudioServicesNoHardwareError")
    atDepthExpect(kAudioServicesPropertyCompletePlaybackIfAppDies == 1768318057, "kAudioServicesPropertyCompletePlaybackIfAppDies")
    atDepthExpect(kAudioServicesPropertyIsUISound == 1769174377, "kAudioServicesPropertyIsUISound")
    atDepthExpect(kAudioServicesSystemSoundClientTimedOutError == -1501, "kAudioServicesSystemSoundClientTimedOutError")
    atDepthExpect(kAudioServicesSystemSoundExceededMaximumDurationError == -1502, "kAudioServicesSystemSoundExceededMaximumDurationError")
    atDepthExpect(kAudioServicesSystemSoundUnspecifiedError == -1500, "kAudioServicesSystemSoundUnspecifiedError")
    atDepthExpect(kAudioServicesUnsupportedPropertyError == 1886681407, "kAudioServicesUnsupportedPropertyError")
    atDepthExpect(kAudioSessionAlreadyInitialized == 1768843636, "kAudioSessionAlreadyInitialized")
    atDepthExpect(kAudioSessionBadPropertySizeError == 561211770, "kAudioSessionBadPropertySizeError")
    atDepthExpect(kAudioSessionBeginInterruption == 1, "kAudioSessionBeginInterruption")
    atDepthExpect(kAudioSessionCategory_AmbientSound == 1634558569, "kAudioSessionCategory_AmbientSound")
    atDepthExpect(kAudioSessionCategory_AudioProcessing == 1886547811, "kAudioSessionCategory_AudioProcessing")
    atDepthExpect(kAudioSessionCategory_LiveAudio == 1818850917, "kAudioSessionCategory_LiveAudio")
    atDepthExpect(kAudioSessionCategory_MediaPlayback == 1835361385, "kAudioSessionCategory_MediaPlayback")
    atDepthExpect(kAudioSessionCategory_PlayAndRecord == 1886151026, "kAudioSessionCategory_PlayAndRecord")
    atDepthExpect(kAudioSessionCategory_RecordAudio == 1919247201, "kAudioSessionCategory_RecordAudio")
    atDepthExpect(kAudioSessionCategory_SoloAmbientSound == 1936682095, "kAudioSessionCategory_SoloAmbientSound")
    atDepthExpect(kAudioSessionCategory_UserInterfaceSoundEffects == 1969845093, "kAudioSessionCategory_UserInterfaceSoundEffects")
    atDepthExpect(kAudioSessionEndInterruption == 0, "kAudioSessionEndInterruption")
    atDepthExpect(kAudioSessionIncompatibleCategory == 560161140, "kAudioSessionIncompatibleCategory")
    atDepthExpect(kAudioSessionInitializationError == 1768843583, "kAudioSessionInitializationError")
    atDepthExpect(kAudioSessionInterruptionType_ShouldNotResume == 0, "kAudioSessionInterruptionType_ShouldNotResume")
    atDepthExpect(kAudioSessionInterruptionType_ShouldResume == 1, "kAudioSessionInterruptionType_ShouldResume")
    atDepthExpect(kAudioSessionMode_Default == 1684434036, "kAudioSessionMode_Default")
    atDepthExpect(kAudioSessionMode_GameChat == 1735222132, "kAudioSessionMode_GameChat")
    atDepthExpect(kAudioSessionMode_Measurement == 1836281204, "kAudioSessionMode_Measurement")
    atDepthExpect(kAudioSessionMode_VideoRecording == 1987208036, "kAudioSessionMode_VideoRecording")
    atDepthExpect(kAudioSessionMode_VoiceChat == 1986225012, "kAudioSessionMode_VoiceChat")
    atDepthExpect(kAudioSessionNoCategorySet == 1063477620, "kAudioSessionNoCategorySet")
    atDepthExpect(kAudioSessionNoError == 0, "kAudioSessionNoError")
    atDepthExpect(kAudioSessionNotActiveError == 560030580, "kAudioSessionNotActiveError")
    atDepthExpect(kAudioSessionNotInitialized == 561210739, "kAudioSessionNotInitialized")
    atDepthExpect(kAudioSessionOverrideAudioRoute_None == 0, "kAudioSessionOverrideAudioRoute_None")
    atDepthExpect(kAudioSessionOverrideAudioRoute_Speaker == 1936747378, "kAudioSessionOverrideAudioRoute_Speaker")
    atDepthExpect(kAudioSessionProperty_AudioCategory == 1633902964, "kAudioSessionProperty_AudioCategory")
    atDepthExpect(kAudioSessionProperty_AudioInputAvailable == 1634296182, "kAudioSessionProperty_AudioInputAvailable")
    atDepthExpect(kAudioSessionProperty_AudioRoute == 1919907188, "kAudioSessionProperty_AudioRoute")
    atDepthExpect(kAudioSessionProperty_AudioRouteChange == 1919902568, "kAudioSessionProperty_AudioRouteChange")
    atDepthExpect(kAudioSessionProperty_AudioRouteDescription == 1919182195, "kAudioSessionProperty_AudioRouteDescription")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareIOBufferDuration == 1667787106, "kAudioSessionProperty_CurrentHardwareIOBufferDuration")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareInputLatency == 1667787116, "kAudioSessionProperty_CurrentHardwareInputLatency")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareInputNumberChannels == 1667787107, "kAudioSessionProperty_CurrentHardwareInputNumberChannels")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareOutputLatency == 1667788652, "kAudioSessionProperty_CurrentHardwareOutputLatency")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareOutputNumberChannels == 1667788643, "kAudioSessionProperty_CurrentHardwareOutputNumberChannels")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareOutputVolume == 1667788662, "kAudioSessionProperty_CurrentHardwareOutputVolume")
    atDepthExpect(kAudioSessionProperty_CurrentHardwareSampleRate == 1667789682, "kAudioSessionProperty_CurrentHardwareSampleRate")
    atDepthExpect(kAudioSessionProperty_InputGainAvailable == 1768382838, "kAudioSessionProperty_InputGainAvailable")
    atDepthExpect(kAudioSessionProperty_InputGainScalar == 1768387427, "kAudioSessionProperty_InputGainScalar")
    atDepthExpect(kAudioSessionProperty_InputSource == 1769173603, "kAudioSessionProperty_InputSource")
    atDepthExpect(kAudioSessionProperty_InputSources == 1769173603, "kAudioSessionProperty_InputSources")
    atDepthExpect(kAudioSessionProperty_InterruptionType == 1954115685, "kAudioSessionProperty_InterruptionType")
    atDepthExpect(kAudioSessionProperty_Mode == 1836016741, "kAudioSessionProperty_Mode")
    atDepthExpect(kAudioSessionProperty_OtherAudioIsPlaying == 1869899890, "kAudioSessionProperty_OtherAudioIsPlaying")
    atDepthExpect(kAudioSessionProperty_OtherMixableAudioShouldDuck == 1685414763, "kAudioSessionProperty_OtherMixableAudioShouldDuck")
    atDepthExpect(kAudioSessionProperty_OutputDestination == 1868854132, "kAudioSessionProperty_OutputDestination")
    atDepthExpect(kAudioSessionProperty_OutputDestinations == 1868854132, "kAudioSessionProperty_OutputDestinations")
    atDepthExpect(kAudioSessionProperty_OverrideAudioRoute == 1870033508, "kAudioSessionProperty_OverrideAudioRoute")
    atDepthExpect(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker == 1668509803, "kAudioSessionProperty_OverrideCategoryDefaultToSpeaker")
    atDepthExpect(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput == 1667394676, "kAudioSessionProperty_OverrideCategoryEnableBluetoothInput")
    atDepthExpect(kAudioSessionProperty_OverrideCategoryMixWithOthers == 1668114808, "kAudioSessionProperty_OverrideCategoryMixWithOthers")
    atDepthExpect(kAudioSessionProperty_PreferredHardwareIOBufferDuration == 1885890914, "kAudioSessionProperty_PreferredHardwareIOBufferDuration")
    atDepthExpect(kAudioSessionProperty_PreferredHardwareSampleRate == 1885893490, "kAudioSessionProperty_PreferredHardwareSampleRate")
    atDepthExpect(kAudioSessionProperty_ServerDied == 1684628836, "kAudioSessionProperty_ServerDied")
    atDepthExpect(kAudioSessionRouteChangeReason_CategoryChange == 3, "kAudioSessionRouteChangeReason_CategoryChange")
    atDepthExpect(kAudioSessionRouteChangeReason_NewDeviceAvailable == 1, "kAudioSessionRouteChangeReason_NewDeviceAvailable")
    atDepthExpect(kAudioSessionRouteChangeReason_NoSuitableRouteForCategory == 7, "kAudioSessionRouteChangeReason_NoSuitableRouteForCategory")
    atDepthExpect(kAudioSessionRouteChangeReason_OldDeviceUnavailable == 2, "kAudioSessionRouteChangeReason_OldDeviceUnavailable")
    atDepthExpect(kAudioSessionRouteChangeReason_Override == 4, "kAudioSessionRouteChangeReason_Override")
    atDepthExpect(kAudioSessionRouteChangeReason_RouteConfigurationChange == 8, "kAudioSessionRouteChangeReason_RouteConfigurationChange")
    atDepthExpect(kAudioSessionRouteChangeReason_Unknown == 0, "kAudioSessionRouteChangeReason_Unknown")
    atDepthExpect(kAudioSessionRouteChangeReason_WakeFromSleep == 6, "kAudioSessionRouteChangeReason_WakeFromSleep")
    atDepthExpect(kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation == 1, "kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation")
    atDepthExpect(kAudioSessionUnspecifiedError == 2003329396, "kAudioSessionUnspecifiedError")
    atDepthExpect(kAudioSessionUnsupportedPropertyError == 1886681407, "kAudioSessionUnsupportedPropertyError")
    atDepthExpect(kAudioUnitErr_CannotDoInCurrentContext == -10863, "kAudioUnitErr_CannotDoInCurrentContext")
    atDepthExpect(kAudioUnitErr_ComponentManagerNotSupported == -66740, "kAudioUnitErr_ComponentManagerNotSupported")
    atDepthExpect(kAudioUnitErr_ExtensionNotFound == -66744, "kAudioUnitErr_ExtensionNotFound")
    atDepthExpect(kAudioUnitErr_FailedInitialization == -10875, "kAudioUnitErr_FailedInitialization")
    atDepthExpect(kAudioUnitErr_FileNotSpecified == -10869, "kAudioUnitErr_FileNotSpecified")
    atDepthExpect(kAudioUnitErr_FormatNotSupported == -10868, "kAudioUnitErr_FormatNotSupported")
    atDepthExpect(kAudioUnitErr_IllegalInstrument == -10873, "kAudioUnitErr_IllegalInstrument")
    atDepthExpect(kAudioUnitErr_Initialized == -10849, "kAudioUnitErr_Initialized")
    atDepthExpect(kAudioUnitErr_InstrumentTypeNotFound == -10872, "kAudioUnitErr_InstrumentTypeNotFound")
    atDepthExpect(kAudioUnitErr_InvalidElement == -10877, "kAudioUnitErr_InvalidElement")
    atDepthExpect(kAudioUnitErr_InvalidFile == -10871, "kAudioUnitErr_InvalidFile")
    atDepthExpect(kAudioUnitErr_InvalidFilePath == -66742, "kAudioUnitErr_InvalidFilePath")
    atDepthExpect(kAudioUnitErr_InvalidOfflineRender == -10848, "kAudioUnitErr_InvalidOfflineRender")
    atDepthExpect(kAudioUnitErr_InvalidParameter == -10878, "kAudioUnitErr_InvalidParameter")
    atDepthExpect(kAudioUnitErr_InvalidParameterValue == -66743, "kAudioUnitErr_InvalidParameterValue")
    atDepthExpect(kAudioUnitErr_InvalidProperty == -10879, "kAudioUnitErr_InvalidProperty")
    atDepthExpect(kAudioUnitErr_InvalidPropertyValue == -10851, "kAudioUnitErr_InvalidPropertyValue")
    atDepthExpect(kAudioUnitErr_InvalidScope == -10866, "kAudioUnitErr_InvalidScope")
    atDepthExpect(kAudioUnitErr_MIDIOutputBufferFull == -66753, "kAudioUnitErr_MIDIOutputBufferFull")
    atDepthExpect(kAudioUnitErr_MissingKey == -66741, "kAudioUnitErr_MissingKey")
    atDepthExpect(kAudioUnitErr_MultipleVoiceProcessors == -66635, "kAudioUnitErr_MultipleVoiceProcessors")
    atDepthExpect(kAudioUnitErr_NoConnection == -10876, "kAudioUnitErr_NoConnection")
    atDepthExpect(kAudioUnitErr_PropertyNotInUse == -10850, "kAudioUnitErr_PropertyNotInUse")
    atDepthExpect(kAudioUnitErr_PropertyNotWritable == -10865, "kAudioUnitErr_PropertyNotWritable")
    atDepthExpect(kAudioUnitErr_RenderTimeout == -66745, "kAudioUnitErr_RenderTimeout")
    atDepthExpect(kAudioUnitErr_TooManyFramesToProcess == -10874, "kAudioUnitErr_TooManyFramesToProcess")
    atDepthExpect(kAudioUnitErr_Unauthorized == -10847, "kAudioUnitErr_Unauthorized")
    atDepthExpect(kAudioUnitErr_Uninitialized == -10867, "kAudioUnitErr_Uninitialized")
    atDepthExpect(kAudioUnitErr_UnknownFileType == -10870, "kAudioUnitErr_UnknownFileType")
    atDepthExpect(kAudioUnitManufacturer_Apple == 1634758764, "kAudioUnitManufacturer_Apple")
    atDepthExpect(kAudioUnitProperty_3DMixerAttenuationCurve == 3013, "kAudioUnitProperty_3DMixerAttenuationCurve")
    atDepthExpect(kAudioUnitProperty_3DMixerDistanceAtten == 3004, "kAudioUnitProperty_3DMixerDistanceAtten")
    atDepthExpect(kAudioUnitProperty_3DMixerDistanceParams == 3010, "kAudioUnitProperty_3DMixerDistanceParams")
    atDepthExpect(kAudioUnitProperty_3DMixerRenderingFlags == 3003, "kAudioUnitProperty_3DMixerRenderingFlags")
    atDepthExpect(kAudioUnitProperty_AudioChannelLayout == 19, "kAudioUnitProperty_AudioChannelLayout")
    atDepthExpect(kAudioUnitProperty_AudioUnitMIDIProtocol == 64, "kAudioUnitProperty_AudioUnitMIDIProtocol")
    atDepthExpect(kAudioUnitProperty_BypassEffect == 21, "kAudioUnitProperty_BypassEffect")
    atDepthExpect(kAudioUnitProperty_CPULoad == 6, "kAudioUnitProperty_CPULoad")
    atDepthExpect(kAudioUnitProperty_ClassInfo == 0, "kAudioUnitProperty_ClassInfo")
    atDepthExpect(kAudioUnitProperty_ClassInfoFromDocument == 50, "kAudioUnitProperty_ClassInfoFromDocument")
    atDepthExpect(kAudioUnitProperty_ContextName == 25, "kAudioUnitProperty_ContextName")
    atDepthExpect(kAudioUnitProperty_CurrentPlayTime == 3302, "kAudioUnitProperty_CurrentPlayTime")
    atDepthExpect(kAudioUnitProperty_DeferredRendererExtraLatency == 3321, "kAudioUnitProperty_DeferredRendererExtraLatency")
    atDepthExpect(kAudioUnitProperty_DeferredRendererPullSize == 3320, "kAudioUnitProperty_DeferredRendererPullSize")
    atDepthExpect(kAudioUnitProperty_DeferredRendererWaitFrames == 3322, "kAudioUnitProperty_DeferredRendererWaitFrames")
    atDepthExpect(kAudioUnitProperty_DependentParameters == 45, "kAudioUnitProperty_DependentParameters")
    atDepthExpect(kAudioUnitProperty_DopplerShift == 3002, "kAudioUnitProperty_DopplerShift")
    atDepthExpect(kAudioUnitProperty_ElementCount == 11, "kAudioUnitProperty_ElementCount")
    atDepthExpect(kAudioUnitProperty_ElementName == 30, "kAudioUnitProperty_ElementName")
    atDepthExpect(kAudioUnitProperty_FactoryPresets == 24, "kAudioUnitProperty_FactoryPresets")
    atDepthExpect(kAudioUnitProperty_FrequencyResponse == 52, "kAudioUnitProperty_FrequencyResponse")
    atDepthExpect(kAudioUnitProperty_HostCallbacks == 27, "kAudioUnitProperty_HostCallbacks")
    atDepthExpect(kAudioUnitProperty_HostMIDIProtocol == 65, "kAudioUnitProperty_HostMIDIProtocol")
    atDepthExpect(kAudioUnitProperty_InPlaceProcessing == 29, "kAudioUnitProperty_InPlaceProcessing")
    atDepthExpect(kAudioUnitProperty_InputAnchorTimeStamp == 3016, "kAudioUnitProperty_InputAnchorTimeStamp")
    atDepthExpect(kAudioUnitProperty_InputSamplesInOutput == 49, "kAudioUnitProperty_InputSamplesInOutput")
    atDepthExpect(kAudioUnitProperty_IsInterAppConnected == 101, "kAudioUnitProperty_IsInterAppConnected")
    atDepthExpect(kAudioUnitProperty_LastRenderError == 22, "kAudioUnitProperty_LastRenderError")
    atDepthExpect(kAudioUnitProperty_LastRenderSampleTime == 61, "kAudioUnitProperty_LastRenderSampleTime")
    atDepthExpect(kAudioUnitProperty_Latency == 12, "kAudioUnitProperty_Latency")
    atDepthExpect(kAudioUnitProperty_LoadedOutOfProcess == 62, "kAudioUnitProperty_LoadedOutOfProcess")
    atDepthExpect(kAudioUnitProperty_MIDIOutputBufferSizeHint == 66, "kAudioUnitProperty_MIDIOutputBufferSizeHint")
    atDepthExpect(kAudioUnitProperty_MIDIOutputCallback == 48, "kAudioUnitProperty_MIDIOutputCallback")
    atDepthExpect(kAudioUnitProperty_MIDIOutputCallbackInfo == 47, "kAudioUnitProperty_MIDIOutputCallbackInfo")
    atDepthExpect(kAudioUnitProperty_MIDIOutputEventListCallback == 63, "kAudioUnitProperty_MIDIOutputEventListCallback")
    atDepthExpect(kAudioUnitProperty_MakeConnection == 1, "kAudioUnitProperty_MakeConnection")
    atDepthExpect(kAudioUnitProperty_MatrixDimensions == 3009, "kAudioUnitProperty_MatrixDimensions")
    atDepthExpect(kAudioUnitProperty_MatrixLevels == 3006, "kAudioUnitProperty_MatrixLevels")
    atDepthExpect(kAudioUnitProperty_MaximumFramesPerSlice == 14, "kAudioUnitProperty_MaximumFramesPerSlice")
    atDepthExpect(kAudioUnitProperty_MeterClipping == 3011, "kAudioUnitProperty_MeterClipping")
    atDepthExpect(kAudioUnitProperty_MeteringMode == 3007, "kAudioUnitProperty_MeteringMode")
    atDepthExpect(kAudioUnitProperty_NickName == 54, "kAudioUnitProperty_NickName")
    atDepthExpect(kAudioUnitProperty_OfflineRender == 37, "kAudioUnitProperty_OfflineRender")
    atDepthExpect(kAudioUnitProperty_ParameterClumpName == 35, "kAudioUnitProperty_ParameterClumpName")
    atDepthExpect(kAudioUnitProperty_ParameterHistoryInfo == 53, "kAudioUnitProperty_ParameterHistoryInfo")
    atDepthExpect(kAudioUnitProperty_ParameterIDName == 34, "kAudioUnitProperty_ParameterIDName")
    atDepthExpect(kAudioUnitProperty_ParameterInfo == 4, "kAudioUnitProperty_ParameterInfo")
    atDepthExpect(kAudioUnitProperty_ParameterList == 3, "kAudioUnitProperty_ParameterList")
    atDepthExpect(kAudioUnitProperty_ParameterStringFromValue == 33, "kAudioUnitProperty_ParameterStringFromValue")
    atDepthExpect(kAudioUnitProperty_ParameterValueFromString == 38, "kAudioUnitProperty_ParameterValueFromString")
    atDepthExpect(kAudioUnitProperty_ParameterValueStrings == 16, "kAudioUnitProperty_ParameterValueStrings")
    atDepthExpect(kAudioUnitProperty_ParametersForOverview == 57, "kAudioUnitProperty_ParametersForOverview")
    atDepthExpect(kAudioUnitProperty_PeerURL == 102, "kAudioUnitProperty_PeerURL")
    atDepthExpect(kAudioUnitProperty_PresentPreset == 36, "kAudioUnitProperty_PresentPreset")
    atDepthExpect(kAudioUnitProperty_PresentationLatency == 40, "kAudioUnitProperty_PresentationLatency")
    atDepthExpect(kAudioUnitProperty_RemoteControlEventListener == 100, "kAudioUnitProperty_RemoteControlEventListener")
    atDepthExpect(kAudioUnitProperty_RenderQuality == 26, "kAudioUnitProperty_RenderQuality")
    atDepthExpect(kAudioUnitProperty_RequestViewController == 56, "kAudioUnitProperty_RequestViewController")
    atDepthExpect(kAudioUnitProperty_ReverbPreset == 3017, "kAudioUnitProperty_ReverbPreset")
    atDepthExpect(kAudioUnitProperty_ReverbRoomType == 10, "kAudioUnitProperty_ReverbRoomType")
    atDepthExpect(kAudioUnitProperty_SampleRate == 2, "kAudioUnitProperty_SampleRate")
    atDepthExpect(kAudioUnitProperty_SampleRateConverterComplexity == 3014, "kAudioUnitProperty_SampleRateConverterComplexity")
    atDepthExpect(kAudioUnitProperty_ScheduleAudioSlice == 3300, "kAudioUnitProperty_ScheduleAudioSlice")
    atDepthExpect(kAudioUnitProperty_ScheduleStartTimeStamp == 3301, "kAudioUnitProperty_ScheduleStartTimeStamp")
    atDepthExpect(kAudioUnitProperty_ScheduledFileBufferSizeFrames == 3313, "kAudioUnitProperty_ScheduledFileBufferSizeFrames")
    atDepthExpect(kAudioUnitProperty_ScheduledFileIDs == 3310, "kAudioUnitProperty_ScheduledFileIDs")
    atDepthExpect(kAudioUnitProperty_ScheduledFileNumberBuffers == 3314, "kAudioUnitProperty_ScheduledFileNumberBuffers")
    atDepthExpect(kAudioUnitProperty_ScheduledFilePrime == 3312, "kAudioUnitProperty_ScheduledFilePrime")
    atDepthExpect(kAudioUnitProperty_ScheduledFileRegion == 3311, "kAudioUnitProperty_ScheduledFileRegion")
    atDepthExpect(kAudioUnitProperty_SetRenderCallback == 23, "kAudioUnitProperty_SetRenderCallback")
    atDepthExpect(kAudioUnitProperty_ShouldAllocateBuffer == 51, "kAudioUnitProperty_ShouldAllocateBuffer")
    atDepthExpect(kAudioUnitProperty_SpatialMixerAnyInputIsUsingPersonalizedHRTF == 3116, "kAudioUnitProperty_SpatialMixerAnyInputIsUsingPersonalizedHRTF")
    atDepthExpect(kAudioUnitProperty_SpatialMixerAttenuationCurve == 3013, "kAudioUnitProperty_SpatialMixerAttenuationCurve")
    atDepthExpect(kAudioUnitProperty_SpatialMixerDistanceParams == 3010, "kAudioUnitProperty_SpatialMixerDistanceParams")
    atDepthExpect(kAudioUnitProperty_SpatialMixerEnableHeadTracking == 3111, "kAudioUnitProperty_SpatialMixerEnableHeadTracking")
    atDepthExpect(kAudioUnitProperty_SpatialMixerOutputType == 3100, "kAudioUnitProperty_SpatialMixerOutputType")
    atDepthExpect(kAudioUnitProperty_SpatialMixerPersonalizedHRTFMode == 3113, "kAudioUnitProperty_SpatialMixerPersonalizedHRTFMode")
    atDepthExpect(kAudioUnitProperty_SpatialMixerPointSourceInHeadMode == 3103, "kAudioUnitProperty_SpatialMixerPointSourceInHeadMode")
    atDepthExpect(kAudioUnitProperty_SpatialMixerRenderingFlags == 3003, "kAudioUnitProperty_SpatialMixerRenderingFlags")
    atDepthExpect(kAudioUnitProperty_SpatialMixerSourceMode == 3005, "kAudioUnitProperty_SpatialMixerSourceMode")
    atDepthExpect(kAudioUnitProperty_SpatializationAlgorithm == 3000, "kAudioUnitProperty_SpatializationAlgorithm")
    atDepthExpect(kAudioUnitProperty_StreamFormat == 8, "kAudioUnitProperty_StreamFormat")
    atDepthExpect(kAudioUnitProperty_SupportedChannelLayoutTags == 32, "kAudioUnitProperty_SupportedChannelLayoutTags")
    atDepthExpect(kAudioUnitProperty_SupportedNumChannels == 13, "kAudioUnitProperty_SupportedNumChannels")
    atDepthExpect(kAudioUnitProperty_SupportsMPE == 58, "kAudioUnitProperty_SupportsMPE")
    atDepthExpect(kAudioUnitProperty_TailTime == 20, "kAudioUnitProperty_TailTime")
    atDepthExpect(kAudioUnitProperty_UsesInternalReverb == 1004, "kAudioUnitProperty_UsesInternalReverb")
    atDepthExpect(kAudioUnitScope_Global == 0, "kAudioUnitScope_Global")
    atDepthExpect(kAudioUnitScope_Group == 3, "kAudioUnitScope_Group")
    atDepthExpect(kAudioUnitScope_Input == 1, "kAudioUnitScope_Input")
    atDepthExpect(kAudioUnitScope_Layer == 6, "kAudioUnitScope_Layer")
    atDepthExpect(kAudioUnitScope_LayerItem == 7, "kAudioUnitScope_LayerItem")
    atDepthExpect(kAudioUnitScope_Note == 5, "kAudioUnitScope_Note")
    atDepthExpect(kAudioUnitScope_Output == 2, "kAudioUnitScope_Output")
    atDepthExpect(kAudioUnitScope_Part == 4, "kAudioUnitScope_Part")
    atDepthExpect(kAudioUnitSubType_AU3DMixerEmbedded == 862217581, "kAudioUnitSubType_AU3DMixerEmbedded")
    atDepthExpect(kAudioUnitSubType_AUAudioMix == 1634560376, "kAudioUnitSubType_AUAudioMix")
    atDepthExpect(kAudioUnitSubType_AUConverter == 1668247158, "kAudioUnitSubType_AUConverter")
    atDepthExpect(kAudioUnitSubType_AUSoundIsolation == 1634953587, "kAudioUnitSubType_AUSoundIsolation")
    atDepthExpect(kAudioUnitSubType_AUiPodEQ == 1768973681, "kAudioUnitSubType_AUiPodEQ")
    atDepthExpect(kAudioUnitSubType_AUiPodTime == 1768977517, "kAudioUnitSubType_AUiPodTime")
    atDepthExpect(kAudioUnitSubType_AUiPodTimeOther == 1768977519, "kAudioUnitSubType_AUiPodTimeOther")
    atDepthExpect(kAudioUnitSubType_AudioFilePlayer == 1634103404, "kAudioUnitSubType_AudioFilePlayer")
    atDepthExpect(kAudioUnitSubType_BandPassFilter == 1651532147, "kAudioUnitSubType_BandPassFilter")
    atDepthExpect(kAudioUnitSubType_DeferredRenderer == 1684366962, "kAudioUnitSubType_DeferredRenderer")
    atDepthExpect(kAudioUnitSubType_Delay == 1684368505, "kAudioUnitSubType_Delay")
    atDepthExpect(kAudioUnitSubType_Distortion == 1684632436, "kAudioUnitSubType_Distortion")
    atDepthExpect(kAudioUnitSubType_DynamicsProcessor == 1684237680, "kAudioUnitSubType_DynamicsProcessor")
    atDepthExpect(kAudioUnitSubType_GenericOutput == 1734700658, "kAudioUnitSubType_GenericOutput")
    atDepthExpect(kAudioUnitSubType_HighPassFilter == 1752195443, "kAudioUnitSubType_HighPassFilter")
    atDepthExpect(kAudioUnitSubType_HighShelfFilter == 1752393830, "kAudioUnitSubType_HighShelfFilter")
    atDepthExpect(kAudioUnitSubType_LowPassFilter == 1819304307, "kAudioUnitSubType_LowPassFilter")
    atDepthExpect(kAudioUnitSubType_LowShelfFilter == 1819502694, "kAudioUnitSubType_LowShelfFilter")
    atDepthExpect(kAudioUnitSubType_MIDISynth == 1836284270, "kAudioUnitSubType_MIDISynth")
    atDepthExpect(kAudioUnitSubType_MatrixMixer == 1836608888, "kAudioUnitSubType_MatrixMixer")
    atDepthExpect(kAudioUnitSubType_Merger == 1835364967, "kAudioUnitSubType_Merger")
    atDepthExpect(kAudioUnitSubType_MultiChannelMixer == 1835232632, "kAudioUnitSubType_MultiChannelMixer")
    atDepthExpect(kAudioUnitSubType_MultiSplitter == 1836281964, "kAudioUnitSubType_MultiSplitter")
    atDepthExpect(kAudioUnitSubType_NBandEQ == 1851942257, "kAudioUnitSubType_NBandEQ")
    atDepthExpect(kAudioUnitSubType_NewTimePitch == 1853191280, "kAudioUnitSubType_NewTimePitch")
    atDepthExpect(kAudioUnitSubType_ParametricEQ == 1886217585, "kAudioUnitSubType_ParametricEQ")
    atDepthExpect(kAudioUnitSubType_PeakLimiter == 1819112562, "kAudioUnitSubType_PeakLimiter")
    atDepthExpect(kAudioUnitSubType_RemoteIO == 1919512419, "kAudioUnitSubType_RemoteIO")
    atDepthExpect(kAudioUnitSubType_Reverb2 == 1920361010, "kAudioUnitSubType_Reverb2")
    atDepthExpect(kAudioUnitSubType_RoundTripAAC == 1918984547, "kAudioUnitSubType_RoundTripAAC")
    atDepthExpect(kAudioUnitSubType_SampleDelay == 1935961209, "kAudioUnitSubType_SampleDelay")
    atDepthExpect(kAudioUnitSubType_Sampler == 1935764848, "kAudioUnitSubType_Sampler")
    atDepthExpect(kAudioUnitSubType_ScheduledSoundPlayer == 1936945260, "kAudioUnitSubType_ScheduledSoundPlayer")
    atDepthExpect(kAudioUnitSubType_SpatialMixer == 862217581, "kAudioUnitSubType_SpatialMixer")
    atDepthExpect(kAudioUnitSubType_Splitter == 1936747636, "kAudioUnitSubType_Splitter")
    atDepthExpect(kAudioUnitSubType_TimePitch == 1953329268, "kAudioUnitSubType_TimePitch")
    atDepthExpect(kAudioUnitSubType_Varispeed == 1986097769, "kAudioUnitSubType_Varispeed")
    atDepthExpect(kAudioUnitSubType_VoiceProcessingIO == 1987078511, "kAudioUnitSubType_VoiceProcessingIO")
    atDepthExpect(kAudioUnitType_Effect == 1635083896, "kAudioUnitType_Effect")
    atDepthExpect(kAudioUnitType_FormatConverter == 1635083875, "kAudioUnitType_FormatConverter")
    atDepthExpect(kAudioUnitType_Generator == 1635084142, "kAudioUnitType_Generator")
    atDepthExpect(kAudioUnitType_MIDIProcessor == 1635085673, "kAudioUnitType_MIDIProcessor")
    atDepthExpect(kAudioUnitType_Mixer == 1635085688, "kAudioUnitType_Mixer")
    atDepthExpect(kAudioUnitType_MusicDevice == 1635085685, "kAudioUnitType_MusicDevice")
    atDepthExpect(kAudioUnitType_MusicEffect == 1635085670, "kAudioUnitType_MusicEffect")
    atDepthExpect(kAudioUnitType_OfflineEffect == 1635086188, "kAudioUnitType_OfflineEffect")
    atDepthExpect(kAudioUnitType_Output == 1635086197, "kAudioUnitType_Output")
    atDepthExpect(kAudioUnitType_Panner == 1635086446, "kAudioUnitType_Panner")
    atDepthExpect(kAudioUnitType_RemoteEffect == 1635086968, "kAudioUnitType_RemoteEffect")
    atDepthExpect(kAudioUnitType_RemoteGenerator == 1635086951, "kAudioUnitType_RemoteGenerator")
    atDepthExpect(kAudioUnitType_RemoteInstrument == 1635086953, "kAudioUnitType_RemoteInstrument")
    atDepthExpect(kAudioUnitType_RemoteMusicEffect == 1635086957, "kAudioUnitType_RemoteMusicEffect")
    atDepthExpect(kAudioUnitType_SpeechSynthesizer == 1635087216, "kAudioUnitType_SpeechSynthesizer")
    atDepthExpect(kCAFMarkerType_EditDestinationBegin == 1684170087, "kCAFMarkerType_EditDestinationBegin")
    atDepthExpect(kCAFMarkerType_EditDestinationEnd == 1684368996, "kCAFMarkerType_EditDestinationEnd")
    atDepthExpect(kCAFMarkerType_EditSourceBegin == 1667392871, "kCAFMarkerType_EditSourceBegin")
    atDepthExpect(kCAFMarkerType_EditSourceEnd == 1667591780, "kCAFMarkerType_EditSourceEnd")
    atDepthExpect(kCAFMarkerType_Generic == 0, "kCAFMarkerType_Generic")
    atDepthExpect(kCAFMarkerType_Index == 1768842360, "kCAFMarkerType_Index")
    atDepthExpect(kCAFMarkerType_KeySignature == 1802725735, "kCAFMarkerType_KeySignature")
    atDepthExpect(kCAFMarkerType_ProgramEnd == 1885695588, "kCAFMarkerType_ProgramEnd")
    atDepthExpect(kCAFMarkerType_ProgramStart == 1885496679, "kCAFMarkerType_ProgramStart")
    atDepthExpect(kCAFMarkerType_RegionEnd == 1919250020, "kCAFMarkerType_RegionEnd")
    atDepthExpect(kCAFMarkerType_RegionStart == 1919051111, "kCAFMarkerType_RegionStart")
    atDepthExpect(kCAFMarkerType_RegionSyncPoint == 1920170339, "kCAFMarkerType_RegionSyncPoint")
    atDepthExpect(kCAFMarkerType_ReleaseLoopEnd == 1919706478, "kCAFMarkerType_ReleaseLoopEnd")
    atDepthExpect(kCAFMarkerType_ReleaseLoopStart == 1919705703, "kCAFMarkerType_ReleaseLoopStart")
    atDepthExpect(kCAFMarkerType_SavedPlayPosition == 1936748659, "kCAFMarkerType_SavedPlayPosition")
    atDepthExpect(kCAFMarkerType_SelectionEnd == 1936027236, "kCAFMarkerType_SelectionEnd")
    atDepthExpect(kCAFMarkerType_SelectionStart == 1935828327, "kCAFMarkerType_SelectionStart")
    atDepthExpect(kCAFMarkerType_SustainLoopEnd == 1936483694, "kCAFMarkerType_SustainLoopEnd")
    atDepthExpect(kCAFMarkerType_SustainLoopStart == 1936482919, "kCAFMarkerType_SustainLoopStart")
    atDepthExpect(kCAFMarkerType_Tempo == 1953329263, "kCAFMarkerType_Tempo")
    atDepthExpect(kCAFMarkerType_TimeSignature == 1953720679, "kCAFMarkerType_TimeSignature")
    atDepthExpect(kCAFMarkerType_TrackEnd == 1952804452, "kCAFMarkerType_TrackEnd")
    atDepthExpect(kCAFMarkerType_TrackStart == 1952605543, "kCAFMarkerType_TrackStart")
    atDepthExpect(kCAF_AudioDataChunkID == 1684108385, "kCAF_AudioDataChunkID")
    atDepthExpect(kCAF_ChannelLayoutChunkID == 1667785070, "kCAF_ChannelLayoutChunkID")
    atDepthExpect(kCAF_EditCommentsChunkID == 1701077876, "kCAF_EditCommentsChunkID")
    atDepthExpect(kCAF_FileType == 1667327590, "kCAF_FileType")
    atDepthExpect(kCAF_FileVersion_Initial == 1, "kCAF_FileVersion_Initial")
    atDepthExpect(kCAF_FillerChunkID == 1718773093, "kCAF_FillerChunkID")
    atDepthExpect(kCAF_FormatListID == 1818522467, "kCAF_FormatListID")
    atDepthExpect(kCAF_InfoStringsChunkID == 1768842863, "kCAF_InfoStringsChunkID")
    atDepthExpect(kCAF_InstrumentChunkID == 1768846196, "kCAF_InstrumentChunkID")
    atDepthExpect(kCAF_MIDIChunkID == 1835623529, "kCAF_MIDIChunkID")
    atDepthExpect(kCAF_MagicCookieID == 1802857321, "kCAF_MagicCookieID")
    atDepthExpect(kCAF_MarkerChunkID == 1835102827, "kCAF_MarkerChunkID")
    atDepthExpect(kCAF_OverviewChunkID == 1870034551, "kCAF_OverviewChunkID")
    atDepthExpect(kCAF_PacketTableChunkID == 1885432692, "kCAF_PacketTableChunkID")
    atDepthExpect(kCAF_PeakChunkID == 1885692267, "kCAF_PeakChunkID")
    atDepthExpect(kCAF_RegionChunkID == 1919248238, "kCAF_RegionChunkID")
    atDepthExpect(kCAF_SMPTE_TimeType2398 == 12, "kCAF_SMPTE_TimeType2398")
    atDepthExpect(kCAF_SMPTE_TimeType24 == 1, "kCAF_SMPTE_TimeType24")
    atDepthExpect(kCAF_SMPTE_TimeType25 == 2, "kCAF_SMPTE_TimeType25")
    atDepthExpect(kCAF_SMPTE_TimeType2997 == 5, "kCAF_SMPTE_TimeType2997")
    atDepthExpect(kCAF_SMPTE_TimeType2997Drop == 6, "kCAF_SMPTE_TimeType2997Drop")
    atDepthExpect(kCAF_SMPTE_TimeType30 == 4, "kCAF_SMPTE_TimeType30")
    atDepthExpect(kCAF_SMPTE_TimeType30Drop == 3, "kCAF_SMPTE_TimeType30Drop")
    atDepthExpect(kCAF_SMPTE_TimeType50 == 11, "kCAF_SMPTE_TimeType50")
    atDepthExpect(kCAF_SMPTE_TimeType5994 == 8, "kCAF_SMPTE_TimeType5994")
    atDepthExpect(kCAF_SMPTE_TimeType5994Drop == 10, "kCAF_SMPTE_TimeType5994Drop")
    atDepthExpect(kCAF_SMPTE_TimeType60 == 7, "kCAF_SMPTE_TimeType60")
    atDepthExpect(kCAF_SMPTE_TimeType60Drop == 9, "kCAF_SMPTE_TimeType60Drop")
    atDepthExpect(kCAF_SMPTE_TimeTypeNone == 0, "kCAF_SMPTE_TimeTypeNone")
    atDepthExpect(kCAF_StreamDescriptionChunkID == 1684370275, "kCAF_StreamDescriptionChunkID")
    atDepthExpect(kCAF_StringsChunkID == 1937011303, "kCAF_StringsChunkID")
    atDepthExpect(kCAF_UMIDChunkID == 1970104676, "kCAF_UMIDChunkID")
    atDepthExpect(kCAF_UUIDChunkID == 1970628964, "kCAF_UUIDChunkID")
    atDepthExpect(kCAF_iXMLChunkID == 1767394636, "kCAF_iXMLChunkID")
    atDepthExpect(kExtAudioFileError_AsyncWriteBufferOverflow == -66570, "kExtAudioFileError_AsyncWriteBufferOverflow")
    atDepthExpect(kExtAudioFileError_AsyncWriteTooLarge == -66569, "kExtAudioFileError_AsyncWriteTooLarge")
    atDepthExpect(kExtAudioFileError_CodecUnavailableInputConsumed == -66559, "kExtAudioFileError_CodecUnavailableInputConsumed")
    atDepthExpect(kExtAudioFileError_CodecUnavailableInputNotConsumed == -66560, "kExtAudioFileError_CodecUnavailableInputNotConsumed")
    atDepthExpect(kExtAudioFileError_InvalidChannelMap == -66564, "kExtAudioFileError_InvalidChannelMap")
    atDepthExpect(kExtAudioFileError_InvalidDataFormat == -66566, "kExtAudioFileError_InvalidDataFormat")
    atDepthExpect(kExtAudioFileError_InvalidOperationOrder == -66565, "kExtAudioFileError_InvalidOperationOrder")
    atDepthExpect(kExtAudioFileError_InvalidProperty == -66561, "kExtAudioFileError_InvalidProperty")
    atDepthExpect(kExtAudioFileError_InvalidPropertySize == -66562, "kExtAudioFileError_InvalidPropertySize")
    atDepthExpect(kExtAudioFileError_InvalidSeek == -66568, "kExtAudioFileError_InvalidSeek")
    atDepthExpect(kExtAudioFileError_MaxPacketSizeUnknown == -66567, "kExtAudioFileError_MaxPacketSizeUnknown")
    atDepthExpect(kExtAudioFileError_NonPCMClientFormat == -66563, "kExtAudioFileError_NonPCMClientFormat")
    atDepthExpect(kExtAudioFilePacketTableInfoOverride_UseFileValue == -1, "kExtAudioFilePacketTableInfoOverride_UseFileValue")
    atDepthExpect(kExtAudioFilePacketTableInfoOverride_UseFileValueIfValid == 1, "kExtAudioFilePacketTableInfoOverride_UseFileValueIfValid")
    atDepthExpect(kExtAudioFileProperty_AudioConverter == 1633906294, "kExtAudioFileProperty_AudioConverter")
    atDepthExpect(kExtAudioFileProperty_AudioFile == 1634101612, "kExtAudioFileProperty_AudioFile")
    atDepthExpect(kExtAudioFileProperty_ClientChannelLayout == 1667460207, "kExtAudioFileProperty_ClientChannelLayout")
    atDepthExpect(kExtAudioFileProperty_ClientDataFormat == 1667657076, "kExtAudioFileProperty_ClientDataFormat")
    atDepthExpect(kExtAudioFileProperty_ClientMaxPacketSize == 1668116595, "kExtAudioFileProperty_ClientMaxPacketSize")
    atDepthExpect(kExtAudioFileProperty_CodecManufacturer == 1668112750, "kExtAudioFileProperty_CodecManufacturer")
    atDepthExpect(kExtAudioFileProperty_ConverterConfig == 1633903462, "kExtAudioFileProperty_ConverterConfig")
    atDepthExpect(kExtAudioFileProperty_FileChannelLayout == 1717791855, "kExtAudioFileProperty_FileChannelLayout")
    atDepthExpect(kExtAudioFileProperty_FileDataFormat == 1717988724, "kExtAudioFileProperty_FileDataFormat")
    atDepthExpect(kExtAudioFileProperty_FileLengthFrames == 593916525, "kExtAudioFileProperty_FileLengthFrames")
    atDepthExpect(kExtAudioFileProperty_FileMaxPacketSize == 1718448243, "kExtAudioFileProperty_FileMaxPacketSize")
    atDepthExpect(kExtAudioFileProperty_IOBuffer == 1768907366, "kExtAudioFileProperty_IOBuffer")
    atDepthExpect(kExtAudioFileProperty_IOBufferSizeBytes == 1768907379, "kExtAudioFileProperty_IOBufferSizeBytes")
    atDepthExpect(kExtAudioFileProperty_PacketTable == 2020635753, "kExtAudioFileProperty_PacketTable")
    atDepthExpect(kMusicEventType_AUPreset == 10, "kMusicEventType_AUPreset")
    atDepthExpect(kMusicEventType_ExtendedNote == 1, "kMusicEventType_ExtendedNote")
    atDepthExpect(kMusicEventType_ExtendedTempo == 3, "kMusicEventType_ExtendedTempo")
    atDepthExpect(kMusicEventType_MIDIChannelMessage == 7, "kMusicEventType_MIDIChannelMessage")
    atDepthExpect(kMusicEventType_MIDINoteMessage == 6, "kMusicEventType_MIDINoteMessage")
    atDepthExpect(kMusicEventType_MIDIRawData == 8, "kMusicEventType_MIDIRawData")
    atDepthExpect(kMusicEventType_Meta == 5, "kMusicEventType_Meta")
    atDepthExpect(kMusicEventType_NULL == 0, "kMusicEventType_NULL")
    atDepthExpect(kMusicEventType_Parameter == 9, "kMusicEventType_Parameter")
    atDepthExpect(kMusicEventType_User == 4, "kMusicEventType_User")
    atDepthExpect(kSystemSoundID_Vibrate == 4095, "kSystemSoundID_Vibrate")
}
