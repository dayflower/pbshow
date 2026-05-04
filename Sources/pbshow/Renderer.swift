import AppKit
import Foundation

struct Renderer {
    private let output = OutputWriter.standard
    private static let textTypes: Set<String> = [
        NSPasteboard.PasteboardType.html.rawValue,
        NSPasteboard.PasteboardType.rtf.rawValue,
        NSPasteboard.PasteboardType.string.rawValue,
        "public.utf16-external-plain-text",
        NSPasteboard.PasteboardType.tabularText.rawValue,
        NSPasteboard.PasteboardType.fileURL.rawValue,
        NSPasteboard.PasteboardType.URL.rawValue,
        "org.chromium.source-url"
    ]

    func renderShow(snapshot: ClipboardSnapshot, targetIndexes: [Int], typeFilter: String?, force: Bool) {
        guard !snapshot.items.isEmpty else {
            output.writeLine("[Clipboard contents]")
            output.writeLine("changeCount: \(snapshot.changeCount)")
            output.writeLine("items: 0")
            output.writeLine("targets: []")
            output.writeLine()
            output.writeLine("Clipboard is empty.")
            return
        }

        output.writeLine("[Clipboard contents]")
        output.writeLine("changeCount: \(snapshot.changeCount)")
        output.writeLine("items: \(snapshot.items.count)")
        output.writeLine("targets: \(targetIndexes.map(String.init).joined(separator: ", "))")

        for itemIndex in targetIndexes {
            let item = snapshot.items[itemIndex]
            output.writeLine()
            output.writeLine("===== item #\(itemIndex) =====")

            let filteredTypes = filterTypes(item.types, by: typeFilter)
            if filteredTypes.isEmpty {
                if let typeFilter {
                    output.writeLine("(type not found: \(typeFilter))")
                } else {
                    output.writeLine("(no types)")
                }
                continue
            }

            for rawType in filteredTypes {
                output.writeLine()
                output.writeLine("---")
                output.writeLine("type: \(rawType)")

                guard let data = item.data(forType: rawType) else {
                    output.writeLine("(no data)")
                    continue
                }

                output.writeLine("size: \(data.count) bytes")

                if shouldRenderAsText(type: rawType, force: force), let text = decodeText(from: data) {
                    output.writeLine()
                    writeRawToStdout(text)
                    if !text.hasSuffix("\n") {
                        output.writeLine()
                    }
                } else {
                    output.writeLine("view: hex")
                    output.writeLine()
                    output.writeLine(hexDump(data: data, maxBytes: 256))
                }
            }
        }
    }

    func renderList(snapshot: ClipboardSnapshot, targetIndexes: [Int], typeFilter: String?) {
        guard !snapshot.items.isEmpty else {
            output.writeLine("clipboard:")
            output.writeLine("  changeCount: \(snapshot.changeCount)")
            output.writeLine("  items: []")
            return
        }

        output.writeLine("clipboard:")
        output.writeLine("  changeCount: \(snapshot.changeCount)")
        output.writeLine("  totalItems: \(snapshot.items.count)")
        output.writeLine("  targets: [\(targetIndexes.map(String.init).joined(separator: ", "))]")
        output.writeLine("  items:")

        for itemIndex in targetIndexes {
            let item = snapshot.items[itemIndex]
            let filteredTypes = filterTypes(item.types, by: typeFilter)

            output.writeLine("    - index: \(itemIndex)")
            output.writeLine("      formats:")
            if filteredTypes.isEmpty {
                output.writeLine("        []")
                continue
            }

            for rawType in filteredTypes {
                let size = item.data(forType: rawType)?.count ?? 0
                output.writeLine("        - type: \"\(escapeYAMLString(rawType))\"")
                output.writeLine("          size: \(size)")
            }
        }
    }

    func printClearCompleted() {
        output.writeLine("Clipboard cleared.")
    }

    private func shouldRenderAsText(type: String, force: Bool) -> Bool {
        force || Self.textTypes.contains(type)
    }

    private func filterTypes(_ types: [String], by typeFilter: String?) -> [String] {
        guard let typeFilter else {
            return types
        }
        return types.filter { $0 == typeFilter }
    }

    private func decodeText(from data: Data) -> String? {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .utf32LittleEndian,
            .utf32BigEndian,
            .ascii,
            .isoLatin1,
            .nonLossyASCII
        ]

        for encoding in encodings {
            if let text = String(data: data, encoding: encoding), !text.isEmpty {
                return text
            }
        }

        return nil
    }

    private func hexDump(data: Data, maxBytes: Int) -> String {
        let shownData = data.prefix(maxBytes)
        var lines: [String] = []

        for offset in stride(from: 0, to: shownData.count, by: 16) {
            let chunk = shownData.dropFirst(offset).prefix(16)

            let hex = chunk.map { String(format: "%02x", $0) }.joined(separator: " ")
            let paddedHex = hex.padding(toLength: 16 * 3 - 1, withPad: " ", startingAt: 0)

            let ascii = chunk.map { byte -> Character in
                if (0x20...0x7e).contains(byte) {
                    return Character(UnicodeScalar(byte))
                }
                return "."
            }

            lines.append(String(format: "%04x  %@  |%@|", offset, paddedHex, String(ascii)))
        }

        if data.count > maxBytes {
            lines.append("... truncated: showing first \(maxBytes) of \(data.count) bytes")
        }

        return lines.joined(separator: "\n")
    }

    private func escapeYAMLString(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func writeRawToStdout(_ text: String) {
        output.write(text)
    }
}
