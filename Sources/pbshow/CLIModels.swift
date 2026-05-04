import Foundation
import AppKit

enum ClipboardType: Hashable {
    enum Known: CaseIterable {
        case html
        case rtf
        case plainText
        case utf16PlainText
        case tabularText
        case fileURL
        case url
        case chromiumSourceURL

        var rawValue: String {
            switch self {
            case .html:
                // public.html
                return NSPasteboard.PasteboardType.html.rawValue
            case .rtf:
                // public.rtf
                return NSPasteboard.PasteboardType.rtf.rawValue
            case .plainText:
                // public.utf8-plain-text
                return NSPasteboard.PasteboardType.string.rawValue
            case .utf16PlainText:
                return "public.utf16-external-plain-text"
            case .tabularText:
                // public.utf8-tab-separated-values-text
                return NSPasteboard.PasteboardType.tabularText.rawValue
            case .fileURL:
                // public.file-url
                return NSPasteboard.PasteboardType.fileURL.rawValue
            case .url:
                // public.url
                return NSPasteboard.PasteboardType.URL.rawValue
            case .chromiumSourceURL:
                return "org.chromium.source-url"
            }
        }

        init?(rawValue: String) {
            guard let known = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
                return nil
            }
            self = known
        }
    }

    case known(Known)
    case custom(String)

    init(rawValue: String) {
        if let known = Known(rawValue: rawValue) {
            self = .known(known)
        } else {
            self = .custom(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case let .known(known):
            return known.rawValue
        case let .custom(value):
            return value
        }
    }
}

enum Command {
    case show(type: ClipboardType?)
    case list(type: ClipboardType?)
    case export(type: ClipboardType, outputPath: String?)
    case clear
    case help
    case version
}

struct ParsedArguments {
    let command: Command
    let index: Int?
    let force: Bool
}

struct CLIError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
