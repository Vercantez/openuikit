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

func testParticleEmissionAndReset() {
    let particles = SCNParticleSystem()
    particles.birthRate = 10
    particles.loops = true
    particles.emissionDuration = 10
    particles.emissionDurationVariation = 0
    particles.idleDuration = 0
    particles.idleDurationVariation = 0
    particles.particleLifeSpan = 5
    particles.particleLifeSpanVariation = 0
    particles.particleVelocity = 2
    particles.particleVelocityVariation = 0
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.spreadingAngle = 0
    particles.acceleration = SCNVector3Zero
    particles.dampingFactor = 0
    particles.speedFactor = 1
    particles.particleSize = 1
    particles.particleSizeVariation = 0
    particles.particleAngle = 0
    particles.particleAngleVariation = 0
    particles.particleAngularVelocity = 0
    particles.particleAngularVelocityVariation = 0
    particles.particleMass = 1
    particles.particleMassVariation = 0
    particles.particleBounce = 0.2
    particles.particleBounceVariation = 0
    particles.particleCharge = 0
    particles.particleChargeVariation = 0
    particles.particleFriction = 0
    particles.particleFrictionVariation = 0
    particles.particleIntensity = 1
    particles.particleIntensityVariation = 0
    particles.particleColorVariation = SCNVector4Zero
    particles.isBlackPassEnabled = true
    particles.isLightingEnabled = true
    particles.orientationDirection = SCNVector3(0, 1, 0)
    particles.imageSequenceRowCount = 2
    particles.imageSequenceColumnCount = 2
    particles.imageSequenceInitialFrame = 0
    particles.imageSequenceInitialFrameVariation = 0
    particles.imageSequenceFrameRate = 12
    particles.imageSequenceFrameRateVariation = 0
    particles.imageSequenceAnimationMode = .repeat
    particles.systemSpawnedOnDying = SCNParticleSystem()
    particles.systemSpawnedOnLiving = SCNParticleSystem()
    let collider = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
    particles.colliderNodes = [collider]
    particles.particleDiesOnCollision = false
    precondition(particles.isBlackPassEnabled)
    precondition(particles.isLightingEnabled)
    precondition(particles.imageSequenceColumnCount == 2)
    precondition(particles.colliderNodes?.count == 1)
    particles.linux_advance(1)
    precondition(particles.linux_aliveCount == 10)
    precondition(abs(particles.linux_firstPosition.y - 2) < 0.15)
    particles.reset()
    precondition(particles.linux_aliveCount == 0)
}

func testParticleModifiersAndEvents() {
    let particles = SCNParticleSystem()
    particles.birthRate = 4
    particles.loops = true
    particles.emissionDuration = 10
    particles.particleLifeSpan = 10
    particles.particleVelocity = 5
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.acceleration = SCNVector3Zero
    var births = 0
    particles.handle(.birth, forProperties: [.position], handler: { _, _, _, count in
        births += count
    })
    particles.addModifier(forProperties: [.velocity], at: .preDynamics, modifier: { data, stride, start, end, dt in
        _ = stride
        _ = dt
        let vel = data[0].assumingMemoryBound(to: Float.self)
        var i = start
        while i < end {
            vel[i * 3 + 0] = 0
            vel[i * 3 + 1] = 0
            vel[i * 3 + 2] = 0
            i += 1
        }
    })
    particles.linux_advance(1)
    precondition(births == 4)
    precondition(particles.linux_aliveCount == 4)
    precondition(abs(particles.linux_firstPosition.y) < 1e-3)
    particles.removeModifiers(at: .preCollision)
    particles.removeAllModifiers()
    let controller = SCNParticlePropertyController(animation: CAAnimation())
    controller.inputMode = .overLife
    controller.inputScale = 2
    controller.inputBias = 0.5
    controller.inputOrigin = SCNNode()
    controller.inputProperty = .life
    particles.propertyControllers = [.size: controller]
    precondition(particles.propertyControllers?[.size]?.inputMode == .overLife)
    precondition(abs(Float(controller.inputScale) - 2) < 1e-4)
    precondition(controller.inputProperty == .life)
}

func testParticlePropertyConstants() {
    let props: [SCNParticleSystem.ParticleProperty] = [
        .position, .angle, .rotationAxis, .velocity, .angularVelocity, .life,
        .color, .opacity, .size, .frame, .frameRate, .bounce, .charge, .friction,
        .contactPoint, .contactNormal
    ]
    precondition(SCNParticleSystem.ParticleProperty.angle.rawValue == "angle")
    precondition(SCNParticleSystem.ParticleProperty.bounce.rawValue == "bounce")
    precondition(SCNParticleSystem.ParticleProperty.charge.rawValue == "charge")
    precondition(SCNParticleSystem.ParticleProperty.contactNormal.rawValue == "contactNormal")
    precondition(SCNParticleSystem.ParticleProperty.contactPoint.rawValue == "contactPoint")
    precondition(SCNParticleSystem.ParticleProperty.frameRate.rawValue == "frameRate")
    precondition(SCNParticleSystem.ParticleProperty.life.rawValue == "life")
    precondition(SCNParticleSystem.ParticleProperty.rotationAxis.rawValue == "rotationAxis")
    precondition(SCNParticleSystem.ParticleProperty.angle != .bounce)
    _ = SCNParticleSystem.ParticleProperty.angle.hashValue
    var hasher = Hasher()
    SCNParticleSystem.ParticleProperty.life.hash(into: &hasher)
    precondition(props.count == 16)
    _ = SCNParticleEventBlock.self
    _ = SCNParticleModifierBlock.self
    _ = SCNParticleSystem.ParticleProperty.self
}
