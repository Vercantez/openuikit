// Rung 2/3: a Swift dylib with a C-callable entry point.
@_cdecl("spike_answer")
public func spikeAnswer() -> Int32 { 42 }
