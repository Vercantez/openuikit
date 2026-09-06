import Foundation

public let kAudioFilePropertyFileFormat: AudioFilePropertyID = atFourCC("ffmt")
public let kAudioFilePropertyDataFormat: AudioFilePropertyID = atFourCC("dfmt")
public let kAudioFilePropertyIsOptimized: AudioFilePropertyID = atFourCC("optm")
public let kAudioFilePropertyMagicCookieData: AudioFilePropertyID = atFourCC("mgic")
public let kAudioFilePropertyAudioDataByteCount: AudioFilePropertyID = atFourCC("bcnt")
public let kAudioFilePropertyAudioDataPacketCount: AudioFilePropertyID = atFourCC("pcnt")
public let kAudioFilePropertyMaximumPacketSize: AudioFilePropertyID = atFourCC("psze")
public let kAudioFilePropertyDataOffset: AudioFilePropertyID = atFourCC("doff")
public let kAudioFilePropertyChannelLayout: AudioFilePropertyID = atFourCC("cmap")
public let kAudioFilePropertyDeferSizeUpdates: AudioFilePropertyID = atFourCC("dszu")
public let kAudioFilePropertyDataFormatName: AudioFilePropertyID = atFourCC("fnme")
public let kAudioFilePropertyMarkerList: AudioFilePropertyID = atFourCC("mkls")
public let kAudioFilePropertyRegionList: AudioFilePropertyID = atFourCC("rgls")
public let kAudioFilePropertyPacketToFrame: AudioFilePropertyID = atFourCC("pkfr")
public let kAudioFilePropertyFrameToPacket: AudioFilePropertyID = atFourCC("frpk")
public let kAudioFilePropertyPacketToByte: AudioFilePropertyID = atFourCC("pkby")
public let kAudioFilePropertyByteToPacket: AudioFilePropertyID = atFourCC("bypk")
public let kAudioFilePropertyChunkIDs: AudioFilePropertyID = atFourCC("chid")
public let kAudioFilePropertyInfoDictionary: AudioFilePropertyID = atFourCC("info")
public let kAudioFilePropertyPacketTableInfo: AudioFilePropertyID = atFourCC("pnfo")
public let kAudioFilePropertyFormatList: AudioFilePropertyID = atFourCC("flst")
public let kAudioFilePropertyPacketSizeUpperBound: AudioFilePropertyID = atFourCC("pkub")
public let kAudioFilePropertyReserveDuration: AudioFilePropertyID = atFourCC("rsrv")
public let kAudioFilePropertyEstimatedDuration: AudioFilePropertyID = atFourCC("edur")
public let kAudioFilePropertyBitRate: AudioFilePropertyID = atFourCC("brat")
public let kAudioFilePropertyID3Tag: AudioFilePropertyID = atFourCC("id3t")
public let kAudioFilePropertySourceBitDepth: AudioFilePropertyID = atFourCC("sbtd")
public let kAudioFilePropertyAlbumArtwork: AudioFilePropertyID = atFourCC("aart")
public let kAudioFilePropertyAudioTrackCount: AudioFilePropertyID = atFourCC("atct")
public let kAudioFilePropertyUseAudioTrack: AudioFilePropertyID = atFourCC("uatk")
public let kAudioFilePropertyID3TagOffset: AudioFilePropertyID = atFourCC("id3o")
public let kAudioFilePropertyNextIndependentPacket: AudioFilePropertyID = atFourCC("nind")
public let kAudioFilePropertyPreviousIndependentPacket: AudioFilePropertyID = atFourCC("pind")
public let kAudioFilePropertyPacketToDependencyInfo: AudioFilePropertyID = atFourCC("pdep")
public let kAudioFilePropertyPacketToRollDistance: AudioFilePropertyID = atFourCC("prll")
public let kAudioFilePropertyRestrictsRandomAccess: AudioFilePropertyID = atFourCC("rran")
public let kAudioFilePropertyPacketRangeByteCountUpperBound: AudioFilePropertyID = atFourCC("prub")

public let kExtAudioFileProperty_FileDataFormat: ExtAudioFilePropertyID = atFourCC("ffmt")
public let kExtAudioFileProperty_FileChannelLayout: ExtAudioFilePropertyID = atFourCC("fclo")
public let kExtAudioFileProperty_ClientDataFormat: ExtAudioFilePropertyID = atFourCC("cfmt")
public let kExtAudioFileProperty_ClientChannelLayout: ExtAudioFilePropertyID = atFourCC("cclo")
public let kExtAudioFileProperty_CodecManufacturer: ExtAudioFilePropertyID = atFourCC("cman")
public let kExtAudioFileProperty_AudioConverter: ExtAudioFilePropertyID = atFourCC("acnv")
public let kExtAudioFileProperty_AudioFile: ExtAudioFilePropertyID = atFourCC("afil")
public let kExtAudioFileProperty_FileMaxPacketSize: ExtAudioFilePropertyID = atFourCC("fmps")
public let kExtAudioFileProperty_ClientMaxPacketSize: ExtAudioFilePropertyID = atFourCC("cmps")
public let kExtAudioFileProperty_FileLengthFrames: ExtAudioFilePropertyID = atFourCC("#frm")
public let kExtAudioFileProperty_ConverterConfig: ExtAudioFilePropertyID = atFourCC("accf")
public let kExtAudioFileProperty_IOBufferSizeBytes: ExtAudioFilePropertyID = atFourCC("iobs")
public let kExtAudioFileProperty_IOBuffer: ExtAudioFilePropertyID = atFourCC("iobf")
public let kExtAudioFileProperty_PacketTable: ExtAudioFilePropertyID = atFourCC("xpti")

public let kExtAudioFilePacketTableInfoOverride_UseFileValue: ExtAudioFilePacketTableInfoOverride = -1
public let kExtAudioFilePacketTableInfoOverride_UseFileValueIfValid: ExtAudioFilePacketTableInfoOverride = 1

public let kAFInfoDictionary_Album = "album"
public let kAFInfoDictionary_ApproximateDurationInSeconds = "approximate duration in seconds"
public let kAFInfoDictionary_Artist = "artist"
public let kAFInfoDictionary_ChannelLayout = "channel layout"
public let kAFInfoDictionary_Comments = "comments"
public let kAFInfoDictionary_Composer = "composer"
public let kAFInfoDictionary_Copyright = "copyright"
public let kAFInfoDictionary_EncodingApplication = "encoding application"
public let kAFInfoDictionary_Genre = "genre"
public let kAFInfoDictionary_ISRC = "ISRC"
public let kAFInfoDictionary_KeySignature = "key signature"
public let kAFInfoDictionary_Lyricist = "lyricist"
public let kAFInfoDictionary_NominalBitRate = "nominal bit rate"
public let kAFInfoDictionary_RecordedDate = "recorded date"
public let kAFInfoDictionary_SourceBitDepth = "source bit depth"
public let kAFInfoDictionary_SourceEncoder = "source encoder"
public let kAFInfoDictionary_SubTitle = "subtitle"
public let kAFInfoDictionary_Tempo = "tempo"
public let kAFInfoDictionary_TimeSignature = "time signature"
public let kAFInfoDictionary_Title = "title"
public let kAFInfoDictionary_TrackNumber = "track number"
public let kAFInfoDictionary_Year = "year"

public struct AudioFileRegionFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let loopEnable = AudioFileRegionFlags(rawValue: 1)
    public static let playForward = AudioFileRegionFlags(rawValue: 2)
    public static let playBackward = AudioFileRegionFlags(rawValue: 4)
}
