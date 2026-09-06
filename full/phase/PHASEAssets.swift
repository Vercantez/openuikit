import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif

public class PHASEAsset: NSObject {
    public enum AssetType: Int, Hashable, Sendable {
        case resident = 0
        case streamed = 1
    }

    public let identifier: String

    @available(*, unavailable)
    public override init() {
        fatalError("PHASEAsset has no public default initializer")
    }

    init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
}

public final class PHASEGlobalMetaParameterAsset: PHASEAsset {}

public final class PHASESoundEventNodeAsset: PHASEAsset {}

public final class PHASESoundAsset: PHASEAsset {
    public let url: URL?
    public let data: Data?
    public let type: AssetType

    init(identifier: String, url: URL?, data: Data?, type: AssetType) {
        self.url = url
        self.data = data
        self.type = type
        super.init(identifier: identifier)
    }
}

public final class PHASEAssetRegistry: NSObject {
    weak var engine: PHASEEngine?
    private var assets: [String: PHASEAsset] = [:]
    public private(set) var globalMetaParameters: [String: PHASEMetaParameter] = [:]

    override init() {
        super.init()
    }

    public func asset(forIdentifier identifier: String) -> PHASEAsset? {
        assets[identifier]
    }

    public func registerGlobalMetaParameter(
        metaParameterDefinition: PHASEMetaParameterDefinition
    ) throws -> PHASEGlobalMetaParameterAsset {
        let identifier = metaParameterDefinition.identifier
        if assets[identifier] != nil {
            throw PHASEAssetError(
                .alreadyExists,
                userInfo: phaseLinuxReason("global meta-parameter \(identifier) already exists")
            )
        }
        let parameter: PHASEMetaParameter
        if let number = metaParameterDefinition as? PHASENumberMetaParameterDefinition {
            parameter = PHASENumberMetaParameter(
                identifier: identifier,
                value: (number.value as? NSNumber)?.doubleValue ?? number.minimum,
                minimum: number.minimum,
                maximum: number.maximum
            )
        } else if let string = metaParameterDefinition as? PHASEStringMetaParameterDefinition {
            parameter = PHASEStringMetaParameter(
                identifier: identifier,
                value: string.value as? String ?? ""
            )
        } else {
            parameter = PHASEMetaParameter(identifier: identifier, value: metaParameterDefinition.value)
        }
        globalMetaParameters[identifier] = parameter
        let asset = PHASEGlobalMetaParameterAsset(identifier: identifier)
        assets[identifier] = asset
        return asset
    }

    public func registerSoundEventAsset(
        rootNode: PHASESoundEventNodeDefinition,
        identifier: String?
    ) throws -> PHASESoundEventNodeAsset {
        let ident = identifier ?? rootNode.identifier
        if assets[ident] != nil {
            throw PHASEAssetError(
                .alreadyExists,
                userInfo: phaseLinuxReason("sound-event asset \(ident) already exists")
            )
        }
        let asset = PHASESoundEventNodeAsset(identifier: ident)
        assets[ident] = asset
        registeredRoots[ident] = rootNode
        return asset
    }

    var registeredRoots: [String: PHASESoundEventNodeDefinition] = [:]

    public func unregisterAsset(identifier: String) async -> Bool {
        guard assets[identifier] != nil else { return false }
        assets.removeValue(forKey: identifier)
        globalMetaParameters.removeValue(forKey: identifier)
        registeredRoots.removeValue(forKey: identifier)
        return true
    }

    @_spi(OpenUIKitHost)
    public func hostUnregisterAsset(identifier: String) -> Bool {
        guard assets[identifier] != nil else { return false }
        assets.removeValue(forKey: identifier)
        globalMetaParameters.removeValue(forKey: identifier)
        registeredRoots.removeValue(forKey: identifier)
        return true
    }

#if canImport(AVFAudio)
    public func registerSoundAsset(
        url: URL,
        identifier: String?,
        assetType: PHASEAsset.AssetType,
        channelLayout: AVAudioChannelLayout?,
        normalizationMode: PHASENormalizationMode
    ) throws -> PHASESoundAsset {
        _ = url
        _ = identifier
        _ = assetType
        _ = channelLayout
        _ = normalizationMode
        throw PHASEAssetError(
            .failedToLoad,
            userInfo: phaseLinuxReason("sound-asset decode requires Apple audio codecs")
        )
    }

    public func registerSoundAsset(
        data: Data,
        identifier: String?,
        format: AVAudioFormat,
        normalizationMode: PHASENormalizationMode
    ) throws -> PHASESoundAsset {
        _ = data
        _ = identifier
        _ = format
        _ = normalizationMode
        throw PHASEAssetError(
            .failedToLoad,
            userInfo: phaseLinuxReason("sound-asset decode requires Apple audio codecs")
        )
    }
#endif
}
