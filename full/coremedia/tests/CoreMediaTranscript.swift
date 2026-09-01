import CoreMedia

@main
struct CoreMediaTranscript {
    static func main() {
        let half = CMTime(value: 1, timescale: 2)
        let third = CMTime(value: 1, timescale: 3)
        let sum = CMTimeAdd(half, third)
        let difference = CMTimeSubtract(sum, half)
        let scaled = CMTimeConvertScale(
            sum,
            timescale: 12,
            method: .default
        )
        let range = CMTimeRange(
            start: half,
            duration: CMTime(value: 2, timescale: 1)
        )

        print("sum=\(sum.value)/\(sum.timescale):\(sum.seconds)")
        print(
            "sub=\(difference.value)/\(difference.timescale):\(difference.seconds)"
        )
        print(
            "scaled=\(scaled.value)/\(scaled.timescale):\(scaled.hasBeenRounded)"
        )
        print(
            "range=\(range.containsTime(CMTime(value: 2, timescale: 1))):"
                + "\(range.containsTime(range.end))"
        )
    }
}
