import Foundation

open class GKQuadtreeNode: NSObject {
    public let quad: GKQuad

    init(quad: GKQuad) {
        self.quad = quad
        super.init()
    }
}

private struct GKSpatialEntry<Element: AnyObject> {
    let element: Element
    let point: vector_float2?
    let quad: GKQuad
    let node: GKQuadtreeNode
}

open class GKQuadtree<ElementType: NSObject>: NSObject {
    private let bounds: GKQuad
    private let minCellSize: Float
    private var entries: [GKSpatialEntry<ElementType>] = []

    public init(boundingQuad quad: GKQuad, minimumCellSize minCellSize: Float) {
        self.bounds = quad
        self.minCellSize = max(minCellSize, 1e-4)
        super.init()
    }

    @discardableResult
    open func add(_ element: ElementType, at point: vector_float2) -> GKQuadtreeNode {
        let quad = GKQuad(quadMin: point, quadMax: point)
        return add(element, in: quad)
    }

    @discardableResult
    open func add(_ element: ElementType, in quad: GKQuad) -> GKQuadtreeNode {
        let node = GKQuadtreeNode(quad: snappedQuad(quad))
        entries.append(GKSpatialEntry(element: element, point: nil, quad: quad, node: node))
        return node
    }

    open func elements(at point: vector_float2) -> [ElementType] {
        elements(in: GKQuad(quadMin: point, quadMax: point))
    }

    open func elements(in quad: GKQuad) -> [ElementType] {
        entries.compactMap { entry in
            gkQuadIntersects(entry.quad, quad) ? entry.element : nil
        }
    }

    @discardableResult
    open func remove(_ element: ElementType) -> Bool {
        let before = entries.count
        entries.removeAll { $0.element === element }
        return entries.count != before
    }

    @discardableResult
    open func remove(_ data: ElementType, using node: GKQuadtreeNode) -> Bool {
        let before = entries.count
        entries.removeAll { $0.element === data && $0.node === node }
        return entries.count != before
    }

    private func snappedQuad(_ quad: GKQuad) -> GKQuad {
        _ = minCellSize
        _ = bounds
        return quad
    }
}

open class GKOctreeNode: NSObject {
    public let box: GKBox

    init(box: GKBox) {
        self.box = box
        super.init()
    }
}

private struct GKOctreeEntry<Element: AnyObject> {
    let element: Element
    let box: GKBox
    let node: GKOctreeNode
}

open class GKOctree<ElementType: NSObject>: NSObject {
    private let bounds: GKBox
    private let minCellSize: Float
    private var entries: [GKOctreeEntry<ElementType>] = []

    public init(boundingBox box: GKBox, minimumCellSize minCellSize: Float) {
        self.bounds = box
        self.minCellSize = max(minCellSize, 1e-4)
        super.init()
    }

    @discardableResult
    open func add(_ element: ElementType, at point: vector_float3) -> GKOctreeNode {
        add(element, in: GKBox(boxMin: point, boxMax: point))
    }

    @discardableResult
    open func add(_ element: ElementType, in box: GKBox) -> GKOctreeNode {
        let node = GKOctreeNode(box: box)
        entries.append(GKOctreeEntry(element: element, box: box, node: node))
        return node
    }

    open func elements(at point: vector_float3) -> [ElementType] {
        elements(in: GKBox(boxMin: point, boxMax: point))
    }

    open func elements(in box: GKBox) -> [ElementType] {
        entries.compactMap { entry in
            gkBoxIntersects(entry.box, box) ? entry.element : nil
        }
    }

    @discardableResult
    open func remove(_ element: ElementType) -> Bool {
        let before = entries.count
        entries.removeAll { $0.element === element }
        return entries.count != before
    }

    @discardableResult
    open func remove(_ element: ElementType, using node: GKOctreeNode) -> Bool {
        let before = entries.count
        entries.removeAll { $0.element === element && $0.node === node }
        return entries.count != before
    }
}

private struct GKRTreeEntry<Element: AnyObject> {
    let element: Element
    let min: vector_float2
    let max: vector_float2
}

open class GKRTree<ElementType: NSObject>: NSObject {
    public var queryReserve: Int = 32
    private let maxChildren: Int
    private var entries: [GKRTreeEntry<ElementType>] = []

    public init(maxNumberOfChildren: Int) {
        self.maxChildren = max(maxNumberOfChildren, 2)
        super.init()
    }

    open func addElement(
        _ element: ElementType,
        boundingRectMin: vector_float2,
        boundingRectMax: vector_float2,
        splitStrategy: GKRTreeSplitStrategy
    ) {
        _ = splitStrategy
        _ = maxChildren
        entries.append(GKRTreeEntry(element: element, min: boundingRectMin, max: boundingRectMax))
    }

    open func removeElement(
        _ element: ElementType,
        boundingRectMin: vector_float2,
        boundingRectMax: vector_float2
    ) {
        entries.removeAll {
            $0.element === element
                && gkDistance($0.min, boundingRectMin) < 1e-5
                && gkDistance($0.max, boundingRectMax) < 1e-5
        }
    }

    open func elements(inBoundingRectMin rectMin: vector_float2, rectMax: vector_float2) -> [ElementType] {
        let query = GKQuad(quadMin: rectMin, quadMax: rectMax)
        return entries.compactMap { entry in
            let quad = GKQuad(quadMin: entry.min, quadMax: entry.max)
            return gkQuadIntersects(quad, query) ? entry.element : nil
        }
    }
}
