// Foundation-family identities that OpenUIKit must own while the Foundation
// umbrella is hidden from its compilation.
//
// UIKit APIs expose these declarations directly. Defining parallel facade
// classes would make an attributed string accepted by UILabel differ from an
// attributed string created by an application, and would leave Timer or user
// activity ambiguous in files importing both UIKit and Foundation. The later
// app-facing Foundation module therefore aliases the exact OpenUIKit types.
import OpenUIKit

public typealias NSAttributedString = OpenUIKit.NSAttributedString
public typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString
public typealias NSParagraphStyle = OpenUIKit.NSParagraphStyle
public typealias NSMutableParagraphStyle = OpenUIKit.NSMutableParagraphStyle
public typealias NSUnderlineStyle = OpenUIKit.NSUnderlineStyle

public typealias Timer = OpenUIKit.Timer
public typealias RunLoop = OpenUIKit.RunLoop

public typealias NSUserActivity = OpenUIKit.NSUserActivity
public typealias NSUserActivityPersistentIdentifier =
    OpenUIKit.NSUserActivityPersistentIdentifier
