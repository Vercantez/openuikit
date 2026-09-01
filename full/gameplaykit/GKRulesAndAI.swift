import Foundation

public protocol GKGameModelPlayer: NSObjectProtocol {
    var playerId: Int { get }
}

public protocol GKGameModelUpdate: NSObjectProtocol {
    var value: Int { get set }
}

public protocol GKGameModel: NSObjectProtocol, NSCopying {
    var players: [any GKGameModelPlayer]? { get }
    var activePlayer: (any GKGameModelPlayer)? { get }
    func setGameModel(_ gameModel: any GKGameModel)
    func gameModelUpdates(for player: any GKGameModelPlayer) -> [any GKGameModelUpdate]?
    func apply(_ gameModelUpdate: any GKGameModelUpdate)
    func score(for player: any GKGameModelPlayer) -> Int
    func isWin(for player: any GKGameModelPlayer) -> Bool
    func isLoss(for player: any GKGameModelPlayer) -> Bool
    func unapplyGameModelUpdate(_ gameModelUpdate: any GKGameModelUpdate)
}

public extension GKGameModel {
    func score(for player: any GKGameModelPlayer) -> Int { 0 }
    func isWin(for player: any GKGameModelPlayer) -> Bool { false }
    func isLoss(for player: any GKGameModelPlayer) -> Bool { false }
    func unapplyGameModelUpdate(_ gameModelUpdate: any GKGameModelUpdate) {}
}

public protocol GKStrategist: NSObjectProtocol {
    var gameModel: (any GKGameModel)? { get set }
    var randomSource: (any GKRandom)? { get set }
    func bestMoveForActivePlayer() -> (any GKGameModelUpdate)?
}

open class GKMinmaxStrategist: NSObject, GKStrategist {
    public var gameModel: (any GKGameModel)?
    public var randomSource: (any GKRandom)?
    public var maxLookAheadDepth: Int = 1

    public override init() {
        super.init()
    }

    open func bestMoveForActivePlayer() -> (any GKGameModelUpdate)? {
        guard let player = gameModel?.activePlayer else { return nil }
        return bestMove(for: player)
    }

    open func bestMove(for player: any GKGameModelPlayer) -> (any GKGameModelUpdate)? {
        randomMove(for: player, fromNumberOfBestMoves: 1)
    }

    open func randomMove(for player: any GKGameModelPlayer, fromNumberOfBestMoves numMovesToConsider: Int) -> (any GKGameModelUpdate)? {
        guard let model = gameModel else { return nil }
        guard let updates = model.gameModelUpdates(for: player), !updates.isEmpty else { return nil }
        let depth = max(maxLookAheadDepth, 1)
        var scored: [(any GKGameModelUpdate, Int)] = []
        for update in updates {
            guard let copy = model.copy() as? GKGameModel else { continue }
            copy.setGameModel(model)
            copy.apply(update)
            let score = minimax(copy, player: player, depth: depth - 1, maximizing: false)
            update.value = score
            scored.append((update, score))
        }
        scored.sort { $0.1 > $1.1 }
        let consider = max(min(numMovesToConsider, scored.count), 1)
        let index = randomSource?.nextInt(upperBound: consider) ?? 0
        return scored[min(index, scored.count - 1)].0
    }

    private func minimax(_ model: any GKGameModel, player: any GKGameModelPlayer, depth: Int, maximizing: Bool) -> Int {
        if model.isWin(for: player) { return GKGameModelMaxScore }
        if model.isLoss(for: player) { return GKGameModelMinScore }
        if depth <= 0 {
            return model.score(for: player)
        }
        guard let active = model.activePlayer,
              let updates = model.gameModelUpdates(for: active), !updates.isEmpty else {
            return model.score(for: player)
        }
        if maximizing {
            var best = GKGameModelMinScore
            for update in updates {
                guard let copy = model.copy() as? GKGameModel else { continue }
                copy.setGameModel(model)
                copy.apply(update)
                best = max(best, minimax(copy, player: player, depth: depth - 1, maximizing: false))
            }
            return best
        }
        var best = GKGameModelMaxScore
        for update in updates {
            guard let copy = model.copy() as? GKGameModel else { continue }
            copy.setGameModel(model)
            copy.apply(update)
            best = min(best, minimax(copy, player: player, depth: depth - 1, maximizing: true))
        }
        return best
    }
}

open class GKMonteCarloStrategist: NSObject, GKStrategist {
    public var gameModel: (any GKGameModel)?
    public var randomSource: (any GKRandom)?
    public var budget: Int = 16
    public var explorationParameter: Int = 2

    public override init() {
        super.init()
    }

    open func bestMoveForActivePlayer() -> (any GKGameModelUpdate)? {
        guard let model = gameModel, let player = model.activePlayer else { return nil }
        guard let updates = model.gameModelUpdates(for: player), !updates.isEmpty else { return nil }
        var wins = Array(repeating: 0, count: updates.count)
        var visits = Array(repeating: 0, count: updates.count)
        let rounds = max(budget, 1)
        for round in 0..<rounds {
            let index: Int
            if visits.contains(0) {
                index = visits.firstIndex(of: 0) ?? 0
            } else {
                var bestScore = -Double.greatestFiniteMagnitude
                var bestIndex = 0
                for i in 0..<updates.count {
                    let exploit = Double(wins[i]) / Double(max(visits[i], 1))
                    let explore = Double(explorationParameter) * (log(Double(round + 1)) / Double(visits[i])).squareRoot()
                    let score = exploit + explore
                    if score > bestScore {
                        bestScore = score
                        bestIndex = i
                    }
                }
                index = bestIndex
            }
            guard let copy = model.copy() as? GKGameModel else { continue }
            copy.setGameModel(model)
            copy.apply(updates[index])
            let result = playout(copy, player: player)
            visits[index] += 1
            wins[index] += result
        }
        var bestIndex = 0
        for i in 1..<updates.count {
            if visits[i] > visits[bestIndex] {
                bestIndex = i
            }
        }
        return updates[bestIndex]
    }

    private func playout(_ model: any GKGameModel, player: any GKGameModelPlayer) -> Int {
        var steps = 0
        while steps < 32 {
            if model.isWin(for: player) { return 1 }
            if model.isLoss(for: player) { return 0 }
            guard let active = model.activePlayer,
                  let updates = model.gameModelUpdates(for: active), !updates.isEmpty else {
                break
            }
            let pick = randomSource?.nextInt(upperBound: updates.count) ?? 0
            model.apply(updates[min(pick, updates.count - 1)])
            steps += 1
        }
        return model.score(for: player) > 0 ? 1 : 0
    }
}

open class GKRule: NSObject {
    public var salience: Int = 0
    var predicateBlock: ((GKRuleSystem) -> Bool)?
    var actionBlock: ((GKRuleSystem) -> Void)?
    var assertFact: (any NSObjectProtocol)?
    var retractFact: (any NSObjectProtocol)?
    var grade: Float = 1
    var storedPredicate: NSPredicate?

    public override init() {
        super.init()
    }

    public convenience init(blockPredicate predicate: @escaping (GKRuleSystem) -> Bool, action: @escaping (GKRuleSystem) -> Void) {
        self.init()
        self.predicateBlock = predicate
        self.actionBlock = action
    }

    public convenience init(predicate: NSPredicate, assertingFact fact: any NSObjectProtocol, grade: Float) {
        self.init()
        self.storedPredicate = predicate
        self.assertFact = fact
        self.grade = grade
    }

    public convenience init(predicate: NSPredicate, retractingFact fact: any NSObjectProtocol, grade: Float) {
        self.init()
        self.storedPredicate = predicate
        self.retractFact = fact
        self.grade = grade
    }

    open func evaluatePredicate(in system: GKRuleSystem) -> Bool {
        if let predicateBlock {
            return predicateBlock(system)
        }
        if let storedPredicate {
            return storedPredicate.evaluate(with: system.state)
        }
        return false
    }

    open func performAction(in system: GKRuleSystem) {
        if let actionBlock {
            actionBlock(system)
            return
        }
        if let assertFact {
            system.assertFact(assertFact, grade: grade)
        }
        if let retractFact {
            system.retractFact(retractFact, grade: grade)
        }
    }
}

open class GKNSPredicateRule: GKRule {
    public var predicate: NSPredicate {
        storedPredicate ?? NSPredicate(value: false)
    }

    public init(predicate: NSPredicate) {
        super.init()
        self.storedPredicate = predicate
    }

    open override func evaluatePredicate(in system: GKRuleSystem) -> Bool {
        predicate.evaluate(with: system.state)
    }
}

open class GKRuleSystem: NSObject {
    public let state: NSMutableDictionary = NSMutableDictionary()
    private var ruleStorage: [GKRule] = []
    private var agendaStorage: [GKRule] = []
    private var executedStorage: [GKRule] = []
    private var factGrades: [ObjectIdentifier: (any NSObjectProtocol, Float)] = [:]

    public var rules: [GKRule] { ruleStorage }
    public var agenda: [GKRule] { agendaStorage }
    public var executed: [GKRule] { executedStorage }
    public var facts: [Any] { factGrades.values.map { $0.0 } }

    public override init() {
        super.init()
    }

    open func add(_ rule: GKRule) {
        ruleStorage.append(rule)
    }

    open func add(_ rules: [GKRule]) {
        ruleStorage.append(contentsOf: rules)
    }

    open func removeAllRules() {
        ruleStorage.removeAll()
        agendaStorage.removeAll()
        executedStorage.removeAll()
    }

    open func evaluate() {
        agendaStorage = ruleStorage.sorted { $0.salience > $1.salience }
        executedStorage.removeAll()
        for rule in agendaStorage where rule.evaluatePredicate(in: self) {
            rule.performAction(in: self)
            executedStorage.append(rule)
        }
    }

    open func reset() {
        factGrades.removeAll()
        executedStorage.removeAll()
        agendaStorage.removeAll()
        state.removeAllObjects()
    }

    open func assertFact(_ fact: any NSObjectProtocol) {
        assertFact(fact, grade: 1)
    }

    open func assertFact(_ fact: any NSObjectProtocol, grade: Float) {
        let id = ObjectIdentifier(fact as AnyObject)
        let current = factGrades[id]?.1 ?? 0
        factGrades[id] = (fact, gkClamp(current + grade, 0, 1))
    }

    open func retractFact(_ fact: any NSObjectProtocol) {
        retractFact(fact, grade: 1)
    }

    open func retractFact(_ fact: any NSObjectProtocol, grade: Float) {
        let id = ObjectIdentifier(fact as AnyObject)
        let current = factGrades[id]?.1 ?? 0
        let next = current - grade
        if next <= 0 {
            factGrades.removeValue(forKey: id)
        } else {
            factGrades[id] = (fact, next)
        }
    }

    open func grade(forFact fact: any NSObjectProtocol) -> Float {
        factGrades[ObjectIdentifier(fact as AnyObject)]?.1 ?? 0
    }

    open func maximumGrade(forFacts facts: [Any]) -> Float {
        facts.compactMap { $0 as? NSObjectProtocol }.map { grade(forFact: $0) }.max() ?? 0
    }

    open func minimumGrade(forFacts facts: [Any]) -> Float {
        let grades = facts.compactMap { $0 as? NSObjectProtocol }.map { grade(forFact: $0) }
        return grades.min() ?? 0
    }
}

final class GKDecisionBranch {
    enum Kind {
        case value(NSNumber)
        case predicate(NSPredicate)
        case weight(Int)
    }

    let kind: Kind
    let attribute: any NSObjectProtocol
    let child: GKDecisionNode

    init(kind: Kind, attribute: any NSObjectProtocol, child: GKDecisionNode) {
        self.kind = kind
        self.attribute = attribute
        self.child = child
    }
}

open class GKDecisionNode: NSObject {
    public let attribute: any NSObjectProtocol
    var branches: [GKDecisionBranch] = []

    public required init(attribute: any NSObjectProtocol) {
        self.attribute = attribute
        super.init()
    }

    @discardableResult
    open func createBranch(predicate: NSPredicate, attribute: any NSObjectProtocol) -> Self {
        let child = Self(attribute: attribute)
        branches.append(GKDecisionBranch(kind: .predicate(predicate), attribute: attribute, child: child))
        return child
    }

    @discardableResult
    open func createBranch(value: NSNumber, attribute: any NSObjectProtocol) -> Self {
        let child = Self(attribute: attribute)
        branches.append(GKDecisionBranch(kind: .value(value), attribute: attribute, child: child))
        return child
    }

    @discardableResult
    open func createBranch(weight: Int, attribute: any NSObjectProtocol) -> Self {
        let child = Self(attribute: attribute)
        branches.append(GKDecisionBranch(kind: .weight(weight), attribute: attribute, child: child))
        return child
    }
}

open class GKDecisionTree: NSObject {
    public var randomSource: GKRandomSource = GKARC4RandomSource()
    public private(set) var rootNode: GKDecisionNode?

    public init(attribute: any NSObjectProtocol) {
        self.rootNode = GKDecisionNode(attribute: attribute)
        super.init()
    }

    public init(examples: [[any NSObjectProtocol]], actions: [any NSObjectProtocol], attributes: [any NSObjectProtocol]) {
        super.init()
        if let first = attributes.first {
            let root = GKDecisionNode(attribute: first)
            let exampleCount = examples.count
            for (index, action) in actions.enumerated() {
                let weight = index < exampleCount ? max(exampleCount - index, 1) : 1
                _ = root.createBranch(weight: weight, attribute: action)
            }
            self.rootNode = root
        }
    }

    public init(url: URL, error: (any Error)?) {
        self.rootNode = GKDecisionNode(attribute: NSString(string: "unreadable"))
        super.init()
    }

    public init(URL url: URL, error: (any Error)?) {
        self.rootNode = GKDecisionNode(attribute: NSString(string: "unreadable"))
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        return nil
    }

    open func findAction(forAnswers answers: [AnyHashable: any NSObjectProtocol]) -> (any NSObjectProtocol)? {
        guard var node = rootNode else { return nil }
        var guardCount = 0
        while guardCount < 64 {
            if node.branches.isEmpty {
                return node.attribute
            }
            var next: GKDecisionNode?
            for branch in node.branches {
                switch branch.kind {
                case .value(let number):
                    if let key = node.attribute as? AnyHashable,
                       let answer = answers[key] as? NSNumber,
                       answer == number {
                        next = branch.child
                    }
                case .predicate(let predicate):
                    if predicate.evaluate(with: answers as NSDictionary) {
                        next = branch.child
                    }
                case .weight:
                    continue
                }
                if next != nil { break }
            }
            if next == nil {
                let weighted = node.branches.filter {
                    if case .weight = $0.kind { return true }
                    return false
                }
                if weighted.isEmpty {
                    return node.attribute
                }
                let total = weighted.reduce(0) { sum, branch in
                    if case .weight(let w) = branch.kind { return sum + max(w, 0) }
                    return sum
                }
                var pick = randomSource.nextInt(upperBound: max(total, 1))
                for branch in weighted {
                    if case .weight(let w) = branch.kind {
                        pick -= max(w, 0)
                        if pick < 0 {
                            next = branch.child
                            break
                        }
                    }
                }
                next = next ?? weighted.last?.child
            }
            guard let following = next else { return node.attribute }
            node = following
            guardCount += 1
        }
        return node.attribute
    }

    open func export(to url: URL, error: (any Error)?) -> Bool {
        false
    }
}
