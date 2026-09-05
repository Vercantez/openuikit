import Foundation
import GameplayKit

private final class HealthComponent: GKComponent {
    override class var supportsSecureCoding: Bool { true }
    var value: Int = 0
    var added = 0
    var removed = 0
    var updates = 0

    convenience init(value: Int) {
        self.init()
        self.value = value
    }

    override init() {
        super.init()
    }

    override func didAddToEntity() {
        added += 1
    }

    override func willRemoveFromEntity() {
        removed += 1
    }

    override func update(deltaTime seconds: TimeInterval) {
        updates += 1
        _ = seconds
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        HealthComponent(value: value)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(value), forKey: "health.value")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        value = Int(coder.decodeInt64(forKey: "health.value"))
    }
}

func testComponentOwnership() {
    let first = GKEntity()
    let second = GKEntity()
    let health = HealthComponent(value: 7)
    precondition(health.entity == nil)
    first.addComponent(health)
    precondition(health.entity === first)
    precondition(first.component(ofType: HealthComponent.self) === health)
    precondition(first.components.count == 1)
    second.addComponent(health)
    precondition(health.entity === second)
    precondition(first.component(ofType: HealthComponent.self) == nil)
    precondition(second.component(ofType: HealthComponent.self) === health)
    precondition(health.removed == 1)
    precondition(health.added == 2)

    let replacement = HealthComponent(value: 9)
    second.addComponent(replacement)
    precondition(second.component(ofType: HealthComponent.self) === replacement)
    precondition(health.entity == nil)
    precondition(second.components.count == 1)

    second.removeComponent(ofType: HealthComponent.self)
    precondition(second.component(ofType: HealthComponent.self) == nil)
    precondition(replacement.entity == nil)

    var host: GKEntity? = GKEntity()
    let orphan = HealthComponent(value: 1)
    host!.addComponent(orphan)
    host = nil
    precondition(orphan.entity == nil)
}

func testComponentSystemAndEntityUpdate() {
    let entity = GKEntity()
    let health = HealthComponent(value: 7)
    entity.addComponent(health)
    let system = GKComponentSystem<HealthComponent>(componentClass: HealthComponent.self)
    precondition(system.componentClass == HealthComponent.self)
    system.addComponent(foundIn: entity)
    precondition(system.components.count == 1)
    precondition(system[0] === health)
    precondition(system.classForGenericArgument(at: 0) == HealthComponent.self)
    entity.update(deltaTime: 0.016)
    precondition(health.updates == 1)
    system.update(deltaTime: 0.016)
    precondition(health.updates == 2)
    let extra = HealthComponent(value: 3)
    system.addComponent(extra)
    precondition(system.components.count == 2)
    system.removeComponent(extra)
    precondition(system.components.count == 1)
    system.removeComponent(foundIn: entity)
    precondition(system.components.isEmpty)
}
