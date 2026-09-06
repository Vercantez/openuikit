import Foundation
import EnergyKit

func testElectricityGuidanceType() {
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: UUID(),
        suggestedAction: .shift,
        interval: energyKitSampleInterval(),
        values: [],
        options: []
    )
    energyKitExpectEqual(guidance.suggestedAction, .shift)
}

func testElectricityGuidanceToken() {
    let token = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    let guidance = ElectricityGuidance(
        guidanceToken: token,
        energyVenueID: UUID(),
        suggestedAction: .reduce,
        interval: energyKitSampleInterval(),
        values: [],
        options: []
    )
    energyKitExpectEqual(guidance.guidanceToken, token)
}

func testElectricityGuidanceEnergyVenueID() {
    let venueID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: venueID,
        suggestedAction: .shift,
        interval: energyKitSampleInterval(),
        values: [],
        options: []
    )
    energyKitExpectEqual(guidance.energyVenueID, venueID)
}

func testElectricityGuidanceSuggestedActionProperty() {
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: UUID(),
        suggestedAction: .reduce,
        interval: energyKitSampleInterval(),
        values: [],
        options: []
    )
    energyKitExpectEqual(guidance.suggestedAction, .reduce)
}

func testElectricityGuidanceInterval() {
    let interval = energyKitSampleInterval()
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: UUID(),
        suggestedAction: .shift,
        interval: interval,
        values: [],
        options: []
    )
    energyKitExpectEqual(guidance.interval, interval)
}

func testElectricityGuidanceValues() {
    let value = ElectricityGuidance.Value(interval: energyKitSampleInterval(), rating: 0.75)
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: UUID(),
        suggestedAction: .shift,
        interval: energyKitSampleInterval(),
        values: [value],
        options: []
    )
    energyKitExpectEqual(guidance.values.count, 1)
    energyKitExpectEqual(guidance.values[0].rating, 0.75)
}

func testElectricityGuidanceOptionsProperty() {
    let guidance = ElectricityGuidance(
        guidanceToken: UUID(),
        energyVenueID: UUID(),
        suggestedAction: .shift,
        interval: energyKitSampleInterval(),
        values: [],
        options: [.locationHasRatePlan]
    )
    energyKitExpect(guidance.options.contains(.locationHasRatePlan))
}

func testElectricityGuidanceSharedService() {
    energyKitExpect(ElectricityGuidance.sharedService === ElectricityGuidance.sharedService)
}

func testElectricityGuidanceCodable() {
    let original = ElectricityGuidance(
        guidanceToken: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        energyVenueID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        suggestedAction: .reduce,
        interval: energyKitSampleInterval(),
        values: [ElectricityGuidance.Value(interval: energyKitSampleInterval(), rating: 0.2)],
        options: [.guidanceIncorporatesRatePlan]
    )
    let decoded = try! energyKitRoundTrip(original)
    energyKitExpectEqual(decoded.guidanceToken, original.guidanceToken)
    energyKitExpectEqual(decoded.suggestedAction, .reduce)
}

func testElectricityGuidanceEncode() {
    let data = try! JSONEncoder().encode(
        ElectricityGuidance(
            guidanceToken: UUID(),
            energyVenueID: UUID(),
            suggestedAction: .shift,
            interval: energyKitSampleInterval(),
            values: [],
            options: []
        )
    )
    energyKitExpect(data.count > 0)
}

func testSuggestedActionCases() {
    let cases: [ElectricityGuidance.SuggestedAction] = [.shift, .reduce]
    energyKitExpectEqual(Set(cases).count, 2)
}

func testSuggestedActionEquality() {
    energyKitExpectEqual(ElectricityGuidance.SuggestedAction.shift, .shift)
    energyKitExpect(ElectricityGuidance.SuggestedAction.shift != .reduce)
}

func testSuggestedActionInequality() {
    energyKitExpect(ElectricityGuidance.SuggestedAction.reduce != .shift)
}

func testSuggestedActionHash() {
    var hasher = Hasher()
    ElectricityGuidance.SuggestedAction.shift.hash(into: &hasher)
    energyKitExpectEqual(Set([ElectricityGuidance.SuggestedAction.shift, .shift]).count, 1)
}

func testSuggestedActionCodable() {
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityGuidance.SuggestedAction.shift), .shift)
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityGuidance.SuggestedAction.reduce), .reduce)
}

func testGuidanceQueryInit() {
    let query = ElectricityGuidance.Query(suggestedAction: .shift)
    energyKitExpectEqual(query.suggestedAction, .shift)
}

func testGuidanceQueryCodable() {
    let decoded = try! energyKitRoundTrip(ElectricityGuidance.Query(suggestedAction: .reduce))
    energyKitExpectEqual(decoded.suggestedAction, .reduce)
}

func testGuidanceQueryEncode() {
    let data = try! JSONEncoder().encode(ElectricityGuidance.Query(suggestedAction: .shift))
    energyKitExpect(data.count > 0)
}

func testGuidanceValueInit() {
    let value = ElectricityGuidance.Value(interval: energyKitSampleInterval(), rating: 1.5)
    energyKitExpectEqual(value.rating, 1.5)
}

func testGuidanceValueInterval() {
    let interval = energyKitSampleInterval()
    let value = ElectricityGuidance.Value(interval: interval, rating: 0)
    energyKitExpectEqual(value.interval, interval)
}

func testGuidanceValueRating() {
    energyKitExpectEqual(ElectricityGuidance.Value(interval: energyKitSampleInterval(), rating: -0.25).rating, -0.25)
}

func testGuidanceValueCodable() {
    let original = ElectricityGuidance.Value(interval: energyKitSampleInterval(), rating: 0.5)
    let decoded = try! energyKitRoundTrip(original)
    energyKitExpectEqual(decoded.rating, 0.5)
}

func testGuidanceOptionsCases() {
    energyKitExpectEqual(
        ElectricityGuidance.Options.allCases,
        [.locationHasRatePlan, .guidanceIncorporatesRatePlan]
    )
}

func testGuidanceOptionsEquality() {
    energyKitExpectEqual(ElectricityGuidance.Options.locationHasRatePlan, .locationHasRatePlan)
    energyKitExpect(ElectricityGuidance.Options.locationHasRatePlan != .guidanceIncorporatesRatePlan)
}

func testGuidanceOptionsInequality() {
    energyKitExpect(ElectricityGuidance.Options.guidanceIncorporatesRatePlan != .locationHasRatePlan)
}

func testGuidanceOptionsAllCasesTypealias() {
    let cases: ElectricityGuidance.Options.AllCases = ElectricityGuidance.Options.allCases
    energyKitExpectEqual(cases.count, 2)
}

func testGuidanceOptionsHashable() {
    var hasher = Hasher()
    ElectricityGuidance.Options.locationHasRatePlan.hash(into: &hasher)
    energyKitExpectEqual(
        Set([ElectricityGuidance.Options.locationHasRatePlan, .locationHasRatePlan]).count,
        1
    )
}

func testGuidanceOptionsCodable() {
    energyKitExpectEqual(
        try! energyKitRoundTrip(ElectricityGuidance.Options.locationHasRatePlan),
        .locationHasRatePlan
    )
}

func testGuidanceServiceType() {
    let service = ElectricityGuidance.Service()
    energyKitExpectEqual(String(describing: type(of: service)), "Service")
}

func testGuidanceServiceGuidanceFailClosed() {
    let query = ElectricityGuidance.Query(suggestedAction: .shift)
    let sequence = ElectricityGuidance.sharedService.guidance(using: query, at: UUID())
    energyKitExpectError(
        energyKitAwait { () async throws -> ElectricityGuidance in
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next()!
        },
        .guidanceUnavailable
    )
}
