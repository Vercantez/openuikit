import Foundation

public let kAudioConverterPropertyMinimumInputBufferSize: AudioConverterPropertyID = atFourCC("mibs")
public let kAudioConverterPropertyMinimumOutputBufferSize: AudioConverterPropertyID = atFourCC("mobs")
public let kAudioConverterPropertyMaximumInputBufferSize: AudioConverterPropertyID = atFourCC("xibs")
public let kAudioConverterPropertyMaximumInputPacketSize: AudioConverterPropertyID = atFourCC("xips")
public let kAudioConverterPropertyMaximumOutputPacketSize: AudioConverterPropertyID = atFourCC("xops")
public let kAudioConverterPropertyCalculateInputBufferSize: AudioConverterPropertyID = atFourCC("cibs")
public let kAudioConverterPropertyCalculateOutputBufferSize: AudioConverterPropertyID = atFourCC("cobs")
public let kAudioConverterSampleRateConverterComplexity: AudioConverterPropertyID = atFourCC("srca")
public let kAudioConverterSampleRateConverterQuality: AudioConverterPropertyID = atFourCC("srcq")
public let kAudioConverterSampleRateConverterInitialPhase: AudioConverterPropertyID = atFourCC("srcp")
public let kAudioConverterSampleRateConverterAlgorithm: AudioConverterPropertyID = atFourCC("srci")
public let kAudioConverterCodecQuality: AudioConverterPropertyID = atFourCC("cdqu")
public let kAudioConverterPrimeMethod: AudioConverterPropertyID = atFourCC("prmm")
public let kAudioConverterPrimeInfo: AudioConverterPropertyID = atFourCC("prim")
public let kAudioConverterChannelMap: AudioConverterPropertyID = atFourCC("chmp")
public let kAudioConverterDecompressionMagicCookie: AudioConverterPropertyID = atFourCC("dmgc")
public let kAudioConverterCompressionMagicCookie: AudioConverterPropertyID = atFourCC("cmgc")
public let kAudioConverterEncodeBitRate: AudioConverterPropertyID = atFourCC("brat")
public let kAudioConverterEncodeAdjustableSampleRate: AudioConverterPropertyID = atFourCC("ajsr")
public let kAudioConverterInputChannelLayout: AudioConverterPropertyID = atFourCC("icl ")
public let kAudioConverterOutputChannelLayout: AudioConverterPropertyID = atFourCC("ocl ")
public let kAudioConverterApplicableEncodeBitRates: AudioConverterPropertyID = atFourCC("aebr")
public let kAudioConverterAvailableEncodeBitRates: AudioConverterPropertyID = atFourCC("vebr")
public let kAudioConverterApplicableEncodeSampleRates: AudioConverterPropertyID = atFourCC("aesr")
public let kAudioConverterAvailableEncodeSampleRates: AudioConverterPropertyID = atFourCC("vesr")
public let kAudioConverterAvailableEncodeChannelLayoutTags: AudioConverterPropertyID = atFourCC("aecl")
public let kAudioConverterCurrentOutputStreamDescription: AudioConverterPropertyID = atFourCC("acod")
public let kAudioConverterCurrentInputStreamDescription: AudioConverterPropertyID = atFourCC("acid")
public let kAudioConverterPropertySettings: AudioConverterPropertyID = atFourCC("acps")
public let kAudioConverterPropertyBitDepthHint: AudioConverterPropertyID = atFourCC("acbd")
public let kAudioConverterPropertyFormatList: AudioConverterPropertyID = atFourCC("flst")
public let kAudioConverterPropertyCanResumeFromInterruption: AudioConverterPropertyID = atFourCC("crfi")
public let kAudioConverterPropertyPerformDownmix: AudioConverterPropertyID = atFourCC("dmix")
public let kAudioConverterPropertyChannelMixMap: AudioConverterPropertyID = atFourCC("mmap")
public let kAudioConverterPropertyInputCodecParameters: AudioConverterPropertyID = atFourCC("icdp")
public let kAudioConverterPropertyOutputCodecParameters: AudioConverterPropertyID = atFourCC("ocdp")

public let kAudioConverterQuality_Min: UInt32 = 0
public let kAudioConverterQuality_Low: UInt32 = 0x20
public let kAudioConverterQuality_Medium: UInt32 = 0x40
public let kAudioConverterQuality_High: UInt32 = 0x60
public let kAudioConverterQuality_Max: UInt32 = 0x7F

public let kAudioConverterSampleRateConverterComplexity_Linear: UInt32 = atFourCC("line")
public let kAudioConverterSampleRateConverterComplexity_Normal: UInt32 = atFourCC("norm")
public let kAudioConverterSampleRateConverterComplexity_Mastering: UInt32 = atFourCC("bats")
public let kAudioConverterSampleRateConverterComplexity_MinimumPhase: UInt32 = atFourCC("minp")

extension AudioConverterOptions {
    public static let unbuffered = AudioConverterOptions(rawValue: 1)
}

public typealias AudioConverterComplexInputDataProc = @convention(c) (
    AudioConverterRef,
    UnsafeMutablePointer<UInt32>,
    UnsafeMutableRawPointer,
    UnsafeMutablePointer<UnsafeMutableRawPointer?>,
    UnsafeMutableRawPointer?
) -> Int32
