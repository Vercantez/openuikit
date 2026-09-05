import Foundation

public let kAUNodeInteraction_Connection: UInt32 = 1
public let kAUNodeInteraction_InputCallback: UInt32 = 2

public typealias AURenderCallback = (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    UnsafeRawPointer?,
    UInt32,
    UInt32,
    UnsafeMutableRawPointer?
) -> Int32

@frozen
public struct AURenderCallbackStruct {
    public var inputProc: AURenderCallback?
    public var inputProcRefCon: UnsafeMutableRawPointer?

    public init() {
        inputProc = nil
        inputProcRefCon = nil
    }

    public init(inputProc: AURenderCallback?, inputProcRefCon: UnsafeMutableRawPointer?) {
        self.inputProc = inputProc
        self.inputProcRefCon = inputProcRefCon
    }
}

@frozen
public struct AUNodeInteraction: Equatable, Hashable, Sendable {
    public var nodeInteractionType: UInt32
    public var sourceNode: AUNode
    public var sourceOutputNumber: UInt32
    public var destNode: AUNode
    public var destInputNumber: UInt32

    public init() {
        nodeInteractionType = 0
        sourceNode = 0
        sourceOutputNumber = 0
        destNode = 0
        destInputNumber = 0
    }

    public init(
        nodeInteractionType: UInt32,
        sourceNode: AUNode,
        sourceOutputNumber: UInt32,
        destNode: AUNode,
        destInputNumber: UInt32
    ) {
        self.nodeInteractionType = nodeInteractionType
        self.sourceNode = sourceNode
        self.sourceOutputNumber = sourceOutputNumber
        self.destNode = destNode
        self.destInputNumber = destInputNumber
    }
}

internal struct ATAUGraphConnection {
    var sourceNode: AUNode
    var sourceOutput: UInt32
    var destNode: AUNode
    var destInput: UInt32
}

internal struct ATAUGraphInputCallback {
    var destNode: AUNode
    var destInput: UInt32
    var callback: AURenderCallbackStruct
}

internal final class ATAUGraphNode {
    let node: AUNode
    var description: AudioComponentDescription
    var unit: AudioUnit?
    var ownedUnit: ATAudioUnitObject?

    init(node: AUNode, description: AudioComponentDescription) {
        self.node = node
        self.description = description
    }
}

internal final class ATAUGraphObject: ATObject {
    var nodes: [ATAUGraphNode] = []
    var connections: [ATAUGraphConnection] = []
    var inputCallbacks: [ATAUGraphInputCallback] = []
    var nextNode: AUNode = 1
    var opened = false
    var initialized = false
    var running = false
}

public func NewAUGraph(_ outGraph: UnsafeMutablePointer<AUGraph?>?) -> Int32 {
    outGraph?.pointee = nil
    let graph = ATAUGraphObject()
    outGraph?.pointee = ATRegistry.shared.retain(graph)
    return 0
}

@_cdecl("DisposeAUGraph")
public func DisposeAUGraph(_ inGraph: AUGraph?) -> Int32 {
    if let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) {
        for node in graph.nodes {
            if let unit = node.unit {
                _ = AudioComponentInstanceDispose(unit)
            }
        }
        graph.nodes.removeAll()
        graph.connections.removeAll()
    }
    let status = ATRegistry.shared.release(inGraph)
    return status == atParamError ? 0 : status
}

@_cdecl("AUGraphOpen")
public func AUGraphOpen(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.opened = true
    return 0
}

@_cdecl("AUGraphClose")
public func AUGraphClose(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.opened = false
    graph.running = false
    return 0
}

public func AUGraphAddNode(
    _ inGraph: AUGraph?,
    _ inDescription: UnsafePointer<AudioComponentDescription>?,
    _ outNode: UnsafeMutablePointer<AUNode>?
) -> Int32 {
    outNode?.pointee = 0
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    guard let inDescription else { return kAUGraphErr_InvalidAudioUnit }
    let node = ATAUGraphNode(node: graph.nextNode, description: inDescription.pointee)
    graph.nextNode += 1
    graph.nodes.append(node)
    outNode?.pointee = node.node
    return 0
}

@_cdecl("AUGraphRemoveNode")
public func AUGraphRemoveNode(_ inGraph: AUGraph?, _ inNode: AUNode) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    guard let index = graph.nodes.firstIndex(where: { $0.node == inNode }) else {
        return kAUGraphErr_NodeNotFound
    }
    if let unit = graph.nodes[index].unit {
        _ = AudioComponentInstanceDispose(unit)
    }
    graph.nodes.remove(at: index)
    graph.connections.removeAll { $0.sourceNode == inNode || $0.destNode == inNode }
    graph.inputCallbacks.removeAll { $0.destNode == inNode }
    return 0
}

public func AUGraphGetNodeCount(
    _ inGraph: AUGraph?,
    _ outNumberOfNodes: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outNumberOfNodes?.pointee = UInt32(graph.nodes.count)
    return 0
}

public func AUGraphGetIndNode(
    _ inGraph: AUGraph?,
    _ inIndex: UInt32,
    _ outNode: UnsafeMutablePointer<AUNode>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    if Int(inIndex) >= graph.nodes.count {
        return kAUGraphErr_NodeNotFound
    }
    outNode?.pointee = graph.nodes[Int(inIndex)].node
    return 0
}

public func AUGraphNodeInfo(
    _ inGraph: AUGraph?,
    _ inNode: AUNode,
    _ outDescription: UnsafeMutablePointer<AudioComponentDescription>?,
    _ outAudioUnit: UnsafeMutablePointer<AudioUnit?>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    guard let node = graph.nodes.first(where: { $0.node == inNode }) else {
        return kAUGraphErr_NodeNotFound
    }
    outDescription?.pointee = node.description
    outAudioUnit?.pointee = node.unit
    return 0
}

public func AUGraphConnectNodeInput(
    _ inGraph: AUGraph?,
    _ inSourceNode: AUNode,
    _ inSourceOutputNumber: UInt32,
    _ inDestNode: AUNode,
    _ inDestInputNumber: UInt32
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    if graph.nodes.first(where: { $0.node == inSourceNode }) == nil
        || graph.nodes.first(where: { $0.node == inDestNode }) == nil
    {
        return kAUGraphErr_NodeNotFound
    }
    graph.connections.removeAll {
        $0.destNode == inDestNode && $0.destInput == inDestInputNumber
    }
    graph.connections.append(
        ATAUGraphConnection(
            sourceNode: inSourceNode,
            sourceOutput: inSourceOutputNumber,
            destNode: inDestNode,
            destInput: inDestInputNumber
        )
    )
    return 0
}

@_cdecl("AUGraphDisconnectNodeInput")
public func AUGraphDisconnectNodeInput(
    _ inGraph: AUGraph?,
    _ inDestNode: AUNode,
    _ inDestInputNumber: UInt32
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.connections.removeAll { $0.destNode == inDestNode && $0.destInput == inDestInputNumber }
    graph.inputCallbacks.removeAll { $0.destNode == inDestNode && $0.destInput == inDestInputNumber }
    return 0
}

@_cdecl("AUGraphClearConnections")
public func AUGraphClearConnections(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.connections.removeAll()
    graph.inputCallbacks.removeAll()
    return 0
}

public func AUGraphSetNodeInputCallback(
    _ inGraph: AUGraph?,
    _ inDestNode: AUNode,
    _ inDestInputNumber: UInt32,
    _ inInputCallback: UnsafePointer<AURenderCallbackStruct>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    guard graph.nodes.contains(where: { $0.node == inDestNode }) else {
        return kAUGraphErr_NodeNotFound
    }
    guard let inInputCallback else { return kAUGraphErr_InvalidConnection }
    graph.inputCallbacks.removeAll { $0.destNode == inDestNode && $0.destInput == inDestInputNumber }
    graph.inputCallbacks.append(
        ATAUGraphInputCallback(
            destNode: inDestNode,
            destInput: inDestInputNumber,
            callback: inInputCallback.pointee
        )
    )
    return 0
}

@_cdecl("AUGraphInitialize")
public func AUGraphInitialize(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    if !graph.opened {
        graph.opened = true
    }
    for node in graph.nodes {
        if node.unit != nil { continue }
        var description = node.description
        let component = AudioComponentFindNext(nil, &description)
        var instance: AudioComponentInstance?
        let status = AudioComponentInstanceNew(component, &instance)
        if status != 0 {
            return kAUGraphErr_InvalidAudioUnit
        }
        node.unit = instance
        node.ownedUnit = ATRegistry.shared.lookup(instance, as: ATAudioUnitObject.self)
        if node.ownedUnit?.isRemoteIO == true {
            _ = AudioComponentInstanceDispose(instance)
            node.unit = nil
            return kAUGraphErr_OutputNodeErr
        }
        let initStatus = AudioUnitInitialize(instance)
        if initStatus != 0 {
            return kAUGraphErr_InvalidAudioUnit
        }
    }
    for connection in graph.connections {
        guard let destNode = graph.nodes.first(where: { $0.node == connection.destNode }),
              let sourceNode = graph.nodes.first(where: { $0.node == connection.sourceNode }),
              let destUnit = destNode.ownedUnit,
              let sourceHandle = sourceNode.unit
        else {
            return kAUGraphErr_InvalidConnection
        }
        destUnit.connections[connection.destInput] = ATUnitConnection(
            source: sourceHandle,
            sourceOutput: connection.sourceOutput
        )
    }
    for callback in graph.inputCallbacks {
        guard let destNode = graph.nodes.first(where: { $0.node == callback.destNode }),
              let destUnit = destNode.ownedUnit
        else {
            return kAUGraphErr_NodeNotFound
        }
        destUnit.inputCallbacks[callback.destInput] = callback.callback
    }
    graph.initialized = true
    return 0
}

@_cdecl("AUGraphUninitialize")
public func AUGraphUninitialize(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.running = false
    for node in graph.nodes {
        _ = AudioUnitUninitialize(node.unit)
    }
    graph.initialized = false
    return 0
}

@_cdecl("AUGraphStart")
public func AUGraphStart(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    if !graph.initialized {
        return kAUGraphErr_CannotDoInCurrentContext
    }
    graph.running = true
    return 0
}

@_cdecl("AUGraphStop")
public func AUGraphStop(_ inGraph: AUGraph?) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    graph.running = false
    return 0
}

public func AUGraphIsInitialized(
    _ inGraph: AUGraph?,
    _ outIsInitialized: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outIsInitialized?.pointee = graph.initialized ? 1 : 0
    return 0
}

public func AUGraphIsOpen(
    _ inGraph: AUGraph?,
    _ outIsOpen: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outIsOpen?.pointee = graph.opened ? 1 : 0
    return 0
}

public func AUGraphIsRunning(
    _ inGraph: AUGraph?,
    _ outIsRunning: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outIsRunning?.pointee = graph.running ? 1 : 0
    return 0
}

public func AUGraphUpdate(
    _ inGraph: AUGraph?,
    _ outIsUpdated: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outIsUpdated?.pointee = 1
    return 0
}

public func AUGraphGetNumberOfInteractions(
    _ inGraph: AUGraph?,
    _ outNumInteractions: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outNumInteractions?.pointee = UInt32(graph.connections.count + graph.inputCallbacks.count)
    return 0
}

public func AUGraphCountNodeInteractions(
    _ inGraph: AUGraph?,
    _ inNode: AUNode,
    _ outNumInteractions: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    let connections = graph.connections.filter { $0.sourceNode == inNode || $0.destNode == inNode }
    let callbacks = graph.inputCallbacks.filter { $0.destNode == inNode }
    outNumInteractions?.pointee = UInt32(connections.count + callbacks.count)
    return 0
}

public func AUGraphGetInteractionInfo(
    _ inGraph: AUGraph?,
    _ inInteractionIndex: UInt32,
    _ outInteraction: UnsafeMutablePointer<AUNodeInteraction>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    let index = Int(inInteractionIndex)
    if index < graph.connections.count {
        let connection = graph.connections[index]
        outInteraction?.pointee = AUNodeInteraction(
            nodeInteractionType: kAUNodeInteraction_Connection,
            sourceNode: connection.sourceNode,
            sourceOutputNumber: connection.sourceOutput,
            destNode: connection.destNode,
            destInputNumber: connection.destInput
        )
        return 0
    }
    let callbackIndex = index - graph.connections.count
    if callbackIndex < graph.inputCallbacks.count {
        let callback = graph.inputCallbacks[callbackIndex]
        outInteraction?.pointee = AUNodeInteraction(
            nodeInteractionType: kAUNodeInteraction_InputCallback,
            sourceNode: 0,
            sourceOutputNumber: 0,
            destNode: callback.destNode,
            destInputNumber: callback.destInput
        )
        return 0
    }
    return kAUGraphErr_InvalidConnection
}

public func AUGraphGetNodeInteractions(
    _ inGraph: AUGraph?,
    _ inNode: AUNode,
    _ ioNumInteractions: UnsafeMutablePointer<UInt32>?,
    _ outInteractions: UnsafeMutablePointer<AUNodeInteraction>?
) -> Int32 {
    guard let graph = ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) else {
        return kAUGraphErr_InvalidAudioUnit
    }
    var collected: [AUNodeInteraction] = []
    for connection in graph.connections where connection.sourceNode == inNode || connection.destNode == inNode {
        collected.append(
            AUNodeInteraction(
                nodeInteractionType: kAUNodeInteraction_Connection,
                sourceNode: connection.sourceNode,
                sourceOutputNumber: connection.sourceOutput,
                destNode: connection.destNode,
                destInputNumber: connection.destInput
            )
        )
    }
    for callback in graph.inputCallbacks where callback.destNode == inNode {
        collected.append(
            AUNodeInteraction(
                nodeInteractionType: kAUNodeInteraction_InputCallback,
                sourceNode: 0,
                sourceOutputNumber: 0,
                destNode: callback.destNode,
                destInputNumber: callback.destInput
            )
        )
    }
    let want = min(Int(ioNumInteractions?.pointee ?? UInt32(collected.count)), collected.count)
    if let outInteractions {
        for index in 0..<want {
            outInteractions.advanced(by: index).pointee = collected[index]
        }
    }
    ioNumInteractions?.pointee = UInt32(collected.count)
    return 0
}

public func AUGraphGetCPULoad(
    _ inGraph: AUGraph?,
    _ outAverageCPULoad: UnsafeMutablePointer<Float32>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outAverageCPULoad?.pointee = 0
    return 0
}

public func AUGraphGetMaxCPULoad(
    _ inGraph: AUGraph?,
    _ outMaxLoad: UnsafeMutablePointer<Float32>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
        return kAUGraphErr_InvalidAudioUnit
    }
    outMaxLoad?.pointee = 0
    return 0
}

public func AUGraphAddRenderNotify(
    _ inGraph: AUGraph?,
    _ inCallback: AURenderCallback?,
    _ inRefCon: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inCallback
    _ = inRefCon
    guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
        return kAUGraphErr_InvalidAudioUnit
    }
    return 0
}

public func AUGraphRemoveRenderNotify(
    _ inGraph: AUGraph?,
    _ inCallback: AURenderCallback?,
    _ inRefCon: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inCallback
    _ = inRefCon
    guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
        return kAUGraphErr_InvalidAudioUnit
    }
    return 0
}
