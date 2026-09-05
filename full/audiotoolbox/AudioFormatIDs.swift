import Foundation

public let kAudioFormatProperty_FormatInfo: AudioFormatPropertyID = atFourCC("fmti")
public let kAudioFormatProperty_FormatName: AudioFormatPropertyID = atFourCC("fnam")
public let kAudioFormatProperty_EncodeFormatIDs: AudioFormatPropertyID = atFourCC("acof")
public let kAudioFormatProperty_DecodeFormatIDs: AudioFormatPropertyID = atFourCC("acif")
public let kAudioFormatProperty_FormatList: AudioFormatPropertyID = atFourCC("flst")
public let kAudioFormatProperty_ASBDFromESDS: AudioFormatPropertyID = atFourCC("essd")
public let kAudioFormatProperty_ChannelLayoutFromESDS: AudioFormatPropertyID = atFourCC("escl")
public let kAudioFormatProperty_OutputFormatList: AudioFormatPropertyID = atFourCC("ofls")
public let kAudioFormatProperty_FirstPlayableFormatFromList: AudioFormatPropertyID = atFourCC("fpfl")
public let kAudioFormatProperty_FormatIsVBR: AudioFormatPropertyID = atFourCC("fvbr")
public let kAudioFormatProperty_FormatIsExternallyFramed: AudioFormatPropertyID = atFourCC("fexf")
public let kAudioFormatProperty_FormatEmploysDependentPackets: AudioFormatPropertyID = atFourCC("fdep")
public let kAudioFormatProperty_FormatIsEncrypted: AudioFormatPropertyID = atFourCC("cryp")
public let kAudioFormatProperty_Encoders: AudioFormatPropertyID = atFourCC("aven")
public let kAudioFormatProperty_Decoders: AudioFormatPropertyID = atFourCC("avde")
public let kAudioFormatProperty_AvailableEncodeChannelLayoutTags: AudioFormatPropertyID = atFourCC("aecl")
public let kAudioFormatProperty_AvailableEncodeNumberChannels: AudioFormatPropertyID = atFourCC("avnc")
public let kAudioFormatProperty_AvailableEncodeBitRates: AudioFormatPropertyID = atFourCC("aebr")
public let kAudioFormatProperty_AvailableEncodeSampleRates: AudioFormatPropertyID = atFourCC("aesr")
public let kAudioFormatProperty_ASBDFromMPEGPacket: AudioFormatPropertyID = atFourCC("admp")
public let kAudioFormatProperty_BitmapForLayoutTag: AudioFormatPropertyID = atFourCC("bmtg")
public let kAudioFormatProperty_MatrixMixMap: AudioFormatPropertyID = atFourCC("mmap")
public let kAudioFormatProperty_ChannelMap: AudioFormatPropertyID = atFourCC("chmp")
public let kAudioFormatProperty_NumberOfChannelsForLayout: AudioFormatPropertyID = atFourCC("nchm")
public let kAudioFormatProperty_AreChannelLayoutsEquivalent: AudioFormatPropertyID = atFourCC("cheq")
public let kAudioFormatProperty_ChannelLayoutHash: AudioFormatPropertyID = atFourCC("chha")
public let kAudioFormatProperty_ValidateChannelLayout: AudioFormatPropertyID = atFourCC("vacl")
public let kAudioFormatProperty_ChannelLayoutForTag: AudioFormatPropertyID = atFourCC("cmpl")
public let kAudioFormatProperty_TagForChannelLayout: AudioFormatPropertyID = atFourCC("cmpt")
public let kAudioFormatProperty_ChannelLayoutName: AudioFormatPropertyID = atFourCC("lonm")
public let kAudioFormatProperty_ChannelLayoutSimpleName: AudioFormatPropertyID = atFourCC("lsnm")
public let kAudioFormatProperty_ChannelLayoutForBitmap: AudioFormatPropertyID = atFourCC("cmpb")
public let kAudioFormatProperty_ChannelName: AudioFormatPropertyID = atFourCC("cnam")
public let kAudioFormatProperty_ChannelShortName: AudioFormatPropertyID = atFourCC("csnm")
public let kAudioFormatProperty_TagsForNumberOfChannels: AudioFormatPropertyID = atFourCC("tagc")
public let kAudioFormatProperty_PanningMatrix: AudioFormatPropertyID = atFourCC("panm")
public let kAudioFormatProperty_BalanceFade: AudioFormatPropertyID = atFourCC("balf")
public let kAudioFormatProperty_ID3TagSize: AudioFormatPropertyID = atFourCC("id3s")
public let kAudioFormatProperty_ID3TagToDictionary: AudioFormatPropertyID = atFourCC("id3d")
public let kAudioFormatProperty_HardwareCodecCapabilities: AudioFormatPropertyID = atFourCC("hwcc")
public let kAudioFormatProperty_AvailableDecodeNumberChannels: AudioFormatPropertyID = atFourCC("vdnc")

public let kAudioFormatUnspecifiedError: Int32 = atSignedFourCC("what")
public let kAudioFormatUnsupportedPropertyError: Int32 = atSignedFourCC("prop")
public let kAudioFormatBadPropertySizeError: Int32 = atSignedFourCC("!siz")
public let kAudioFormatBadSpecifierSizeError: Int32 = atSignedFourCC("!spc")
public let kAudioFormatUnsupportedDataFormatError: Int32 = atSignedFourCC("fmt?")
public let kAudioFormatUnknownFormatError: Int32 = atSignedFourCC("!dat")

public func AudioFormatGetPropertyInfo(
    _ inPropertyID: AudioFormatPropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeRawPointer?,
    _ outPropertyDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inSpecifierSize
    _ = inSpecifier
    switch inPropertyID {
    case kAudioFormatProperty_FormatInfo:
        outPropertyDataSize?.pointee = UInt32(atASBDSize)
        return 0
    case kAudioFormatProperty_FormatIsVBR,
         kAudioFormatProperty_FormatIsExternallyFramed,
         kAudioFormatProperty_FormatIsEncrypted,
         kAudioFormatProperty_FormatEmploysDependentPackets:
        outPropertyDataSize?.pointee = 4
        return 0
    default:
        outPropertyDataSize?.pointee = 0
        return kAudioFormatUnsupportedPropertyError
    }
}

public func AudioFormatGetProperty(
    _ inPropertyID: AudioFormatPropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeRawPointer?,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    if inPropertyID == kAudioFormatProperty_FormatInfo {
        guard let inSpecifier, inSpecifierSize >= UInt32(atASBDSize) else {
            return kAudioFormatBadSpecifierSizeError
        }
        guard var format = atLoadASBD(inSpecifier) else {
            return kAudioFormatUnspecifiedError
        }
        if format.mFormatID != 0 && format.mFormatID != atFormatLinearPCM {
            return kAudioFormatUnsupportedDataFormatError
        }
        if format.mFormatID == atFormatLinearPCM {
            atFillPCMASBD(&format)
        }
        let size = ioPropertyDataSize?.pointee ?? 0
        if size < UInt32(atASBDSize) && outPropertyData != nil {
            return kAudioFormatBadPropertySizeError
        }
        ioPropertyDataSize?.pointee = UInt32(atASBDSize)
        if let outPropertyData {
            atStoreASBD(format, to: outPropertyData)
        }
        return 0
    }
    if inPropertyID == kAudioFormatProperty_FormatIsVBR
        || inPropertyID == kAudioFormatProperty_FormatIsExternallyFramed
        || inPropertyID == kAudioFormatProperty_FormatIsEncrypted
        || inPropertyID == kAudioFormatProperty_FormatEmploysDependentPackets
    {
        guard let inSpecifier, inSpecifierSize >= UInt32(atASBDSize) else {
            return kAudioFormatBadSpecifierSizeError
        }
        guard let format = atLoadASBD(inSpecifier) else {
            return kAudioFormatUnspecifiedError
        }
        var value: UInt32 = 0
        if format.mFormatID != 0 && format.mFormatID != atFormatLinearPCM {
            if inPropertyID == kAudioFormatProperty_FormatIsVBR
                || inPropertyID == kAudioFormatProperty_FormatIsExternallyFramed
            {
                value = 1
            }
        }
        if let ioPropertyDataSize, ioPropertyDataSize.pointee < 4, outPropertyData != nil {
            return kAudioFormatBadPropertySizeError
        }
        ioPropertyDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: value, as: UInt32.self)
        return 0
    }
    return kAudioFormatUnsupportedPropertyError
}
