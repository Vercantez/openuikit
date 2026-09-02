// Literal Combine import bridge backed by one OpenCombine identity.
//
// Keep implementation out of this module. These aliases make diagnostics and
// qualified source spellings (`Combine.Published`) match the first-party
// framework name while preserving OpenCombine's nominal types.

@_exported import OpenCombine

public typealias ObservableObject = OpenCombine.ObservableObject
public typealias ObservableObjectPublisher = OpenCombine.ObservableObjectPublisher
public typealias Published<Value> = OpenCombine.Published<Value>
