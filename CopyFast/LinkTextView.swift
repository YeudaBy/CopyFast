import SwiftUI

struct LinkTextView: View {
    let text: String

    var body: some View {
        Text(makeAttributedString(from: text))
            .font(.body)
            .onTapGesture(perform: handleTap)
            .textSelection(.enabled)
    }

    func makeAttributedString(from string: String) -> AttributedString {
        var attributedString = AttributedString(string)

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let nsString = NSString(string: string)
            let matches = detector.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                guard let range = Range(match.range, in: string),
                      let url = match.url else { continue }
                let start = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound.utf16Offset(in: string))
                let end = attributedString.index(attributedString.startIndex, offsetByCharacters: range.upperBound.utf16Offset(in: string))
                let rangeAttributed = start..<end

                attributedString[rangeAttributed].link = url
                attributedString[rangeAttributed].foregroundColor = .blue
                attributedString[rangeAttributed].underlineStyle = .single
            }
        }
        return attributedString
    }

    func handleTap() {
        print("url \(text)! opened")
    }
}
