import Foundation
import UniformTypeIdentifiers

/// Maps Apple's `NSComparisonPredicate.Operator` onto the Linux
/// `HKPredicateOperator` stand-in. Raw values are identical on iPhoneOS 26.1
/// (Apple oracle `scratch/oracle-2026-09-14/hk-predicate-probe.output.txt`:
/// lessThan=0, lessThanOrEqualTo=1, greaterThan=2, greaterThanOrEqualTo=3,
/// equalTo=4, notEqualTo=5). Out-of-range values fail-closed to `equalTo`
/// rather than inventing a comparison.
public func hkOperatorFromComparison(
    _ operatorType: NSComparisonPredicate.Operator
) -> HKPredicateOperator {
    HKPredicateOperator(rawValue: UInt(operatorType.rawValue)) ?? .equalTo
}

extension HKQuery {
    public class func predicateForCategorySamples(
        with operatorType: NSComparisonPredicate.Operator,
        value: Int
    ) -> NSPredicate {
        predicateForCategorySamples(with: hkOperatorFromComparison(operatorType), value: value)
    }

    public class func predicateForObjects(
        withMetadataKey key: String,
        operatorType: NSComparisonPredicate.Operator,
        value: Any
    ) -> NSPredicate {
        predicateForObjects(
            withMetadataKey: key,
            operatorType: hkOperatorFromComparison(operatorType),
            value: value
        )
    }

    public class func predicateForQuantitySamples(
        with operatorType: NSComparisonPredicate.Operator,
        quantity: HKQuantity
    ) -> NSPredicate {
        predicateForQuantitySamples(with: hkOperatorFromComparison(operatorType), quantity: quantity)
    }

    public class func predicateForStatesOfMind(
        withValence valence: Double,
        operatorType: NSComparisonPredicate.Operator
    ) -> NSPredicate {
        predicateForStatesOfMind(
            withValence: valence,
            operatorType: hkOperatorFromComparison(operatorType)
        )
    }

    public class func predicateForWorkoutActivities(
        operatorType: NSComparisonPredicate.Operator,
        duration: TimeInterval
    ) -> NSPredicate {
        predicateForWorkoutActivities(
            operatorType: hkOperatorFromComparison(operatorType),
            duration: duration
        )
    }

    public class func predicateForWorkoutActivities(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        averageQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkoutActivities(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            averageQuantity: averageQuantity
        )
    }

    public class func predicateForWorkoutActivities(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        maximumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkoutActivities(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            maximumQuantity: maximumQuantity
        )
    }

    public class func predicateForWorkoutActivities(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        minimumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkoutActivities(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            minimumQuantity: minimumQuantity
        )
    }

    public class func predicateForWorkoutActivities(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        sumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkoutActivities(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            sumQuantity: sumQuantity
        )
    }

    public class func predicateForWorkouts(
        with operatorType: NSComparisonPredicate.Operator,
        duration: TimeInterval
    ) -> NSPredicate {
        predicateForWorkouts(with: hkOperatorFromComparison(operatorType), duration: duration)
    }

    public class func predicateForWorkouts(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        averageQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            averageQuantity: averageQuantity
        )
    }

    public class func predicateForWorkouts(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        maximumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            maximumQuantity: maximumQuantity
        )
    }

    public class func predicateForWorkouts(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        minimumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            minimumQuantity: minimumQuantity
        )
    }

    public class func predicateForWorkouts(
        operatorType: NSComparisonPredicate.Operator,
        quantityType: HKQuantityType,
        sumQuantity: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            operatorType: hkOperatorFromComparison(operatorType),
            quantityType: quantityType,
            sumQuantity: sumQuantity
        )
    }

    public class func predicateForWorkouts(
        with operatorType: NSComparisonPredicate.Operator,
        totalDistance: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(with: hkOperatorFromComparison(operatorType), totalDistance: totalDistance)
    }

    public class func predicateForWorkouts(
        with operatorType: NSComparisonPredicate.Operator,
        totalEnergyBurned: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            with: hkOperatorFromComparison(operatorType),
            totalEnergyBurned: totalEnergyBurned
        )
    }

    public class func predicateForWorkouts(
        with operatorType: NSComparisonPredicate.Operator,
        totalFlightsClimbed: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            with: hkOperatorFromComparison(operatorType),
            totalFlightsClimbed: totalFlightsClimbed
        )
    }

    public class func predicateForWorkouts(
        with operatorType: NSComparisonPredicate.Operator,
        totalSwimmingStrokeCount: HKQuantity
    ) -> NSPredicate {
        predicateForWorkouts(
            with: hkOperatorFromComparison(operatorType),
            totalSwimmingStrokeCount: totalSwimmingStrokeCount
        )
    }
}

extension HKCategoryValuePredicateProviding where RawValue == Int {
    /// Apple `HKCategoryValuePredicateProviding` operator overload. Delegates
    /// to the local value comparison; the raw-value mapping is oracle-pinned.
    public static func predicateForSamples(
        _ operatorType: NSComparisonPredicate.Operator,
        value: Self
    ) -> NSPredicate {
        HKQuery.predicateForCategorySamples(
            with: hkOperatorFromComparison(operatorType),
            value: value.rawValue
        )
    }
}

extension HKAttachment {
    /// Local content-type projection. Attachments added from a file URL record
    /// the caller-supplied `UTType`; attachments created from raw data report
    /// `.data`. No Apple attachment daemon or iCloud Health sharing is used.
    public var contentType: UTType {
        UTType(_contentTypeIdentifier) ?? .data
    }
}

extension HKAttachmentStore {
    /// Local file-URL attachment add. The file at `url` is copied into the
    /// in-process attachment byte table (not the Apple Health attachment
    /// daemon). Unreadable URLs fail-closed through the completion handler.
    public func addAttachment(
        to object: HKObject,
        name: String,
        contentType: UTType,
        url: URL,
        metadata: [String: Any] = [:],
        completion: @escaping (HKAttachment?, (any Error)?) -> Void
    ) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            completion(nil, error)
            return
        }
        let attachment = HKAttachment(name: name, size: data.count, metadata: metadata)
        attachment._contentTypeIdentifier = contentType.identifier
        HKHealthStorePortable._addAttachment(attachment, data: data, to: object.uuid)
        completion(attachment, nil)
    }

    /// Async file-URL attachment add with the same local copy semantics.
    public func addAttachment(
        to object: HKObject,
        name: String,
        contentType: UTType,
        url: URL,
        metadata: [String: Any] = [:]
    ) async throws -> HKAttachment {
        let data = try Data(contentsOf: url)
        let attachment = HKAttachment(name: name, size: data.count, metadata: metadata)
        attachment._contentTypeIdentifier = contentType.identifier
        HKHealthStorePortable._addAttachment(attachment, data: data, to: object.uuid)
        return attachment
    }
}
