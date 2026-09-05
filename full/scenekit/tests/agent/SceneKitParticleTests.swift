import Foundation
import SceneKit

func testParticleSystemStores() {
    let particles = SCNParticleSystem()
    particles.birthRate = 10
    particles.loops = true
    particles.emissionDuration = 1
    particles.particleLifeSpan = 1
    particles.particleSize = 1
    particles.particleColor = SCNVector4(1, 1, 1, 1)
    particles.emitterShape = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
    particles.warmupDuration = 0
    particles.birthRateVariation = 0
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.spreadingAngle = 0
    particles.particleAngle = 0
    particles.particleAngularVelocity = 0
    particles.particleVelocity = 0
    particles.acceleration = SCNVector3Zero
    particles.isAffectedByGravity = false
    particles.isAffectedByPhysicsFields = false
    particles.particleDiesOnCollision = false
    particles.blendMode = .alpha
    particles.sortingMode = .none
    particles.orientationMode = .billboardScreenAligned
    particles.birthLocation = .surface
    particles.birthDirection = .constant
    particles.isLocal = false
    particles.dampingFactor = 0
    particles.speedFactor = 1
    particles.stretchFactor = 0
    particles.fresnelExponent = 0
    particles.writesToDepthBuffer = false
    precondition(particles.loops)
    _ = particles.particleImage
    _ = particles.systemSpawnedOnCollision
}
