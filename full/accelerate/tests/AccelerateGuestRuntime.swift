import Accelerate

@main
enum AccelerateGuestRuntime {
    static func main() {
        var source: [UInt8] = [
            10, 0, 1, 2,   20, 3, 4, 5,   30, 6, 7, 8,
            40, 9, 10, 11, 50, 12, 13, 14, 60, 15, 16, 17,
            70, 18, 19, 20, 80, 21, 22, 23, 90, 24, 25, 26
        ]
        var output = [UInt8](repeating: 0, count: source.count)
        let status = source.withUnsafeMutableBytes { sourceBytes in
            output.withUnsafeMutableBytes { outputBytes in
                var input = vImage_Buffer(
                    data: sourceBytes.baseAddress,
                    height: 3,
                    width: 3,
                    rowBytes: 12
                )
                var destination = vImage_Buffer(
                    data: outputBytes.baseAddress,
                    height: 3,
                    width: 3,
                    rowBytes: 12
                )
                return vImageBoxConvolve_ARGB8888(
                    &input,
                    &destination,
                    nil,
                    0,
                    0,
                    3,
                    3,
                    nil,
                    vImage_Flags(kvImageEdgeExtend)
                )
            }
        }
        let expected: [UInt8] = [
            23, 4, 5, 6,   30, 6, 7, 8,   37, 8, 9, 10,
            43, 10, 11, 12, 50, 12, 13, 14, 57, 14, 15, 16,
            63, 16, 17, 18, 70, 18, 19, 20, 77, 20, 21, 22
        ]
        precondition(status == kvImageNoError)
        precondition(output == expected)
        print("ACCELERATE_GUEST_OK vimage=box-convolve,argb8888 edge=extend apple-transcript=exact")
    }
}
