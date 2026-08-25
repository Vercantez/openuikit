// Coarse render-path phase timers (perf work, M8). Owner: view module.
//
// The library never reads clocks itself (no Date(), no Foundation): a HOST
// that wants a breakdown injects a monotonic nanosecond source (openhost
// uses SDL_GetPerformanceCounter) and flips `enabled`. When disabled (the
// default) the instrumentation is a single boolean check per phase.
//
// Phases (accumulated nanoseconds across frames until reset()):
//   build    — QZLayer tree construction (excluding content rasterization)
//   content  — drawContent offscreen rasterization (glyphs, icons, chrome)
//   upload   — offscreen post-processing: transparency scan, row flip,
//              QZImageCreate (straight→premul conversion into quartz)
//   composite— QZLayerRenderInContext (quartz layer compositing)
//   convert  — premultiplied backing → straight-alpha Bitmap copy-out
//   context  — QZBitmapContext create/release per frame

public enum RenderStats {
    /// Host-injected monotonic nanosecond clock. nil (default) = timers off.
    public static var nowNanos: (() -> UInt64)?
    public static var enabled = false

    public static var buildNs: UInt64 = 0
    public static var contentNs: UInt64 = 0
    public static var uploadNs: UInt64 = 0
    public static var compositeNs: UInt64 = 0
    public static var convertNs: UInt64 = 0
    public static var contextNs: UInt64 = 0

    public static var frames = 0
    public static var layerCount = 0
    public static var contentLayerCount = 0
    public static var contentCacheHits = 0
    public static var contentCacheMisses = 0

    public static func reset() {
        buildNs = 0; contentNs = 0; uploadNs = 0; compositeNs = 0
        convertNs = 0; contextNs = 0
        frames = 0; layerCount = 0; contentLayerCount = 0
        contentCacheHits = 0; contentCacheMisses = 0
    }

    @inline(__always)
    static func mark() -> UInt64 {
        guard enabled, let now = nowNanos else { return 0 }
        return now()
    }

    @inline(__always)
    static func accumulate(_ counter: inout UInt64, since t0: UInt64) {
        guard enabled, t0 != 0, let now = nowNanos else { return }
        counter &+= now() &- t0
    }
}
