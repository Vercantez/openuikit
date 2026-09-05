@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testUnitSymbols() {
    mxRequire(MXUnitAveragePixelLuminance.apl.symbol == "apl", "testUnitSymbols: apl")
    mxRequire(MXUnitSignalBars.bars.symbol == "bars", "testUnitSymbols: bars")
    mxRequire(
        MXUnitAveragePixelLuminance.apl === MXUnitAveragePixelLuminance.baseUnit(),
        "testUnitSymbols: apl baseUnit"
    )
    mxRequire(MXUnitSignalBars.bars === MXUnitSignalBars.baseUnit(), "testUnitSymbols: bars baseUnit")
}

func testHistogramAndAverageGetters() {
    let average = MXAverage(
        averageMeasurement: Measurement(value: 12.5, unit: MXUnitAveragePixelLuminance.apl),
        sampleCount: 4,
        standardDeviation: 1.25
    )
    mxRequire(average.averageMeasurement.value == 12.5, "testHistogramAndAverageGetters: averageMeasurement")
    mxRequire(average.sampleCount == 4, "testHistogramAndAverageGetters: sampleCount")
    mxRequire(average.standardDeviation == 1.25, "testHistogramAndAverageGetters: standardDeviation")

    let start = Measurement(value: 0, unit: UnitDuration.seconds)
    let end = Measurement(value: 1, unit: UnitDuration.seconds)
    let bucket = MXHistogramBucket(bucketStart: start, bucketEnd: end, bucketCount: 7)
    mxRequire(bucket.bucketStart.value == 0, "testHistogramAndAverageGetters: bucketStart")
    mxRequire(bucket.bucketEnd.value == 1, "testHistogramAndAverageGetters: bucketEnd")
    mxRequire(bucket.bucketCount == 7, "testHistogramAndAverageGetters: bucketCount")

    let histogram = MXHistogram(buckets: [bucket])
    mxRequire(histogram.totalBucketCount == 1, "testHistogramAndAverageGetters: totalBucketCount")
    var collected = 0
    let enumerator = histogram.bucketEnumerator
    while let object = enumerator.nextObject() {
        let item = object as? MXHistogramBucket<UnitDuration>
        mxRequire(item?.bucketCount == 7, "testHistogramAndAverageGetters: enumerated bucket")
        collected += 1
    }
    mxRequire(collected == 1, "testHistogramAndAverageGetters: bucketEnumerator")
}
