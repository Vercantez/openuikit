import Foundation

extension JSCBox {
    func reachableBoxes() -> [JSCBox] {
        guard let object else { return [] }
        var out: [JSCBox] = []
        if let prototype = object.prototype { out.append(prototype) }
        out.append(contentsOf: object.values.values)
        if let arrayBufferBox = object.arrayBufferBox { out.append(arrayBufferBox) }
        if let promiseResult = object.promiseResult { out.append(promiseResult) }
        for item in object.thenQueue {
            if let onFulfilled = item.onFulfilled { out.append(onFulfilled) }
            if let onRejected = item.onRejected { out.append(onRejected) }
            out.append(item.successor)
        }
        if case .script(_, _, _, let environment) = object.function {
            out.append(contentsOf: environment.values.values)
        }
        return out
    }
}

extension JSContext {
    func collectGarbage() {
        var marked = Set<ObjectIdentifier>()
        var stack: [JSCBox] = [globalBox]
        virtualMachine.lock.lock()
        for box in virtualMachine.heap where box.protectCount > 0 {
            stack.append(box)
        }
        virtualMachine.lock.unlock()
        while let box = stack.popLast() {
            let identity = ObjectIdentifier(box)
            if marked.contains(identity) { continue }
            marked.insert(identity)
            stack.append(contentsOf: box.reachableBoxes())
        }
        virtualMachine.lock.lock()
        let previous = virtualMachine.heap
        var kept: [JSCBox] = []
        var dropped: [JSCBox] = []
        for box in previous {
            if marked.contains(ObjectIdentifier(box)) {
                kept.append(box)
            } else {
                box.interned = false
                dropped.append(box)
            }
        }
        virtualMachine.heap = kept
        virtualMachine.lock.unlock()
        for box in dropped {
            box.object?.finalizeClassIfNeeded(box)
        }
    }

    func classChain(_ object: JSCObject) -> [JSCClass] {
        var chain: [JSCClass] = []
        var current = object.jsClass
        while let cls = current {
            chain.append(cls)
            current = cls.parent
        }
        return chain
    }

    func staticValueEntry(_ object: JSCObject, name: String) -> JSStaticValue? {
        for cls in classChain(object) {
            guard let pointer = cls.definition.staticValues else { continue }
            var index = 0
            while true {
                let entry = pointer.advanced(by: index).pointee
                guard let namePointer = entry.name else { break }
                if String(cString: namePointer) == name { return entry }
                index += 1
            }
        }
        return nil
    }

    func staticFunctionEntry(_ object: JSCObject, name: String) -> JSStaticFunction? {
        for cls in classChain(object) {
            guard let pointer = cls.definition.staticFunctions else { continue }
            var index = 0
            while true {
                let entry = pointer.advanced(by: index).pointee
                guard let namePointer = entry.name else { break }
                if String(cString: namePointer) == name { return entry }
                index += 1
            }
        }
        return nil
    }

    func invokeGetProperty(
        _ callback: JSObjectGetPropertyCallback,
        object: JSCBox,
        name: String
    ) throws -> JSCBox? {
        var exception: JSValueRef?
        let ref = callback(
            JSCRef.unretained(self),
            JSCRef.unretained(object),
            JSCRef.unretained(virtualMachine.intern(JSCString(name))),
            &exception
        )
        if let exception, let thrown = JSCRef.takeUnretained(exception, as: JSCBox.self) {
            throw JSCJump.thrown(thrown)
        }
        if let ref { return JSCRef.takeUnretained(ref, as: JSCBox.self) }
        return nil
    }

    func initializeClassObject(_ box: JSCBox, jsClass: JSCClass, ctx: JSContextRef?) {
        var order: [JSCClass] = []
        var current: JSCClass? = jsClass
        while let cls = current {
            order.append(cls)
            current = cls.parent
        }
        for cls in order.reversed() {
            cls.definition.initialize?(ctx, JSCRef.unretained(box))
        }
    }

    func convertObject(_ object: JSCBox, to type: JSType) throws -> JSCBox? {
        guard let jsObject = object.object else { return nil }
        for cls in classChain(jsObject) {
            if let convert = cls.definition.convertToType {
                var exception: JSValueRef?
                let ref = convert(JSCRef.unretained(self), JSCRef.unretained(object), type.rawValue, &exception)
                if let exception, let thrown = JSCRef.takeUnretained(exception, as: JSCBox.self) {
                    throw JSCJump.thrown(thrown)
                }
                if let ref, let value = JSCRef.takeUnretained(ref, as: JSCBox.self) {
                    return value
                }
            }
        }
        return nil
    }

    func internedTypedArrayBuffer(_ object: JSCBox) -> JSCBox? {
        if let existing = object.object?.arrayBufferBox { return existing }
        guard let bufferObject = object.object?.arrayBuffer else { return nil }
        let interned = intern(JSCBox(.object(bufferObject)))
        object.object?.arrayBufferBox = interned
        return interned
    }
}
