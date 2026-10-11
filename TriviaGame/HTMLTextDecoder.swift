import Foundation

enum HTMLTextDecoder {
    private static let namedEntities: [String: String] = [
        "amp": "&",
        "apos": "'",
        "gt": ">",
        "lt": "<",
        "nbsp": "\u{00A0}",
        "quot": "\""
    ]

    static func decode(_ text: String) -> String {
        var result = ""
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            guard text[currentIndex] == "&",
                  let semicolonIndex = text[currentIndex...].firstIndex(of: ";") else {
                result.append(text[currentIndex])
                currentIndex = text.index(after: currentIndex)
                continue
            }

            let entityStart = text.index(after: currentIndex)
            let entity = String(text[entityStart..<semicolonIndex])

            if let decodedEntity = decodeEntity(entity) {
                result.append(decodedEntity)
                currentIndex = text.index(after: semicolonIndex)
            } else {
                result.append(text[currentIndex])
                currentIndex = text.index(after: currentIndex)
            }
        }

        return result
    }

    private static func decodeEntity(_ entity: String) -> String? {
        if let namedEntity = namedEntities[entity] {
            return namedEntity
        }

        guard entity.hasPrefix("#") else { return nil }

        let numberText = entity.dropFirst()
        let scalarValue: UInt32?

        if numberText.hasPrefix("x") || numberText.hasPrefix("X") {
            scalarValue = UInt32(numberText.dropFirst(), radix: 16)
        } else {
            scalarValue = UInt32(numberText, radix: 10)
        }

        guard let scalarValue,
              let scalar = UnicodeScalar(scalarValue) else {
            return nil
        }

        return String(Character(scalar))
    }
}
