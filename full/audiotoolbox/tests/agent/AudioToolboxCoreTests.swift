#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation
import AudioToolbox

private final class ATUncheckedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var failureCount = 0
    private var bufferCount = 0

    func addFailure() {
        lock.lock()
        failureCount += 1
        lock.unlock()
    }

    func addBuffer() {
        lock.lock()
        bufferCount += 1
        lock.unlock()
    }

    var failures: Int {
        lock.lock()
        defer { lock.unlock() }
        return failureCount
    }

    var buffers: Int {
        lock.lock()
        defer { lock.unlock() }
        return bufferCount
    }
}

private func atExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private final class ATLatch: @unchecked Sendable {
    private let condition = NSCondition()
    private var remaining: Int

    init(_ count: Int) {
        remaining = count
    }

    func arrive() {
        condition.lock()
        remaining -= 1
        if remaining <= 0 {
            condition.broadcast()
        }
        condition.unlock()
    }

    func wait() {
        condition.lock()
        while remaining > 0 {
            condition.wait()
        }
        condition.unlock()
    }
}

#if canImport(CoreFoundation)
private func atFileURL(_ path: String, isDirectory: Bool = false) -> CFURL {
    path.withCString { cstr in
        CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
            path.utf8.count,
            isDirectory
        )!
    }
}
#endif

private func atMakeFormatBlob() -> [UInt8] {
    // Isolated hosts lack CoreAudioTypes, so the overlay takes an opaque
    // format pointer. Size matches the C AudioStreamBasicDescription (40 bytes).
    [UInt8](repeating: 0, count: 40)
}

func testAudioComponentDescriptionLayout() {
    atExpect(MemoryLayout<AudioComponentDescription>.size == 20, "ACD size")
    atExpect(MemoryLayout<AudioComponentDescription>.stride == 20, "ACD stride")
    atExpect(MemoryLayout<AudioComponentDescription>.alignment == 4, "ACD align")
    var description = AudioComponentDescription(
        componentType: 0x6175_6F75,
        componentSubType: 0x7269_6F63,
        componentManufacturer: 0x6170_706C,
        componentFlags: AudioComponentFlags.isV3AudioUnit.rawValue,
        componentFlagsMask: 0
    )
    atExpect(description.componentType == 0x6175_6F75, "type field")
    atExpect(description.componentSubType == 0x7269_6F63, "subtype field")
    atExpect(description.componentManufacturer == 0x6170_706C, "mfr field")
    let copy = description
    atExpect(copy == description, "equatable")
    description.componentFlags = 0
    atExpect(copy != description, "mutation independence")
}

func testAudioComponentFlagsAndInstantiationOptions() {
    atExpect(AudioComponentFlags.unsearchable.rawValue == 1, "unsearchable")
    atExpect(AudioComponentFlags.sandboxSafe.rawValue == 2, "sandbox")
    atExpect(AudioComponentFlags.isV3AudioUnit.rawValue == 4, "v3")
    atExpect(AudioComponentFlags.requiresAsyncInstantiation.rawValue == 8, "async")
    atExpect(AudioComponentFlags.canLoadInProcess.rawValue == 16, "in-process")
    let combined: AudioComponentFlags = [.unsearchable, .sandboxSafe]
    atExpect(combined.contains(.unsearchable), "optionset contains")
    atExpect(AudioComponentInstantiationOptions.loadOutOfProcess.rawValue == 1, "oop")
    atExpect(
        AudioComponentInstantiationOptions.loadedRemotely.rawValue == (1 << 31),
        "loaded remotely"
    )
}

func testAudioComponentDiscoveryEmpty() {
    var description = AudioComponentDescription()
    description.componentType = kAudioUnitType_Output
    description.componentSubType = kAudioUnitSubType_RemoteIO
    description.componentManufacturer = kAudioUnitManufacturer_Apple
    let count = AudioComponentCount(&description)
    atExpect(count == 0, "no plugins registered")
    let next = AudioComponentFindNext(nil, &description)
    atExpect(next == nil, "find-next empty")
}

func testAudioComponentInstantiateFailClosedExactlyOnce() {
    var calls = 0
    var status: Int32 = 0
    var instance: AudioComponentInstance?
    AudioComponentInstantiate(nil, []) { received, receivedStatus in
        calls += 1
        instance = received
        status = receivedStatus
        AudioComponentInstantiate(nil, []) { _, _ in
            calls += 1
        }
    }
    atExpect(calls >= 2, "nested completion allowed")
    atExpect(calls < 32, "reentrancy bounded")
    atExpect(instance == nil, "no instance")
    atExpect(status == kAudioComponentErr_UnsupportedType, "unsupported plugin")
}

func testAudioComponentInstanceDisposeIdempotent() {
    let garbage = AudioComponentInstance(bitPattern: 0xDEAD_BEEF)
    atExpect(AudioComponentInstanceDispose(garbage) == 0, "unknown dispose")
    atExpect(AudioComponentInstanceDispose(garbage) == 0, "double dispose")
    atExpect(AudioComponentInstanceDispose(nil) == 0, "nil dispose")
    var created: AudioComponentInstance?
    atExpect(
        AudioComponentInstanceNew(garbage, &created) == kAudioComponentErr_UnsupportedType,
        "instantiate unknown component"
    )
    atExpect(created == nil, "out instance cleared")
}

func testAUAudioUnitInitFailClosed() {
    atExpect(AUAudioUnitBusType.input.rawValue == 1, "input bus")
    atExpect(AUAudioUnitBusType.output.rawValue == 2, "output bus")
    do {
        _ = try AUAudioUnit(componentDescription: AudioComponentDescription())
        fatalError("AUAudioUnit init must fail closed")
    } catch let error as NSError {
        atExpect(error.domain == NSOSStatusErrorDomain, "NSOSStatusErrorDomain")
        atExpect(
            error.code == Int(kAudioUnitErr_ComponentManagerNotSupported),
            "component manager unsupported"
        )
    } catch {
        fatalError("unexpected error type")
    }
}

func testAudioUnitHardwareStartFailClosed() {
    let garbage = AudioUnit(bitPattern: 0x11)
    atExpect(AudioUnitInitialize(garbage) == kAudioUnitErr_InvalidElement, "init unknown")
    atExpect(AudioOutputUnitStart(garbage) == kAudioUnitErr_FailedInitialization, "start")
    atExpect(AudioOutputUnitStop(garbage) == 0, "stop unknown is inert")
}

func testMIDINoteMessageLayout() {
    atExpect(MemoryLayout<MIDINoteMessage>.size == 8, "note size")
    atExpect(MemoryLayout<MIDINoteMessage>.stride == 8, "note stride")
    var message = MIDINoteMessage(
        channel: 1, note: 60, velocity: 100, releaseVelocity: 0, duration: 0.5
    )
    atExpect(message.note == 60, "note")
    atExpect(message.duration == 0.5, "duration")
    message.velocity = 1
    atExpect(message.velocity == 1, "velocity write")
}

func testMusicSequenceTrackLifecycle() {
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "new sequence")
    atExpect(sequence != nil, "sequence pointer")
    var count: UInt32 = 99
    atExpect(MusicSequenceGetTrackCount(sequence, &count) == 0, "count status")
    atExpect(count == 0, "user tracks start empty")
    var track: MusicTrack?
    atExpect(MusicSequenceNewTrack(sequence, &track) == 0, "new track")
    atExpect(MusicSequenceGetTrackCount(sequence, &count) == 0 && count == 1, "one track")
    var tempo: MusicTrack?
    atExpect(MusicSequenceGetTempoTrack(sequence, &tempo) == 0, "tempo track")
    atExpect(tempo != nil && tempo != track, "tempo is distinct")
    atExpect(MusicSequenceDisposeTrack(sequence, tempo) != 0, "cannot dispose tempo")
    atExpect(MusicSequenceDisposeTrack(sequence, track) == 0, "dispose user track")
    atExpect(MusicSequenceGetTrackCount(sequence, &count) == 0 && count == 0, "back to zero")
    atExpect(DisposeMusicSequence(sequence) == 0, "dispose sequence")
    atExpect(DisposeMusicSequence(sequence) == 0, "dispose idempotent")
}

func testMusicEventIteratorOrderAndSeek() {
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "seq")
    var track: MusicTrack?
    atExpect(MusicSequenceNewTrack(sequence, &track) == 0, "track")
    var noteA = MIDINoteMessage(channel: 0, note: 64, velocity: 80, releaseVelocity: 0, duration: 1)
    var noteB = MIDINoteMessage(channel: 0, note: 67, velocity: 80, releaseVelocity: 0, duration: 1)
    var noteC = MIDINoteMessage(channel: 0, note: 71, velocity: 80, releaseVelocity: 0, duration: 1)
    atExpect(MusicTrackNewMIDINoteEvent(track, 2.0, &noteA) == 0, "t2")
    atExpect(MusicTrackNewMIDINoteEvent(track, 0.0, &noteB) == 0, "t0")
    atExpect(MusicTrackNewMIDINoteEvent(track, 1.0, &noteC) == 0, "t1")
    var iterator: MusicEventIterator?
    atExpect(NewMusicEventIterator(track, &iterator) == 0, "iterator")
    var has: UInt8 = 0
    atExpect(MusicEventIteratorHasCurrentEvent(iterator, &has) == 0 && has == 1, "has current")
    var stamps: [MusicTimeStamp] = []
    var types: [MusicEventType] = []
    repeat {
        var time: MusicTimeStamp = -1
        var type: MusicEventType = 99
        var data: UnsafeRawPointer?
        var size: UInt32 = 0
        atExpect(MusicEventIteratorGetEventInfo(iterator, &time, &type, &data, &size) == 0, "info")
        atExpect(data != nil && size == UInt32(MemoryLayout<MIDINoteMessage>.size), "payload")
        stamps.append(time)
        types.append(type)
        let nextStatus = MusicEventIteratorNextEvent(iterator)
        _ = MusicEventIteratorHasCurrentEvent(iterator, &has)
        if nextStatus != 0 { break }
    } while has == 1
    atExpect(stamps == [0.0, 1.0, 2.0], "iterator time order")
    atExpect(types.allSatisfy { $0 == kMusicEventType_MIDINoteMessage }, "note types")
    atExpect(MusicEventIteratorSeek(iterator, 1.5) == 0, "seek")
    var time: MusicTimeStamp = 0
    var type: MusicEventType = 0
    var data: UnsafeRawPointer?
    var size: UInt32 = 0
    atExpect(MusicEventIteratorGetEventInfo(iterator, &time, &type, &data, &size) == 0, "seeked")
    atExpect(time == 2.0, "seek lands on next event")
    atExpect(DisposeMusicEventIterator(iterator) == 0, "dispose iterator")
    atExpect(DisposeMusicEventIterator(iterator) == 0, "iterator dispose idempotent")
    atExpect(DisposeMusicSequence(sequence) == 0, "dispose seq")
}

func testMusicEventIteratorEmptyAndDelete() {
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "seq")
    var track: MusicTrack?
    atExpect(MusicSequenceNewTrack(sequence, &track) == 0, "track")
    var iterator: MusicEventIterator?
    atExpect(NewMusicEventIterator(track, &iterator) == 0, "empty iterator")
    var has: UInt8 = 1
    atExpect(MusicEventIteratorHasCurrentEvent(iterator, &has) == 0 && has == 0, "empty")
    atExpect(MusicEventIteratorNextEvent(iterator) != 0, "next on empty fails")
    var note = MIDINoteMessage(channel: 0, note: 12, velocity: 1, releaseVelocity: 0, duration: 0.1)
    atExpect(MusicTrackNewMIDINoteEvent(track, 0, &note) == 0, "add")
    atExpect(DisposeMusicEventIterator(iterator) == 0, "drop stale")
    atExpect(NewMusicEventIterator(track, &iterator) == 0, "refresh")
    atExpect(MusicEventIteratorDeleteEvent(iterator) == 0, "delete")
    atExpect(MusicEventIteratorHasCurrentEvent(iterator, &has) == 0 && has == 0, "deleted")
    atExpect(DisposeMusicEventIterator(iterator) == 0, "dispose")
    atExpect(DisposeMusicSequence(sequence) == 0, "seq")
}

func testMusicSequenceConcurrentMutation() {
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "seq")
    let sequenceBits = UInt(bitPattern: sequence!)
    let box = ATUncheckedCounter()
    let latch = ATLatch(8)
    var threads: [Thread] = []
    threads.reserveCapacity(8)
    for _ in 0..<8 {
        let thread = Thread {
            let local = MusicSequence(bitPattern: sequenceBits)
            var track: MusicTrack?
            let status = MusicSequenceNewTrack(local, &track)
            if status != 0 || track == nil {
                box.addFailure()
            }
            latch.arrive()
        }
        threads.append(thread)
        thread.start()
    }
    latch.wait()
    _ = threads
    atExpect(box.failures == 0, "concurrent NewTrack")
    var count: UInt32 = 0
    atExpect(MusicSequenceGetTrackCount(sequence, &count) == 0, "count")
    atExpect(count == 8, "eight tracks")
    var first: MusicTrack?
    atExpect(MusicSequenceGetIndTrack(sequence, 0, &first) == 0 && first != nil, "ind track")
    atExpect(DisposeMusicSequence(sequence) == 0, "dispose")
}

func testMusicPlayerStartFailClosed() {
    var player: MusicPlayer?
    atExpect(NewMusicPlayer(&player) == 0, "player")
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "seq")
    atExpect(MusicPlayerSetSequence(player, sequence) == 0, "attach")
    atExpect(MusicPlayerStart(player) == kAudioUnitErr_FailedInitialization, "no device")
    var playing: UInt8 = 1
    atExpect(MusicPlayerIsPlaying(player, &playing) == 0 && playing == 0, "not playing")
    atExpect(MusicPlayerStop(player) == 0, "stop")
    atExpect(DisposeMusicPlayer(player) == 0, "dispose player")
    atExpect(DisposeMusicPlayer(player) == 0, "player idempotent")
    atExpect(DisposeMusicSequence(sequence) == 0, "seq")
}

func testMusicSequenceMalformedMIDILoad() {
#if canImport(CoreFoundation)
    var sequence: MusicSequence?
    atExpect(NewMusicSequence(&sequence) == 0, "seq")
    let empty = CFDataCreate(kCFAllocatorDefault, nil, 0)!
    atExpect(
        MusicSequenceFileLoadData(sequence, empty, .midiType, []) == kAudioFileInvalidFileError,
        "empty midi"
    )
    let bytes: [UInt8] = [0x00, 0x01, 0x02, 0x03]
    let junk = bytes.withUnsafeBufferPointer { buffer in
        CFDataCreate(kCFAllocatorDefault, buffer.baseAddress, buffer.count)!
    }
    atExpect(
        MusicSequenceFileLoadData(sequence, junk, .midiType, [])
            == kAudioFileUnsupportedFileTypeError,
        "malformed midi"
    )
    atExpect(DisposeMusicSequence(sequence) == 0, "seq")
#endif
}

func testAudioFileOpenMissingAndMalformed() {
#if canImport(CoreFoundation)
    let missingPath = "/tmp/openuikit-audiotoolbox-missing-\(UUID().uuidString).caf"
    let missing = atFileURL(missingPath)
    var file: AudioFileID?
    atExpect(
        AudioFileOpenURL(missing, .readPermission, 0, &file) == kAudioFileFileNotFoundError,
        "missing file"
    )
    atExpect(file == nil, "out file nil")
    var ext: ExtAudioFileRef?
    atExpect(
        ExtAudioFileOpenURL(missing, &ext) == kAudioFileFileNotFoundError,
        "ext missing"
    )
    let malformed = atFileURL("/", isDirectory: true)
    atExpect(
        AudioFileOpenURL(malformed, .readPermission, 0, &file) == kAudioFileInvalidFileError,
        "malformed root"
    )
    atExpect(AudioFileOpenURL(nil, .readPermission, 0, &file) == kAudioFileUnspecifiedError, "nil")
#endif
}

func testAudioFileExistingUnsupportedCodec() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-audiotoolbox-\(UUID().uuidString).txt")
    try! "not-an-audio-file".write(to: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: path) }
    let cfURL = atFileURL(path.path)
    var file: AudioFileID?
    atExpect(
        AudioFileOpenURL(cfURL, .readPermission, kAudioFileWAVEType, &file)
            == kAudioFileUnsupportedFileTypeError,
        "codec fail-closed"
    )
    var ext: ExtAudioFileRef?
    atExpect(
        ExtAudioFileOpenURL(cfURL, &ext) == kExtAudioFileError_InvalidDataFormat,
        "ext codec fail-closed"
    )
#endif
}

func testAudioFileCloseUnknownIdempotent() {
    let garbage = AudioFileID(bitPattern: 0xF00D)
    atExpect(AudioFileClose(garbage) == kAudioFileNotOpenError, "unknown close")
    atExpect(AudioFileClose(garbage) == kAudioFileNotOpenError, "repeat close")
    atExpect(ExtAudioFileDispose(garbage) == 0, "unknown ext dispose")
    atExpect(ExtAudioFileDispose(nil) == 0, "nil ext dispose")
}

func testAudioConverterUnknownDispose() {
    let garbage = AudioConverterRef(bitPattern: 0x0BAD)
    atExpect(AudioConverterDispose(garbage) == 0, "unknown converter dispose")
    atExpect(AudioConverterReset(garbage) == kAudioConverterErr_UnspecifiedError, "reset unknown")
}

func testAudioQueueBufferOwnershipZeroOneMany() {
    let format = atMakeFormatBlob()
    var queue: AudioQueueRef?
    let noCallback: AudioQueueOutputCallback? = nil
    atExpect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, noCallback, nil, nil, nil, 0, &queue)
        } == 0,
        "new queue object"
    )
    var zero: AudioQueueBufferRef?
    atExpect(
        AudioQueueAllocateBuffer(queue, 0, &zero) == kAudioQueueErr_InvalidParameter,
        "zero size rejected"
    )
    var one: AudioQueueBufferRef?
    atExpect(AudioQueueAllocateBuffer(queue, 64, &one) == 0, "one buffer")
    atExpect(one != nil, "one non-nil")
    atExpect(one!.pointee.mAudioDataBytesCapacity == 64, "capacity")
    atExpect(one!.pointee.mAudioDataByteSize == 0, "empty payload")
    var many: [AudioQueueBufferRef?] = Array(repeating: nil, count: 4)
    for index in 0..<many.count {
        atExpect(AudioQueueAllocateBuffer(queue, 32, &many[index]) == 0, "many \(index)")
    }
    atExpect(AudioQueueFreeBuffer(queue, one) == 0, "free one")
    atExpect(AudioQueueFreeBuffer(queue, one) == kAudioQueueErr_InvalidBuffer, "double free")
    for buffer in many {
        atExpect(AudioQueueFreeBuffer(queue, buffer) == 0, "free many")
    }
    atExpect(AudioQueueDispose(queue, true) == 0, "dispose queue")
    atExpect(AudioQueueDispose(queue, true) == 0, "queue dispose idempotent")
}

func testAudioQueueBufferOverflowAndAlias() {
    let format = atMakeFormatBlob()
    var queue: AudioQueueRef?
    let noCallback: AudioQueueOutputCallback? = nil
    atExpect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, noCallback, nil, nil, nil, 0, &queue)
        } == 0,
        "queue"
    )
    var overflow: AudioQueueBufferRef?
    atExpect(
        AudioQueueAllocateBuffer(queue, (1 << 24) + 1, &overflow) == kAudioQueueErr_InvalidParameter,
        "overflow rejected"
    )
    var buffer: AudioQueueBufferRef?
    atExpect(AudioQueueAllocateBuffer(queue, 16, &buffer) == 0, "alloc")
    buffer!.pointee.mAudioDataByteSize = 32
    atExpect(
        AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == kAudioQueueErr_InvalidParameter,
        "byte size overflow"
    )
    buffer!.pointee.mAudioDataByteSize = 8
    atExpect(
        AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == kAudioQueueErr_CannotStart,
        "enqueue without device"
    )
    atExpect(
        AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == kAudioQueueErr_BufferEnqueuedTwice,
        "alias enqueue"
    )
    atExpect(AudioQueueReset(queue) == 0, "reset clears enqueue")
    atExpect(AudioQueueFreeBuffer(queue, buffer) == 0, "free after reset")
    atExpect(AudioQueueDispose(queue, false) == 0, "dispose")
}

func testAudioQueueStartFailClosed() {
    let format = atMakeFormatBlob()
    var queue: AudioQueueRef?
    let noCallback: AudioQueueOutputCallback? = nil
    atExpect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, noCallback, nil, nil, nil, 0, &queue)
        } == 0,
        "queue"
    )
    atExpect(AudioQueueStart(queue, nil) == kAudioQueueErr_InvalidDevice, "no device")
    atExpect(AudioQueueStart(nil, nil) == kAudioQueueErr_QueueInvalidated, "nil queue")
    atExpect(AudioQueueDispose(queue, true) == 0, "dispose")
}

func testAudioQueueConcurrentAllocate() {
    let format = atMakeFormatBlob()
    var queue: AudioQueueRef?
    let noCallback: AudioQueueOutputCallback? = nil
    atExpect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, noCallback, nil, nil, nil, 0, &queue)
        } == 0,
        "queue"
    )
    let queueBits = UInt(bitPattern: queue!)
    let box = ATUncheckedCounter()
    let latch = ATLatch(6)
    var threads: [Thread] = []
    threads.reserveCapacity(6)
    for index in 0..<6 {
        let capturedIndex = index
        let thread = Thread {
            let local = AudioQueueRef(bitPattern: queueBits)
            var buffer: AudioQueueBufferRef?
            let status: Int32
            if capturedIndex == 0 {
                status = AudioQueueAllocateBufferWithPacketDescriptions(local, 24, 2, &buffer)
            } else {
                status = AudioQueueAllocateBuffer(local, 24, &buffer)
            }
            if status != 0 || buffer == nil {
                box.addFailure()
            } else {
                box.addBuffer()
            }
            latch.arrive()
        }
        threads.append(thread)
        thread.start()
    }
    latch.wait()
    _ = threads
    atExpect(box.failures == 0, "concurrent allocate")
    atExpect(box.buffers == 6, "six buffers")
    atExpect(AudioQueueDispose(queue, true) == 0, "dispose releases owners")
}

func testAudioServicesPlayDoesNotSucceedOrComplete() {
    atExpect(kSystemSoundID_Vibrate == 0x0FFF, "vibrate id")
    atExpect(
        UInt32(bitPattern: kAudioServicesUnsupportedPropertyError) == 0x7074_793F,
        "pty? FourCC, not portable -1501"
    )
    atExpect(kAudioServicesSystemSoundClientTimedOutError == -1501, "timed out stays -1501")
    AudioServicesCompletionProbe.reset()
    atExpect(
        AudioServicesAddSystemSoundCompletion(
            0x1111,
            nil,
            nil,
            AudioServicesCompletionProbe.cProc,
            nil
        ) == kAudioServicesNoError,
        "add completion"
    )
    AudioServicesPlaySystemSound(0x1111)
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    AudioServicesPlaySystemSoundWithCompletion(0x2222) {
        AudioServicesCompletionProbe.swiftBlockFired = true
    }
    atExpect(!AudioServicesCompletionProbe.fired, "C completion never runs")
    atExpect(!AudioServicesCompletionProbe.swiftBlockFired, "Swift completion never runs")
    AudioServicesRemoveSystemSoundCompletion(0x1111)
}

func testAudioServicesCreateAndPropertyFailClosed() {
#if canImport(CoreFoundation)
    let missingPath = "/tmp/openuikit-sound-missing-\(UUID().uuidString).aiff"
    let missing = atFileURL(missingPath)
    var sound: SystemSoundID = 99
    atExpect(
        AudioServicesCreateSystemSoundID(missing, &sound)
            == kAudioServicesSystemSoundUnspecifiedError,
        "create missing"
    )
    atExpect(sound == 0, "out id cleared")
    var size: UInt32 = 0
    var writable: UInt8 = 1
    atExpect(
        AudioServicesGetPropertyInfo(
            kAudioServicesPropertyIsUISound, 0, nil, &size, &writable
        ) == kAudioServicesUnsupportedPropertyError,
        "property unsupported"
    )
    atExpect(
        AudioServicesSetProperty(kAudioServicesPropertyIsUISound, 0, nil, 0, nil)
            == kAudioServicesUnsupportedPropertyError,
        "set unsupported"
    )
#endif
}

func testAudioServicesCompletionReentrancy() {
    AudioServicesCompletionProbe.reset()
    atExpect(
        AudioServicesAddSystemSoundCompletion(
            7, nil, nil, AudioServicesCompletionProbe.cProc, nil
        ) == 0,
        "first add"
    )
    atExpect(AudioServicesDisposeSystemSoundID(7) == kAudioServicesNoError, "dispose")
    atExpect(AudioServicesDisposeSystemSoundID(7) == kAudioServicesNoError, "dispose again")
}

func testUnknownPointerSafety() {
    let garbage = OpaquePointer(bitPattern: 0x1)!
    var out: MusicTrack?
    atExpect(MusicSequenceNewTrack(garbage, &out) == -50, "unknown sequence")
    atExpect(MusicTrackNewMIDIChannelEvent(garbage, 0, nil) == -50, "unknown channel event")
    atExpect(AudioQueueFreeBuffer(garbage, nil) == kAudioQueueErr_QueueInvalidated, "unknown q")
}

func testAUAudioUnitBusArrayRejectsCountChange() {
    let buses = AUAudioUnitBusArray()
    atExpect(buses.count == 0, "empty")
    atExpect(!buses.isCountChangeable, "not changeable")
    do {
        try buses.setBusCount(2)
        fatalError("setBusCount must fail")
    } catch {
        atExpect(true, "threw")
    }
    let bus = AUAudioUnitBus(busType: .output)
    atExpect(bus.busType == .output, "bus type")
    atExpect(!bus.isEnabled, "disabled")
}

private enum AudioServicesCompletionProbe {
    static var fired = false
    static var swiftBlockFired = false
    static let cProc: AudioServicesSystemSoundCompletionProc = { _, _ in
        fired = true
    }

    static func reset() {
        fired = false
        swiftBlockFired = false
    }
}
