import Foundation

/// Parse Xcode `contents` XML (`.xcdatamodel` / `.xcdatamodeld`). Compiled
/// binary `.mom` / `.momd` payloads stay fail-closed (return nil).

func _CDLoadManagedObjectModel(from url: URL) -> NSManagedObjectModel? {
    let path = url.path
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
        return nil
    }
    if isDirectory.boolValue {
        return _CDLoadModelDirectory(url)
    }
    if path.hasSuffix(".mom") {
        return nil
    }
    guard let data = try? Data(contentsOf: url), !data.isEmpty else {
        return nil
    }
    if data.first != UInt8(ascii: "<") && data.first != UInt8(ascii: "?") {
        return nil
    }
    guard let xml = String(data: data, encoding: .utf8) else {
        return nil
    }
    return _CDParseModelXML(xml)
}

private func _CDLoadModelDirectory(_ url: URL) -> NSManagedObjectModel? {
    let path = url.path
    if path.hasSuffix(".momd") {
        let contents = _CDFindContentsXML(in: url)
        if let contents {
            return _CDParseModelXML(contents)
        }
        return nil
    }
    if path.hasSuffix(".xcdatamodeld") {
        let current = _CDCurrentXcdatamodel(in: url) ?? _CDFirstXcdatamodel(in: url)
        guard let current else { return nil }
        return _CDLoadManagedObjectModel(from: current)
    }
    if path.hasSuffix(".xcdatamodel") {
        let contentsURL = url.appendingPathComponent("contents")
        return _CDLoadManagedObjectModel(from: contentsURL)
    }
    let contentsURL = url.appendingPathComponent("contents")
    if FileManager.default.fileExists(atPath: contentsURL.path) {
        return _CDLoadManagedObjectModel(from: contentsURL)
    }
    return nil
}

private func _CDCurrentXcdatamodel(in bundle: URL) -> URL? {
    let marker = bundle.appendingPathComponent(".xccurrentversion")
    guard let data = try? Data(contentsOf: marker),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
          let name = plist["_XCCurrentVersionName"] as? String else {
        return nil
    }
    let candidate = bundle.appendingPathComponent(name)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory) else {
        return nil
    }
    return candidate
}

private func _CDFirstXcdatamodel(in bundle: URL) -> URL? {
    let children = (try? FileManager.default.contentsOfDirectory(at: bundle, includingPropertiesForKeys: nil)) ?? []
    return children.first { $0.path.hasSuffix(".xcdatamodel") }
}

private func _CDFindContentsXML(in directory: URL) -> String? {
    let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
    while let item = enumerator?.nextObject() as? URL {
        if item.lastPathComponent == "contents",
           let data = try? Data(contentsOf: item),
           data.first == UInt8(ascii: "<") || data.first == UInt8(ascii: "?"),
           let xml = String(data: data, encoding: .utf8) {
            return xml
        }
    }
    return nil
}

func _CDParseModelXML(_ xml: String) -> NSManagedObjectModel? {
    guard xml.contains("<model") else { return nil }
    let model = NSManagedObjectModel()
    if let version = _CDXMLAttr(_CDXMLOpenTag(xml, tag: "model") ?? "", "userDefinedModelVersionIdentifier"),
       !version.isEmpty {
        model.versionIdentifiers = [version]
    }
    guard let entityRegex = try? NSRegularExpression(
        pattern: "<entity\\b([^>]*)>(.*?)</entity>",
        options: [.dotMatchesLineSeparators]
    ) else {
        return nil
    }
    let nsxml = xml as NSString
    let full = NSRange(location: 0, length: nsxml.length)
    let entityMatches = entityRegex.matches(in: xml, options: [], range: full)
    var entities: [NSEntityDescription] = []
    var relationshipSpecs: [(NSRelationshipDescription, destination: String, inverse: String?)] = []
    for match in entityMatches {
        guard match.numberOfRanges >= 3 else { continue }
        let openAttrs = nsxml.substring(with: match.range(at: 1))
        let inner = nsxml.substring(with: match.range(at: 2))
        let entity = NSEntityDescription()
        entity.name = _CDXMLAttr(" " + openAttrs, "name")
        entity.managedObjectClassName = _CDXMLAttr(" " + openAttrs, "representedClassName") ?? "NSManagedObject"
        entity.isAbstract = _CDXMLAttr(" " + openAttrs, "isAbstract") == "YES"
        entity.renamingIdentifier = _CDXMLAttr(" " + openAttrs, "renamingIdentifier")
        var properties: [NSPropertyDescription] = []
        for attributeXML in _CDXMLSelfClosing(inner, tag: "attribute") {
            let attribute = NSAttributeDescription()
            attribute.name = _CDXMLAttr(attributeXML, "name") ?? ""
            attribute.isOptional = _CDXMLAttr(attributeXML, "optional") != "NO"
            attribute.isTransient = _CDXMLAttr(attributeXML, "transient") == "YES"
            attribute.isIndexed = _CDXMLAttr(attributeXML, "indexed") == "YES"
            attribute.attributeType = _CDAttributeType(fromXML: _CDXMLAttr(attributeXML, "attributeType") ?? "")
            if let defaultString = _CDXMLAttr(attributeXML, "defaultValueString") {
                attribute.defaultValue = _CDDefaultValue(defaultString, type: attribute.attributeType)
            }
            properties.append(attribute)
        }
        for relationshipXML in _CDXMLSelfClosing(inner, tag: "relationship") {
            let relationship = NSRelationshipDescription()
            relationship.name = _CDXMLAttr(relationshipXML, "name") ?? ""
            relationship.isOptional = _CDXMLAttr(relationshipXML, "optional") != "NO"
            relationship.isTransient = _CDXMLAttr(relationshipXML, "transient") == "YES"
            relationship.isOrdered = _CDXMLAttr(relationshipXML, "ordered") == "YES"
            relationship.deleteRule = _CDDeleteRule(fromXML: _CDXMLAttr(relationshipXML, "deletionRule") ?? "")
            if let max = _CDXMLAttr(relationshipXML, "maxCount"), let value = Int(max) {
                relationship.maxCount = value
            } else if _CDXMLAttr(relationshipXML, "toMany") == "YES" {
                relationship.maxCount = 0
            } else {
                relationship.maxCount = 1
            }
            if let min = _CDXMLAttr(relationshipXML, "minCount"), let value = Int(min) {
                relationship.minCount = value
            }
            properties.append(relationship)
            relationshipSpecs.append(
                (
                    relationship,
                    destination: _CDXMLAttr(relationshipXML, "destinationEntity") ?? "",
                    inverse: _CDXMLAttr(relationshipXML, "inverseName")
                )
            )
        }
        if let fetchedRegex = try? NSRegularExpression(
            pattern: "<fetchedProperty\\b([^>]*)>(.*?)</fetchedProperty>",
            options: [.dotMatchesLineSeparators]
        ) {
            let innerNS = inner as NSString
            for fetchedMatch in fetchedRegex.matches(in: inner, options: [], range: NSRange(location: 0, length: innerNS.length)) {
                guard fetchedMatch.numberOfRanges >= 3 else { continue }
                let fetchedAttrs = innerNS.substring(with: fetchedMatch.range(at: 1))
                let fetchedInner = innerNS.substring(with: fetchedMatch.range(at: 2))
                let fetched = NSFetchedPropertyDescription()
                fetched.name = _CDXMLAttr(" " + fetchedAttrs, "name") ?? ""
                fetched.isOptional = _CDXMLAttr(" " + fetchedAttrs, "optional") != "NO"
                fetched.isTransient = true
                if let request = _CDXMLSelfClosing(fetchedInner, tag: "fetchRequest").first {
                    let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(
                        entityName: _CDXMLAttr(request, "entity") ?? (entity.name ?? "")
                    )
                    if let predicate = _CDXMLAttr(request, "predicateString"), !predicate.isEmpty {
                        fetchRequest.predicate = NSPredicate { object, _ in
                            _ = object
                            return true
                        }
                    }
                    fetched.fetchRequest = fetchRequest
                }
                properties.append(fetched)
            }
        }
        var uniqueness: [[Any]] = []
        if let constraintRegex = try? NSRegularExpression(
            pattern: "<uniquenessConstraint>(.*?)</uniquenessConstraint>",
            options: [.dotMatchesLineSeparators]
        ) {
            let innerNS = inner as NSString
            for constraintMatch in constraintRegex.matches(in: inner, options: [], range: NSRange(location: 0, length: innerNS.length)) {
                guard constraintMatch.numberOfRanges >= 2 else { continue }
                let block = innerNS.substring(with: constraintMatch.range(at: 1))
                let values = _CDXMLSelfClosing(block, tag: "constraint").compactMap { _CDXMLAttr($0, "value") }
                if !values.isEmpty {
                    uniqueness.append(values)
                }
            }
        }
        entity.uniquenessConstraints = uniqueness
        entity.properties = properties
        entities.append(entity)
    }
    model.entities = entities
    let byName = model.entitiesByName
    for (relationship, destination, inverse) in relationshipSpecs {
        relationship.destinationEntity = byName[destination]
        if let inverse, let dest = byName[destination] {
            relationship.inverseRelationship = dest.relationshipsByName[inverse]
        }
    }
    return model.entities.isEmpty ? nil : model
}

func _CDStableData(_ parts: [String]) -> Data {
    Data(parts.joined(separator: "|").utf8)
}

private func _CDAttributeType(fromXML text: String) -> NSAttributeType {
    switch text {
    case "Integer 16": return .integer16AttributeType
    case "Integer 32": return .integer32AttributeType
    case "Integer 64": return .integer64AttributeType
    case "Decimal": return .decimalAttributeType
    case "Double": return .doubleAttributeType
    case "Float": return .floatAttributeType
    case "String": return .stringAttributeType
    case "Boolean": return .booleanAttributeType
    case "Date": return .dateAttributeType
    case "Binary", "Binary data": return .binaryDataAttributeType
    case "UUID": return .UUIDAttributeType
    case "URI": return .URIAttributeType
    case "Transformable": return .transformableAttributeType
    case "ObjectID": return .objectIDAttributeType
    case "Composite": return .compositeAttributeType
    default: return .undefinedAttributeType
    }
}

private func _CDDeleteRule(fromXML text: String) -> NSDeleteRule {
    switch text {
    case "Cascade": return .cascadeDeleteRule
    case "Deny": return .denyDeleteRule
    case "No Action": return .noActionDeleteRule
    default: return .nullifyDeleteRule
    }
}

private func _CDDefaultValue(_ text: String, type: NSAttributeType) -> Any? {
    switch type {
    case .stringAttributeType:
        return text
    case .booleanAttributeType:
        return text == "YES" || text.lowercased() == "true"
    case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
        return Int(text) ?? 0
    case .doubleAttributeType, .floatAttributeType, .decimalAttributeType:
        return Double(text) ?? 0
    default:
        return text
    }
}

private func _CDXMLSelfClosing(_ xml: String, tag: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: "<\(tag)\\b[^>]*/>") else { return [] }
    let nsxml = xml as NSString
    return regex.matches(in: xml, range: NSRange(location: 0, length: nsxml.length)).map {
        nsxml.substring(with: $0.range)
    }
}

private func _CDXMLOpenTag(_ xml: String, tag: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: "<\(tag)\\b[^>]*>") else { return nil }
    let nsxml = xml as NSString
    guard let match = regex.firstMatch(in: xml, range: NSRange(location: 0, length: nsxml.length)) else {
        return nil
    }
    return nsxml.substring(with: match.range)
}

private func _CDXMLAttr(_ tag: String, _ name: String) -> String? {
    let escaped = NSRegularExpression.escapedPattern(for: name)
    guard let regex = try? NSRegularExpression(pattern: "(?:^|[\\s<])\(escaped)=\"([^\"]*)\"") else {
        return nil
    }
    let ns = tag as NSString
    guard let match = regex.firstMatch(in: tag, range: NSRange(location: 0, length: ns.length)),
          match.numberOfRanges > 1 else {
        return nil
    }
    return ns.substring(with: match.range(at: 1))
}
