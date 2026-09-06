import CoreFoundation
import CoreMedia
import Foundation

func testCMAttachmentSetGetPropagateAndCopy() {
    let source = CMBlockBuffer(data: Data([1, 2, 3]))
    let destination = CMBlockBuffer(data: Data([4, 5, 6]))
    let key = kCMFormatDescriptionExtension_FormatName
    let value = "H.264".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    CMSetAttachment(source, key: key, value: value, attachmentMode: kCMAttachmentMode_ShouldPropagate)
    var mode: CMAttachmentMode = kCMAttachmentMode_ShouldNotPropagate
    let fetched = CMGetAttachment(source, key: key, attachmentModeOut: &mode)
    precondition(fetched != nil)
    precondition(mode == kCMAttachmentMode_ShouldPropagate)
    let copied = CMCopyDictionaryOfAttachments(
        allocator: nil,
        target: source,
        attachmentMode: kCMAttachmentMode_ShouldPropagate
    )
    precondition(copied != nil)
    precondition(CFDictionaryGetCount(copied!) == 1)
    CMPropagateAttachments(source, destination: destination)
    var destMode: CMAttachmentMode = 0
    precondition(CMGetAttachment(destination, key: key, attachmentModeOut: &destMode) != nil)
    CMRemoveAttachment(source, key: key)
    precondition(CMGetAttachment(source, key: key, attachmentModeOut: nil) == nil)
}

func testCMAttachmentSetAttachmentsAndRemoveAll() {
    let buffer = CMBlockBuffer(data: Data([9]))
    let key = kCMSampleAttachmentKey_DisplayImmediately
    let flag = kCFBooleanTrue!
    var keyCB = kCFTypeDictionaryKeyCallBacks
    var valCB = kCFTypeDictionaryValueCallBacks
    let dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCB, &valCB)!
    CFDictionarySetValue(
        dict,
        unsafeBitCast(key, to: UnsafeRawPointer.self),
        unsafeBitCast(flag, to: UnsafeRawPointer.self)
    )
    CMSetAttachments(buffer, attachments: dict, attachmentMode: kCMAttachmentMode_ShouldNotPropagate)
    var mode: CMAttachmentMode = kCMAttachmentMode_ShouldPropagate
    precondition(CMGetAttachment(buffer, key: key, attachmentModeOut: &mode) != nil)
    precondition(mode == kCMAttachmentMode_ShouldNotPropagate)
    CMRemoveAllAttachments(buffer)
    precondition(CMGetAttachment(buffer, key: key, attachmentModeOut: nil) == nil)
}
