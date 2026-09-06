@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testGroupMuteSolo() {
    let group = PHASEGroup(identifier: "g1")
    expect(group.identifier == "g1", "id")
    expect(group.gain == 1 && group.rate == 1, "defaults")
    expect(!group.isMuted && !group.isSoloed, "flags")
    group.mute()
    expect(group.isMuted, "muted")
    group.unmute()
    expect(!group.isMuted, "unmuted")
    group.solo()
    expect(group.isSoloed, "soloed")
    group.unsolo()
    expect(!group.isSoloed, "unsoloed")
}

func testGroupRegister() {
    let engine = PHASEEngine(updateMode: .manual)
    let group = PHASEGroup(identifier: "bus")
    group.register(engine: engine)
    expect(engine.groups["bus"] === group, "registered")
    group.unregisterFromEngine()
    expect(engine.groups["bus"] == nil, "unregistered")
}

func testGroupFadeSnaps() {
    let group = PHASEGroup(identifier: "fade")
    group.fadeGain(gain: 0.2, duration: 1, curveType: .linear)
    expect(group.gain == 0.2, "gain snap")
    group.fadeRate(rate: 1.5, duration: 2, curveType: .sine)
    expect(group.rate == 1.5, "rate snap")
}

func testGroupPresetSetting() {
    let setting = PHASEGroupPresetSetting(
        gain: 0.4,
        rate: 1.1,
        gainCurveType: .linear,
        rateCurveType: .squared
    )
    expect(setting.gain == 0.4, "gain")
    expect(setting.rate == 1.1, "rate")
    expect(setting.gainCurveType == .linear, "gain curve")
    expect(setting.rateCurveType == .squared, "rate curve")
}

func testGroupPresetActivate() {
    let engine = PHASEEngine(updateMode: .manual)
    let group = PHASEGroup(identifier: "bus")
    group.register(engine: engine)
    let setting = PHASEGroupPresetSetting(
        gain: 0.3,
        rate: 0.8,
        gainCurveType: .linear,
        rateCurveType: .linear
    )
    let preset = PHASEGroupPreset(
        engine: engine,
        settings: ["bus": setting],
        timeToTarget: 0.1,
        timeToReset: 0.2
    )
    expect(preset.timeToTarget == 0.1, "target")
    expect(preset.timeToReset == 0.2, "reset")
    expect(preset.settings["bus"] === setting, "settings")
    preset.activate()
    expect(engine.activeGroupPreset === preset, "active")
    expect(group.gain == 0.3 && group.rate == 0.8, "applied")
    preset.deactivate()
    expect(engine.activeGroupPreset == nil, "cleared")
}

func testGroupPresetOverrides() {
    let engine = PHASEEngine(updateMode: .manual)
    let preset = PHASEGroupPreset(engine: engine, settings: [:], timeToTarget: 1, timeToReset: 1)
    preset.activate(timeToTargetOverride: 0)
    expect(engine.activeGroupPreset === preset, "override activate")
    preset.deactivate(timeToResetOverride: 0)
    expect(engine.activeGroupPreset == nil, "override deactivate")
}

func testDuckerActivate() {
    let engine = PHASEEngine(updateMode: .manual)
    let source = PHASEGroup(identifier: "src")
    let target = PHASEGroup(identifier: "dst")
    let ducker = PHASEDucker(
        engine: engine,
        sourceGroups: [source],
        targetGroups: [target],
        gain: 0.1,
        attackTime: 0.05,
        releaseTime: 0.2,
        attackCurve: .linear,
        releaseCurve: .squared
    )
    expect(engine.duckers.contains(where: { $0 === ducker }), "registered")
    expect(!ducker.isActive, "inactive")
    expect(ducker.gain == 0.1, "gain")
    expect(ducker.attackTime == 0.05, "attack")
    expect(ducker.releaseTime == 0.2, "release")
    expect(ducker.attackCurve == .linear, "attack curve")
    expect(ducker.releaseCurve == .squared, "release curve")
    expect(ducker.sourceGroups.contains(source), "source")
    expect(ducker.targetGroups.contains(target), "target")
    expect(ducker.identifier.isEmpty == false, "id")
    ducker.activate()
    expect(ducker.isActive, "active")
    ducker.deactivate()
    expect(!ducker.isActive, "deactivated")
}
