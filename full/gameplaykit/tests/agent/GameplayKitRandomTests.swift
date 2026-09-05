import Foundation
import GameplayKit

func testARC4SeedDeterminismAndCopy() {
    let seed = Data([1, 2, 3, 4, 5, 6, 7, 8])
    let arc4 = GKARC4RandomSource(seed: seed)
    precondition(arc4.seed == seed)
    let first = arc4.nextInt()
    let replay = GKARC4RandomSource(seed: seed)
    precondition(replay.nextInt() == first)
    let copy = arc4.copy() as! GKARC4RandomSource
    copy.dropValues(8)
    _ = copy.nextBool()
    let unadvanced = arc4.copy() as! GKARC4RandomSource
    precondition(arc4.nextInt() == unadvanced.nextInt())
    copy.dropValues(16)
    let fromCopy = copy.nextInt()
    let fromFresh = GKARC4RandomSource(seed: seed).nextInt()
    precondition(fromCopy != fromFresh)
    precondition(copy.seed == seed)
    let dropped = GKARC4RandomSource(seed: seed)
    dropped.dropValues(0)
    _ = GKARC4RandomSource()
    for _ in 0..<32 {
        let bound = arc4.nextInt(upperBound: 7)
        precondition(bound >= 0 && bound < 7)
    }
    precondition(arc4.nextInt(upperBound: 0) == 0)
    precondition(arc4.nextInt(upperBound: 1) == 0)
    let uniform = GKARC4RandomSource(seed: seed).nextUniform()
    precondition(uniform >= 0 && uniform < 1)
}

func testLCGAndMersenneDeterminism() {
    let lcg = GKLinearCongruentialRandomSource(seed: 42)
    let lcgA = lcg.nextInt()
    let lcg2 = GKLinearCongruentialRandomSource(seed: 42)
    precondition(lcg2.nextInt() == lcgA)
    precondition(GKLinearCongruentialRandomSource(seed: 42).seed == 42)
    _ = GKLinearCongruentialRandomSource()

    let mt = GKMersenneTwisterRandomSource(seed: 99)
    precondition(mt.seed == 99)
    let bounded = mt.nextInt(upperBound: 10)
    precondition(bounded >= 0 && bounded < 10)
    let replay = GKMersenneTwisterRandomSource(seed: 99)
    precondition(replay.nextInt() == GKMersenneTwisterRandomSource(seed: 99).nextInt())
    _ = GKMersenneTwisterRandomSource()
}

func testDistributionsAndShuffle() {
    let die = GKRandomDistribution.d6()
    let roll = die.nextInt()
    precondition(roll >= 1 && roll <= 6)
    let d20 = GKRandomDistribution.d20()
    for _ in 0..<16 {
        let value = d20.nextInt()
        precondition(value >= 1 && value <= 20)
    }
    let custom = GKRandomDistribution(lowestValue: 2, highestValue: 5)
    precondition(custom.lowestValue == 2)
    precondition(custom.highestValue == 5)
    precondition(custom.numberOfPossibleOutcomes == 4)
    let sides = GKRandomDistribution(forDieWithSideCount: 8)
    precondition(sides.lowestValue == 1 && sides.highestValue == 8)
    let sourced = GKRandomDistribution(
        randomSource: GKARC4RandomSource(seed: Data([9])),
        lowestValue: 1,
        highestValue: 4
    )
    _ = sourced.nextBool()
    let uniform = sourced.nextUniform()
    precondition(uniform >= 0 && uniform <= 1)
    _ = sourced.nextInt(upperBound: 3)

    let shuffled = GKShuffledDistribution(
        randomSource: GKARC4RandomSource(seed: Data([9])),
        lowestValue: 1,
        highestValue: 3
    )
    var seen = Set<Int>()
    for _ in 0..<3 { seen.insert(shuffled.nextInt()) }
    precondition(seen == Set([1, 2, 3]))

    let gaussianRange = GKGaussianDistribution(
        randomSource: GKLinearCongruentialRandomSource(seed: 3),
        lowestValue: 1,
        highestValue: 10
    )
    precondition(gaussianRange.mean == 5.5)
    let sample = gaussianRange.nextInt()
    precondition(sample >= 1 && sample <= 10)
    let gaussian = GKGaussianDistribution(
        randomSource: GKLinearCongruentialRandomSource(seed: 3),
        mean: 10,
        deviation: 2
    )
    precondition(gaussian.mean == 10)
    precondition(gaussian.deviation == 2)
    _ = gaussian.nextInt()

    let corpusObjects: [Any] = ["alpha", "beta", "gamma"]
    let shuffledObjects = GKMersenneTwisterRandomSource(seed: 99)
        .arrayByShufflingObjects(in: corpusObjects)
    let typed = shuffledObjects as? [String]
    precondition(typed?.count == 3)
    precondition(Set(typed ?? []) == Set(["alpha", "beta", "gamma"]))
    let array: NSArray = ["a", "b", "c", "d"]
    precondition(array.shuffled(using: GKARC4RandomSource(seed: Data([2]))).count == 4)
    precondition(array.shuffled().count == 4)
    _ = GKRandomSource.sharedRandom().nextInt(upperBound: 4)
    _ = GKRandomSource()
}

func testRandomProtocolNextValues() {
    let source: any GKRandom = GKARC4RandomSource(seed: Data([4, 5, 6, 7]))
    _ = source.nextInt()
    let bound = source.nextInt(upperBound: 5)
    precondition(bound >= 0 && bound < 5)
    let uniform = source.nextUniform()
    precondition(uniform >= 0 && uniform < 1)
    _ = source.nextBool()
}
