import Foundation
import ModelIO

func testConvertToUSDZFailClosed() {
    let directory = mdlTempDir()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let input = directory.appendingPathComponent("in.obj")
    try! "v 0 0 0\n".write(to: input, atomically: true, encoding: .utf8)
    let output = directory.appendingPathComponent("out.usdz")
    MDLUtility.convert(toUSDZ: input, writeTo: output)
    mdlCheck(!FileManager.default.fileExists(atPath: output.path), "USDZ conversion must not fabricate a file")
    _ = MDLUtility()
}
