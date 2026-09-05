import Foundation
import GameplayKit

func testNoiseSourcesDeterminism() {
    let perlin = GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7)
    precondition(perlin.frequency == 1)
    precondition(perlin.octaveCount == 3)
    precondition(perlin.persistence == 0.5)
    precondition(perlin.lacunarity == 2)
    precondition(perlin.seed == 7)
    let noise = GKNoise(perlin)
    let n1 = noise.value(atPosition: SIMD2<Float>(0.2, 0.3))
    let n2 = GKNoise(GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7))
        .value(atPosition: SIMD2<Float>(0.2, 0.3))
    precondition(n1 == n2)
    _ = GKNoise(noiseSource: perlin)

    let billow = GKBillowNoiseSource(frequency: 1, octaveCount: 2, persistence: 0.4, lacunarity: 2, seed: 1)
    precondition(billow.persistence == 0.4)
    _ = GKNoise(billow).value(atPosition: SIMD2<Float>(0.1, 0.1))
    let ridged = GKRidgedNoiseSource(frequency: 1, octaveCount: 2, lacunarity: 2, seed: 2)
    _ = GKNoise(ridged).value(atPosition: SIMD2<Float>(0.2, 0.1))
    let constant = GKConstantNoiseSource.constantNoise(withValue: 0.25)
    precondition(constant.value == 0.25)
    let namedConstant = GKConstantNoiseSource(value: -0.5)
    precondition(namedConstant.value == -0.5)
    precondition(GKNoise(namedConstant).value(atPosition: SIMD2<Float>(0, 0)) == Float(-0.5))
    precondition(GKNoise(constant).value(atPosition: SIMD2<Float>(0, 0)) == Float(0.25))
    let cylinders = GKCylindersNoiseSource.cylindersNoise(withFrequency: 2)
    precondition(cylinders.frequency == 2)
    _ = GKCylindersNoiseSource(frequency: 1)
    let spheres = GKSpheresNoiseSource.spheresNoise(withFrequency: 1)
    precondition(spheres.frequency == 1)
    _ = GKSpheresNoiseSource(frequency: 2)
    let checker = GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1)
    precondition(checker.squareSize == 1)
    _ = GKCheckerboardNoiseSource(squareSize: 2)
    _ = GKNoise(GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1))
        .value(atPosition: SIMD2<Float>(0.2, 0.2))
    let voronoi = GKVoronoiNoiseSource.voronoiNoise(
        withFrequency: 1,
        displacement: 0.5,
        distanceEnabled: true,
        seed: 4
    )
    precondition(voronoi.frequency == 1)
    precondition(voronoi.displacement == 0.5)
    precondition(voronoi.isDistanceEnabled)
    precondition(voronoi.seed == 4)
    _ = GKVoronoiNoiseSource(frequency: 1, displacement: 1, distanceEnabled: false, seed: 0)
    _ = GKCoherentNoiseSource()
    _ = GKNoiseSource()
    _ = GKNoise()
}

func testNoiseOperationsAndMaps() {
    let source = GKConstantNoiseSource(value: 0.4)
    let noise = GKNoise(source)
    let other = GKNoise(GKConstantNoiseSource(value: 0.2))
    noise.add(other)
    noise.multiply(other)
    noise.minimum(other)
    noise.maximum(other)
    noise.invert()
    noise.applyAbsoluteValue()
    noise.clamp(lowerBound: -0.5, upperBound: 0.5)
    noise.raiseToPower(2)
    noise.raiseToPower(other)
    noise.move(by: SIMD3<Double>(0.1, 0, 0))
    noise.scale(by: SIMD3<Double>(1, 1, 1))
    noise.rotate(by: SIMD3<Double>(0, 0, 0))
    noise.applyTurbulence(frequency: 1, power: 0.2, roughness: 1, seed: 3)
    noise.displaceWithNoises(x: other, y: other, z: other)
    noise.remapValues(toCurveWithControlPoints: [
        NSNumber(value: -1): NSNumber(value: 0),
        NSNumber(value: 1): NSNumber(value: 1)
    ])
    noise.remapValues(toTerracesWithPeaks: [NSNumber(value: -0.5), NSNumber(value: 0.5)], terracesInverted: false)
    _ = noise.value(atPosition: SIMD2<Float>(0.1, 0.2))

    let select = GKNoise(componentNoises: [GKNoise(source), other], selectionNoise: other)
    _ = select.value(atPosition: SIMD2<Float>(0, 0))
    let blended = GKNoise(
        componentNoises: [GKNoise(source), other],
        selectionNoise: other,
        componentBoundaries: [NSNumber(value: 0)],
        boundaryBlendDistances: [NSNumber(value: 0.1)]
    )
    _ = blended.value(atPosition: SIMD2<Float>(0, 0))

    let map = GKNoiseMap(
        noise,
        size: SIMD2<Double>(1, 1),
        origin: SIMD2<Double>(0, 0),
        sampleCount: SIMD2<Int32>(8, 8),
        seamless: false
    )
    precondition(map.sampleCount.x == 8)
    precondition(map.size.x == 1)
    precondition(map.origin.x == 0)
    precondition(map.isSeamless == false)
    _ = map.value(at: SIMD2<Int32>(0, 0))
    map.setValue(0.5, at: SIMD2<Int32>(0, 0))
    precondition(map.value(at: SIMD2<Int32>(0, 0)) == 0.5)
    _ = map.interpolatedValue(at: SIMD2<Float>(1.5, 1.5))
    _ = GKNoiseMap()
    _ = GKNoiseMap(noise)
    _ = GKNoiseMap(noise: noise)
    let named = GKNoiseMap(
        noise: noise,
        size: SIMD2<Double>(1, 1),
        origin: SIMD2<Double>(0, 0),
        sampleCount: SIMD2<Int32>(4, 8),
        seamless: true
    )
    precondition(named.isSeamless)
    _ = named.sampleCount.y
}
