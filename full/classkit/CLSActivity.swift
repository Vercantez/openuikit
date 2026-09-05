import Foundation

/// A student interaction against a `CLSContext`.
///
/// Start/stop is a local state machine. `duration` accumulates wall time while
/// started. `progress` is clamped to `0...1`. Ranges union by taking
/// `max(progress, end)` after validating `0 <= start < end <= 1`.
open class CLSActivity: CLSObject {
    public var progress: Double {
        get { storedProgress }
        set {
            storedProgress = Self.clampProgress(newValue)
            touch()
        }
    }

    public var duration: TimeInterval {
        var total = accumulatedDuration
        if isStarted, let startedAt {
            total += Date().timeIntervalSince(startedAt)
        }
        return max(0, total)
    }

    public var primaryActivityItem: CLSActivityItem? {
        get { storedPrimary }
        set {
            storedPrimary = newValue
            touch()
        }
    }

    public private(set) var additionalActivityItems: [CLSActivityItem] = []

    public private(set) var isStarted: Bool = false

    weak var owningContext: CLSContext?
    private var storedProgress: Double = 0
    private var storedPrimary: CLSActivityItem?
    private var accumulatedDuration: TimeInterval = 0
    private var startedAt: Date?

    override init(portable: ()) {
        super.init(portable: ())
    }

    public required init?(coder: NSCoder) {
        storedProgress = coder.decodeDouble(forKey: "progress")
        accumulatedDuration = coder.decodeDouble(forKey: "duration")
        isStarted = coder.decodeBool(forKey: "started")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(storedProgress, forKey: "progress")
        coder.encode(duration, forKey: "duration")
        coder.encode(isStarted, forKey: "started")
    }

    public func addProgressRange(fromStart start: Double, toEnd end: Double) {
        guard start >= 0, end <= 1, start < end else { return }
        storedProgress = Self.clampProgress(max(storedProgress, end))
        touch()
    }

    public func addAdditionalActivityItem(_ activityItem: CLSActivityItem) {
        additionalActivityItems.append(activityItem)
        touch()
    }

    public func removeAllActivityItems() {
        storedPrimary = nil
        additionalActivityItems.removeAll()
        touch()
    }

    public func start() {
        guard !isStarted else { return }
        isStarted = true
        startedAt = Date()
        owningContext?.store?.runningActivity = self
        touch()
    }

    public func stop() {
        guard isStarted else { return }
        if let startedAt {
            accumulatedDuration += Date().timeIntervalSince(startedAt)
        }
        startedAt = nil
        isStarted = false
        if owningContext?.store?.runningActivity === self {
            owningContext?.store?.runningActivity = nil
        }
        touch()
    }

    private static func clampProgress(_ value: Double) -> Double {
        if value.isNaN { return 0 }
        return min(1, max(0, value))
    }
}

/// Abstract scored/measured item attached to an activity.
open class CLSActivityItem: CLSObject {
    public private(set) var identifier: String
    public var title: String {
        didSet { touch() }
    }

    init(itemIdentifier identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
        super.init(portable: ())
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
            let title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        else {
            return nil
        }
        self.identifier = identifier
        self.title = title
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(title as NSString, forKey: "title")
    }
}

/// Boolean activity outcome.
open class CLSBinaryItem: CLSActivityItem {
    public var value: Bool {
        didSet { touch() }
    }

    public private(set) var valueType: CLSBinaryValueType

    public init(identifier: String, title: String, type valueType: CLSBinaryValueType) {
        self.valueType = valueType
        self.value = false
        super.init(itemIdentifier: identifier, title: title)
    }

    public required init?(coder: NSCoder) {
        value = coder.decodeBool(forKey: "value")
        let raw = coder.decodeInteger(forKey: "valueType")
        valueType = CLSBinaryValueType(rawValue: raw) ?? .trueFalse
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(value, forKey: "value")
        coder.encode(valueType.rawValue, forKey: "valueType")
    }
}

/// Quantitative activity outcome.
open class CLSQuantityItem: CLSActivityItem {
    public var quantity: Double {
        didSet { touch() }
    }

    public init(identifier: String, title: String) {
        self.quantity = 0
        super.init(itemIdentifier: identifier, title: title)
    }

    public required init?(coder: NSCoder) {
        quantity = coder.decodeDouble(forKey: "quantity")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(quantity, forKey: "quantity")
    }
}

/// Score out of a maximum.
open class CLSScoreItem: CLSActivityItem {
    public var score: Double {
        didSet { touch() }
    }

    public var maxScore: Double {
        didSet { touch() }
    }

    public init(identifier: String, title: String, score: Double, maxScore: Double) {
        self.score = score
        self.maxScore = maxScore
        super.init(itemIdentifier: identifier, title: title)
    }

    public required init?(coder: NSCoder) {
        score = coder.decodeDouble(forKey: "score")
        maxScore = coder.decodeDouble(forKey: "maxScore")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(score, forKey: "score")
        coder.encode(maxScore, forKey: "maxScore")
    }
}
