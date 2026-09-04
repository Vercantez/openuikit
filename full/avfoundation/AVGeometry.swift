import Foundation

public func AVMakeRect(aspectRatio: CGSize, insideRect boundingRect: CGRect) -> CGRect {
    guard aspectRatio.width > 0, aspectRatio.height > 0,
          boundingRect.width > 0, boundingRect.height > 0
    else {
        return .zero
    }
    let scale = min(
        boundingRect.width / aspectRatio.width,
        boundingRect.height / aspectRatio.height
    )
    let width = aspectRatio.width * scale
    let height = aspectRatio.height * scale
    return CGRect(
        x: boundingRect.midX - width / 2,
        y: boundingRect.midY - height / 2,
        width: width,
        height: height
    )
}
