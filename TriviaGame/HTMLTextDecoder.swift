import UIKit

enum HTMLTextDecoder {
    nonisolated static func decode(_ text: String) -> String {
        guard text.contains("&"), text.contains(";") else { return text }
        guard let data = text.data(using: .utf8) else { return text }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let decodedText = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ).string else {
            return text
        }

        return decodedText
    }
}
