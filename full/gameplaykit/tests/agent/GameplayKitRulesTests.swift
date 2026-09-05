import Foundation
import GameplayKit

private final class ProbePlayer: NSObject, GKGameModelPlayer {
    let playerId: Int
    init(id: Int) { self.playerId = id }
}

private final class ProbeUpdate: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let delta: Int
    init(delta: Int) { self.delta = delta }
}

private final class ProbeModel: NSObject, GKGameModel {
    var players: [any GKGameModelPlayer]?
    var activePlayer: (any GKGameModelPlayer)?
    var scoreValue: Int

    init(score: Int, player: ProbePlayer) {
        self.scoreValue = score
        self.players = [player]
        self.activePlayer = player
    }

    func copy(with zone: NSZone? = nil) -> Any {
        ProbeModel(score: scoreValue, player: players?.first as! ProbePlayer)
    }

    func setGameModel(_ gameModel: any GKGameModel) {
        if let other = gameModel as? ProbeModel {
            scoreValue = other.scoreValue
        }
    }

    func gameModelUpdates(for player: any GKGameModelPlayer) -> [any GKGameModelUpdate]? {
        _ = player
        return [ProbeUpdate(delta: 4), ProbeUpdate(delta: -1)]
    }

    func apply(_ gameModelUpdate: any GKGameModelUpdate) {
        if let update = gameModelUpdate as? ProbeUpdate {
            scoreValue += update.delta
        }
    }

    func score(for player: any GKGameModelPlayer) -> Int {
        _ = player
        return scoreValue
    }

    func isWin(for player: any GKGameModelPlayer) -> Bool {
        _ = player
        return scoreValue >= 10
    }

    func isLoss(for player: any GKGameModelPlayer) -> Bool {
        _ = player
        return scoreValue < -10
    }

    func unapplyGameModelUpdate(_ gameModelUpdate: any GKGameModelUpdate) {
        if let update = gameModelUpdate as? ProbeUpdate {
            scoreValue -= update.delta
        }
    }
}

func testRuleSystemFactsAndAgenda() {
    let rules = GKRuleSystem()
    let fact = "ready" as NSString
    let other = "done" as NSString
    let rule = GKRule(blockPredicate: { _ in true }, action: { system in
        system.assertFact(fact)
    })
    rule.salience = 10
    precondition(rule.salience == 10)
    rules.add(rule)
    let extra = GKRule(blockPredicate: { _ in false }, action: { _ in })
    rules.add([extra])
    precondition(rules.rules.count == 2)
    rules.evaluate()
    precondition(rules.grade(forFact: fact) == 1)
    precondition(rules.facts.count == 1)
    precondition(rules.executed.count == 1)
    precondition(rules.agenda.count == 2)
    rules.assertFact(other, grade: 0.4)
    precondition(rules.grade(forFact: other) == 0.4)
    rules.retractFact(other, grade: 0.2)
    precondition(rules.grade(forFact: other) > 0)
    rules.retractFact(other)
    precondition(rules.maximumGrade(forFacts: [fact, other]) == 1)
    precondition(rules.minimumGrade(forFacts: [fact]) == 1)
    _ = rules.state
    rules.reset()
    precondition(rules.grade(forFact: fact) == 0)
    rules.removeAllRules()
    precondition(rules.rules.isEmpty)
}

func testNSPredicateRuleAndPredicateFactories() {
    let always = NSPredicate(value: true)
    let never = NSPredicate(value: false)
    let system = GKRuleSystem()
    let fact = "ok" as NSString
    let asserting = GKRule(predicate: always, assertingFact: fact, grade: 1)
    precondition(asserting.evaluatePredicate(in: system))
    asserting.performAction(in: system)
    precondition(system.grade(forFact: fact) == 1)
    let retracting = GKRule(predicate: always, retractingFact: fact, grade: 1)
    retracting.performAction(in: system)
    let predicateRule = GKNSPredicateRule(predicate: always)
    precondition(predicateRule.predicate == always)
    precondition(predicateRule.evaluatePredicate(in: system))
    let blocked = GKNSPredicateRule(predicate: never)
    precondition(!blocked.evaluatePredicate(in: system))
}

func testMinmaxAndMonteCarloStrategists() {
    let player = ProbePlayer(id: 1)
    let model = ProbeModel(score: 0, player: player)
    let minmax = GKMinmaxStrategist()
    minmax.gameModel = model
    minmax.maxLookAheadDepth = 2
    minmax.randomSource = GKARC4RandomSource(seed: Data([4]))
    precondition(minmax.maxLookAheadDepth == 2)
    let best = minmax.bestMove(for: player)
    precondition(best != nil)
    let random = minmax.randomMove(for: player, fromNumberOfBestMoves: 2)
    precondition(random != nil)
    let active = minmax.bestMoveForActivePlayer()
    precondition(active != nil)
    _ = model.score(for: player)
    _ = model.isWin(for: player)
    _ = model.isLoss(for: player)
    if let first = model.gameModelUpdates(for: player)?.first {
        model.apply(first)
        model.unapplyGameModelUpdate(first)
    }

    let monte = GKMonteCarloStrategist()
    monte.gameModel = model
    monte.budget = 8
    monte.explorationParameter = 2
    monte.randomSource = GKARC4RandomSource(seed: Data([5]))
    precondition(monte.budget == 8)
    precondition(monte.explorationParameter == 2)
    precondition(monte.bestMoveForActivePlayer() != nil)
    _ = player.playerId
    _ = (best as? ProbeUpdate)?.value
}
