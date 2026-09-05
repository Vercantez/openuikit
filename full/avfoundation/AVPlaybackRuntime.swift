import Dispatch
import Foundation

/// Monotonic seconds from `DispatchTime` uptime.
/// Drives AVPlayer / AVAudioPlayer clocks. Linux has no audio/video hardware.
enum AVMonotonicClock {
    static func seconds() -> Double {
        Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
    }
}

enum AVTimeMath {
    static func seconds(of time: CMTime) -> Double {
        time.seconds
    }

    static func time(seconds: Double, timescale: CMTimeScale = 600) -> CMTime {
        let scale = timescale == 0 ? 600 : timescale
        return CMTime(seconds: seconds, preferredTimescale: scale)
    }
}

/// Box a `CMTime` inside an `NSValue` identity for `addBoundaryTimeObserver`.
public enum AVCMTimeValue {
    private static let lock = NSLock()
    private static var table: [ObjectIdentifier: CMTime] = [:]

    public static func nsValue(for time: CMTime) -> NSValue {
        let value = NSNumber(value: AVTimeMath.seconds(of: time))
        lock.lock()
        table[ObjectIdentifier(value)] = time
        lock.unlock()
        return value
    }

    static func time(from value: NSValue) -> CMTime {
        lock.lock()
        let boxed = table[ObjectIdentifier(value)]
        lock.unlock()
        if let boxed { return boxed }
#if canImport(CoreMedia)
        return value.timeValue
#else
        return .invalid
#endif
    }
}

func avTime(from value: NSValue) -> CMTime {
    AVCMTimeValue.time(from: value)
}

final class AVPlayerTimeObserverToken: NSObject, @unchecked Sendable {
    enum Kind {
        case periodic(interval: CMTime, block: (CMTime) -> Void)
        case boundary(times: [CMTime], block: () -> Void)
    }

    let kind: Kind
    let queue: DispatchQueue
    var lastPeriodicFire: Double = 0
    var firedBoundaries: Set<Int> = []

    init(kind: Kind, queue: DispatchQueue) {
        self.kind = kind
        self.queue = queue
    }
}

final class AVPlaybackEngine: @unchecked Sendable {
    let lock = NSLock()
    var item: AVPlayerItem?
    var rate: Float = 0
    var defaultRate: Float = 1
    var volume: Float = 1
    var mediaTime: CMTime = .zero
    var mediaSeconds: Double = 0
    var wallAnchor: Double?
    var muted = false
    var preventsDisplaySleep = true
    var backgroundPolicy = AVPlayerAudiovisualBackgroundPlaybackPolicy.automatic
    var actionAtItemEnd = AVPlayer.ActionAtItemEnd.advance
    // Apple default is true (`AVPlayer.automaticallyWaitsToMinimizeStalling`).
    var automaticallyWaitsToMinimizeStalling = true
    var allowsExternalPlayback = false
    var usesExternalPlaybackWhileExternalScreenIsActive = false
    var externalPlaybackVideoGravity = AVLayerVideoGravity.resizeAspect
    // Apple default is true (`AVPlayer.appliesMediaSelectionCriteriaAutomatically`).
    var appliesMediaSelectionCriteriaAutomatically = true
    var networkResourcePriority = AVPlayer.NetworkResourcePriority.default
    var closedCaptionDisplayEnabled = false
    var sourceClock: CMClock?
    var masterClock: CMClock?
    var videoOutput: AVPlayerVideoOutput?
    var mediaSelection: [String: AVPlayerMediaSelectionCriteria] = [:]
    var observers: [ObjectIdentifier: AVPlayerTimeObserverToken] = [:]
    var didEnd = false
    let pulseQueue = DispatchQueue(label: "AVFoundation.AVPlayer.clock")
    var pulse: DispatchSourceTimer?
    weak var owner: AVPlayer?

    func currentSeconds() -> Double {
        if let wallAnchor, rate != 0 {
            return mediaSeconds + (AVMonotonicClock.seconds() - wallAnchor) * Double(rate)
        }
        return mediaSeconds
    }

    func currentTime() -> CMTime {
        // Paused seek keeps the caller's CMTime identity (timescale + value).
        // Measured testPlayerPlayPauseAndSeek: CMTime(value: 1, timescale: 2)
        // round-trips while rate == 0. Playing reconstructs from elapsed
        // uptime at the seek's timescale (pulse 20 ms, DispatchTime).
        let scale: CMTimeScale = mediaTime.timescale == 0 ? 600 : mediaTime.timescale
        if rate == 0 || wallAnchor == nil {
            return mediaTime
        }
        return AVTimeMath.time(seconds: currentSeconds(), timescale: scale)
    }

    func commitTime() {
        mediaSeconds = currentSeconds()
        mediaTime = currentTime()
        wallAnchor = rate == 0 ? nil : AVMonotonicClock.seconds()
    }

    func setRate(_ newRate: Float) {
        commitTime()
        rate = newRate
        wallAnchor = newRate == 0 ? nil : AVMonotonicClock.seconds()
        if newRate != 0 {
            didEnd = false
        }
        ensurePulse()
    }

    func seek(to time: CMTime) -> Bool {
        guard time.isValid else { return false }
        mediaTime = time
        mediaSeconds = max(0, AVTimeMath.seconds(of: time))
        wallAnchor = rate == 0 ? nil : AVMonotonicClock.seconds()
        didEnd = false
        item?._portableSetCurrentTime(time)
        resetBoundaryFires()
        return true
    }

    func resetBoundaryFires() {
        for token in observers.values {
            token.firedBoundaries.removeAll()
            token.lastPeriodicFire = currentSeconds()
        }
    }

    func durationSeconds() -> Double? {
        if let injected = item?._portableDurationSeconds() {
            return injected
        }
        let duration = item?.duration ?? .invalid
        guard duration.isValid else { return nil }
        let seconds = AVTimeMath.seconds(of: duration)
        return seconds > 0 ? seconds : nil
    }

    func timeControlStatus() -> AVPlayer.TimeControlStatus {
        rate == 0 ? .paused : .playing
    }

    func status() -> AVPlayer.Status {
        item == nil ? .unknown : .readyToPlay
    }

    func ensurePulse() {
        if pulse != nil { return }
        let timer = DispatchSource.makeTimerSource(queue: pulseQueue)
        timer.schedule(deadline: .now(), repeating: 0.02)
        timer.setEventHandler { [weak self] in
            self?.pulseTick()
        }
        pulse = timer
        timer.resume()
    }

    func pulseTick() {
        lock.lock()
        let observers = Array(self.observers.values)
        let now = currentSeconds()
        let current = currentTime()
        let duration = durationSeconds()
        let playing = rate != 0
        let owner = self.owner
        let item = self.item
        let action = actionAtItemEnd
        var shouldEnd = false
        if playing, let duration, now >= duration, !didEnd {
            didEnd = true
            mediaSeconds = duration
            rate = 0
            wallAnchor = nil
            shouldEnd = true
        }
        lock.unlock()

        if shouldEnd, let item {
            NotificationCenter.default.post(
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )
            NotificationCenter.default.post(
                name: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )
            if action == .advance, let queue = owner as? AVQueuePlayer {
                DispatchQueue.global().async {
                    queue.advanceToNextItem()
                }
            }
        }

        for token in observers {
            switch token.kind {
            case .periodic(let interval, let block):
                let step = max(AVTimeMath.seconds(of: interval), 0.001)
                if now - token.lastPeriodicFire + 1e-9 >= step {
                    token.lastPeriodicFire = now
                    token.queue.async { block(current) }
                }
            case .boundary(let times, let block):
                for (index, boundary) in times.enumerated() {
                    guard boundary.isValid else { continue }
                    let boundarySeconds = AVTimeMath.seconds(of: boundary)
                    if now + 1e-9 >= boundarySeconds, !token.firedBoundaries.contains(index) {
                        token.firedBoundaries.insert(index)
                        token.queue.async { block() }
                    }
                }
            }
        }
    }

    deinit {
        pulse?.cancel()
    }
}

final class AVAssetLoadState: @unchecked Sendable {
    let lock = NSLock()
    var loadedKeys: Set<String> = []
    var injectedDuration: Double?

    func markLoaded(_ keys: [String]) {
        lock.lock()
        loadedKeys.formUnion(keys)
        lock.unlock()
    }

    func isLoaded(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return loadedKeys.contains(key)
    }
}

extension AVAsset {
    public func status<T>(
        of property: AVAsyncProperty<AVAsset, T>
    ) -> AVAsyncProperty<AVAsset, T>.Status {
        if loadState.isLoaded(property.portableKey) || property.portableKey.isEmpty {
            if let value: T = portableValue(forKey: property.portableKey) {
                return .loaded(value)
            }
        }
        return .notYetLoaded
    }

    public func statusOfValue(
        forKey key: String,
        error outError: UnsafeMutablePointer<NSError?>?
    ) -> AVKeyValueStatus {
        outError?.pointee = nil
        return loadState.isLoaded(key) ? .loaded : .unknown
    }

    public func loadValuesAsynchronously(
        forKeys keys: [String],
        completionHandler handler: (() -> Void)?
    ) {
        loadState.markLoaded(keys)
        handler?()
    }

    public func loadValues(forKeys keys: [String]) async {
        loadState.markLoaded(keys)
    }

    public func load<Root: AVAsset, T>(
        _ property: AVAsyncProperty<Root, T>,
        isolation: (any Actor)? = nil
    ) async throws -> T {
        _ = isolation
        loadState.markLoaded([property.portableKey])
        if let value: T = portableValue(forKey: property.portableKey) {
            return value
        }
        throw AVFoundationPortableError.mediaServiceUnavailable
    }

    public func load<Root: AVAsset, A, B>(
        _ firstProperty: AVAsyncProperty<Root, A>,
        _ secondProperty: AVAsyncProperty<Root, B>,
        isolation: (any Actor)? = nil
    ) async throws -> (A, B) {
        let first = try await load(firstProperty, isolation: isolation)
        let second = try await load(secondProperty, isolation: isolation)
        return (first, second)
    }

    public func load<Root: AVAsset, A, B, C>(
        _ firstProperty: AVAsyncProperty<Root, A>,
        _ secondProperty: AVAsyncProperty<Root, B>,
        _ thirdProperty: AVAsyncProperty<Root, C>,
        isolation: (any Actor)? = nil
    ) async throws -> (A, B, C) {
        let first = try await load(firstProperty, isolation: isolation)
        let second = try await load(secondProperty, isolation: isolation)
        let third = try await load(thirdProperty, isolation: isolation)
        return (first, second, third)
    }

    func portableValue<T>(forKey key: String) -> T? {
        switch key {
        case "duration":
            return duration as? T
        case "tracks":
            return tracks as? T
        case "isPlayable", "isExportable", "isReadable", "isComposable":
            return false as? T
        case "metadata", "commonMetadata":
            return ([] as [AVMetadataItem]) as? T
        case "lyrics":
            return (nil as String?) as? T
        default:
            return nil
        }
    }
}
