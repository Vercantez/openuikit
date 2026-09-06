import Foundation
import LightweightCodeRequirements

func testLaunchConstraintBuilderBuildBlock() {
    let built = LaunchConstraintBuilder.buildBlock(
        [TeamIdentifier("A")],
        [SigningIdentifier("com.a")]
    )
    precondition(built.count == 2)
}

func testLaunchConstraintBuilderBuildExpression() {
    let single = LaunchConstraintBuilder.buildExpression(TeamIdentifier("A") as any LaunchConstraint)
    precondition(single.count == 1)
    let nested = LaunchConstraintBuilder.buildExpression(single)
    precondition(nested.count == 1)
}

func testLaunchConstraintBuilderBuildEither() {
    let first = LaunchConstraintBuilder.buildEither(first: [TeamIdentifier("A")])
    let second = LaunchConstraintBuilder.buildEither(second: [SigningIdentifier("com.a")])
    precondition(first.count == 1)
    precondition(second.count == 1)
}

func testLaunchConstraintBuilderBuildOptional() {
    let some = LaunchConstraintBuilder.buildOptional([TeamIdentifier("A")])
    let none = LaunchConstraintBuilder.buildOptional(nil)
    precondition(some.count == 1)
    precondition(none.isEmpty)
}

func testOnDiskConstraintBuilderBuildBlock() {
    let built = OnDiskConstraintBuilder.buildBlock(
        [IsMainBinary(true)],
        [TeamIdentifier("A")]
    )
    precondition(built.count == 2)
}

func testOnDiskConstraintBuilderBuildExpression() {
    let single = OnDiskConstraintBuilder.buildExpression(IsMainBinary() as any OnDiskConstraint)
    precondition(single.count == 1)
    precondition(OnDiskConstraintBuilder.buildExpression(single).count == 1)
}

func testOnDiskConstraintBuilderBuildEither() {
    precondition(OnDiskConstraintBuilder.buildEither(first: [IsMainBinary()]).count == 1)
    precondition(OnDiskConstraintBuilder.buildEither(second: [IsSIPProtected()]).count == 1)
}

func testOnDiskConstraintBuilderBuildOptional() {
    precondition(OnDiskConstraintBuilder.buildOptional([IsMainBinary()]).count == 1)
    precondition(OnDiskConstraintBuilder.buildOptional(nil).isEmpty)
}

func testProcessConstraintBuilderBuildBlock() {
    let built = ProcessConstraintBuilder.buildBlock(
        [IsInitProcess()],
        [TeamIdentifierMatchesCurrentProcess()]
    )
    precondition(built.count == 2)
}

func testProcessConstraintBuilderBuildExpression() {
    let single = ProcessConstraintBuilder.buildExpression(IsInitProcess() as any ProcessConstraint)
    precondition(single.count == 1)
    precondition(ProcessConstraintBuilder.buildExpression(single).count == 1)
}

func testProcessConstraintBuilderBuildEither() {
    precondition(ProcessConstraintBuilder.buildEither(first: [IsInitProcess()]).count == 1)
    precondition(ProcessConstraintBuilder.buildEither(second: [TeamIdentifier("A")]).count == 1)
}

func testProcessConstraintBuilderBuildOptional() {
    precondition(ProcessConstraintBuilder.buildOptional([IsInitProcess()]).count == 1)
    precondition(ProcessConstraintBuilder.buildOptional(nil).isEmpty)
}

func testLaunchRequirementAllOfSimplifiesSingle() {
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("8XCUU22SN2")
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    precondition(object["team-identifier"] as! String == "8XCUU22SN2")
    precondition(object["$and"] == nil)
}

func testLaunchRequirementAllOfMergesFacts() {
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("8XCUU22SN2")
        SigningIdentifier("com.example.app")
        ValidationCategory(.appStore)
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$and"] as! [[String: Any]]
    precondition(facts.count == 3)
}

func testLaunchRequirementAnyOf() {
    let requirement = try! LaunchCodeRequirement.anyOf {
        TeamIdentifier("8XCUU22SN2")
        ValidationCategory(.platform)
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$or"] as! [[String: Any]]
    precondition(facts.count == 2)
}

func testLaunchRequirementEquality() {
    let left = try! LaunchCodeRequirement.allOf { TeamIdentifier("A") }
    let right = try! LaunchCodeRequirement.allOf { TeamIdentifier("A") }
    let other = try! LaunchCodeRequirement.allOf { TeamIdentifier("B") }
    precondition(left == right)
    precondition(left != other)
}

func testLaunchRequirementCodable() {
    let original = try! LaunchCodeRequirement.allOf {
        PlatformType(.iOS)
        SigningIdentifier("com.example.app")
    }
    let decoded = try! lcrRoundTrip(original)
    precondition(decoded == original)
}

func testLaunchRequirementNestedAnyOf() {
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("A")
        anyOf {
            SigningIdentifier("com.foo")
            ValidationCategory(.platform)
        }
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$and"] as! [[String: Any]]
    precondition(facts.count == 2)
}

func testLaunchRequirementFlattensNestedAllOf() {
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("A")
        allOf {
            SigningIdentifier("com.foo")
        }
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$and"] as! [[String: Any]]
    precondition(facts.count == 2)
}

func testOnDiskRequirementAllOf() {
    let requirement = try! OnDiskCodeRequirement.allOf {
        IsMainBinary(true)
        TeamIdentifier("A")
    }
    let decoded = try! lcrRoundTrip(requirement)
    precondition(decoded == requirement)
}

func testOnDiskRequirementAnyOf() {
    let requirement = try! OnDiskCodeRequirement.anyOf {
        IsMainBinary(true)
        IsSIPProtected(true)
    }
    let data = try! JSONEncoder().encode(requirement)
    precondition((try! JSONSerialization.jsonObject(with: data) as! [String: Any])["$or"] != nil)
}

func testOnDiskRequirementEquality() {
    let left = try! OnDiskCodeRequirement.allOf { IsMainBinary(true) }
    let right = try! OnDiskCodeRequirement.allOf { IsMainBinary(true) }
    precondition(left == right)
    precondition(left != (try! OnDiskCodeRequirement.allOf { IsMainBinary(false) }))
}

func testProcessRequirementAllOf() {
    let requirement = try! ProcessCodeRequirement.allOf {
        IsInitProcess(false)
        TeamIdentifierMatchesCurrentProcess(true)
    }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testProcessRequirementAnyOf() {
    let requirement = try! ProcessCodeRequirement.anyOf {
        ProcessCodeSigningFlags.isSuperset(of: .isSigned)
        ValidationCategory(.platform)
    }
    let data = try! JSONEncoder().encode(requirement)
    precondition((try! JSONSerialization.jsonObject(with: data) as! [String: Any])["$or"] != nil)
}

func testProcessRequirementEquality() {
    let left = try! ProcessCodeRequirement.allOf { IsInitProcess(true) }
    let right = try! ProcessCodeRequirement.allOf { IsInitProcess(true) }
    precondition(left == right)
}

func testFreeFunctionAllOfLaunch() {
    let constraint: any LaunchConstraint = allOf {
        TeamIdentifier("A")
        SigningIdentifier("com.a")
    }
    let requirement = try! LaunchCodeRequirement.allOf {
        constraint
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    precondition(object["$and"] != nil)
}

func testFreeFunctionAnyOfLaunch() {
    let constraint: any LaunchConstraint = anyOf {
        TeamIdentifier("A")
        ValidationCategory(.platform)
    }
    let requirement = try! LaunchCodeRequirement.allOf {
        SigningIdentifier("com.a")
        constraint
    }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testFreeFunctionAllOfOnDisk() {
    let constraint: any OnDiskConstraint = allOf {
        IsMainBinary()
        TeamIdentifier("A")
    }
    let requirement = try! OnDiskCodeRequirement.allOf { constraint }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testFreeFunctionAnyOfOnDisk() {
    let constraint: any OnDiskConstraint = anyOf {
        IsMainBinary()
        IsSIPProtected()
    }
    let requirement = try! OnDiskCodeRequirement.allOf {
        TeamIdentifier("A")
        constraint
    }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testFreeFunctionAllOfProcess() {
    let constraint: any ProcessConstraint = allOf {
        IsInitProcess()
        TeamIdentifier("A")
    }
    let requirement = try! ProcessCodeRequirement.allOf { constraint }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testFreeFunctionAnyOfProcess() {
    let constraint: any ProcessConstraint = anyOf {
        IsInitProcess()
        TeamIdentifierMatchesCurrentProcess()
    }
    let requirement = try! ProcessCodeRequirement.allOf {
        SigningIdentifier("com.a")
        constraint
    }
    precondition(try! lcrRoundTrip(requirement) == requirement)
}

func testConvertLaunchToProcess() {
    let launch = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("A")
        SigningIdentifier("com.a")
    }
    let process = try! ProcessCodeRequirement(launch)
    precondition(try! LaunchCodeRequirement(process) == launch)
}

func testConvertLaunchToOnDisk() {
    let launch = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("A")
        PlatformType(.macOS)
    }
    let onDisk = try! OnDiskCodeRequirement(launch)
    precondition(try! LaunchCodeRequirement(onDisk) == launch)
}

func testConvertOnDiskToProcessCompatible() {
    let onDisk = try! OnDiskCodeRequirement.allOf {
        TeamIdentifier("A")
        CodeDirectoryHash(Data([0x01]))
    }
    let process = try! ProcessCodeRequirement(onDisk)
    precondition(try! OnDiskCodeRequirement(process) == onDisk)
}

func testConvertProcessIsInitToOnDiskThrows() {
    let process = try! ProcessCodeRequirement.allOf { IsInitProcess(true) }
    do {
        _ = try OnDiskCodeRequirement(process)
        preconditionFailure("IsInitProcess is not an on-disk constraint")
    } catch let error as ConstraintError {
        precondition(error == .unsupportedConstraintForRequirementType)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testConvertOnDiskFlagsToLaunchThrows() {
    let onDisk = try! OnDiskCodeRequirement.allOf {
        OnDiskCodeSigningFlags.isSuperset(of: .isAdhocSigned)
    }
    do {
        _ = try LaunchCodeRequirement(onDisk)
        preconditionFailure("on-disk flags cannot convert to launch")
    } catch let error as ConstraintError {
        precondition(error == .unsupportedConstraintForRequirementType)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testConvertTeamMatchToLaunchThrows() {
    let process = try! ProcessCodeRequirement.allOf {
        TeamIdentifierMatchesCurrentProcess()
    }
    do {
        _ = try LaunchCodeRequirement(process)
        preconditionFailure("team-match is process-only")
    } catch let error as ConstraintError {
        precondition(error == .unsupportedConstraintForRequirementType)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testProcessFlagsAllowedOnLaunch() {
    let launch = try! LaunchCodeRequirement.allOf {
        ProcessCodeSigningFlags.isSuperset(of: .isSigned)
    }
    let process = try! ProcessCodeRequirement(launch)
    precondition(try! LaunchCodeRequirement(process) == launch)
}

func testEntitlementsQueryAllowedDuplicates() {
    let requirement = try! LaunchCodeRequirement.allOf {
        EntitlementsQuery.key("a").match(true)
        EntitlementsQuery.key("b").match(true)
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$and"] as! [[String: Any]]
    precondition(facts.count == 2)
}

func testBuilderIfElse() {
    let includeSigning = true
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier("A")
        if includeSigning {
            SigningIdentifier("com.a")
        } else {
            ValidationCategory(.platform)
        }
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let facts = object["$and"] as! [[String: Any]]
    precondition(facts.count == 2)
}

func testInOperatorEncoding() {
    let requirement = try! LaunchCodeRequirement.allOf {
        TeamIdentifier.in("A", "B")
    }
    let data = try! JSONEncoder().encode(requirement)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let wrapper = object["team-identifier"] as! [String: Any]
    let values = wrapper["$in"] as! [String]
    precondition(values == ["A", "B"])
}
