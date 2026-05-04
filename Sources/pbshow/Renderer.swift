import AppKit
import Foundation

struct Renderer {
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
            print("[Clipboard contents]")
            print("changeCount: \(snapshot.changeCount)")
            print("items: 0")
            print("targets: []")
            print("")
            print("Clipboard is empty.")
            return
        }

        print("[Clipboard contents]")
        print("changeCount: \(snapshot.changeCount)")
        print("items: \(snapshot.items.count)")
        print("targets: \(targetIndexes.map(String.init).joined(separator: ", "))")

        for itemIndex in targetIndexes {
            let item = snapshot.items[itemIndex]
            print("")
            print("===== item #\(itemIndex) =====")

            let filteredTypes = filterTypes(item.types, by: typeFilter)
            if filteredTypes.isEmpty {
                if let typeFilter {
                    print("(type not found: \(typeFilter))")
                } else {
                    print("(no types)")
                }
                continue
            }

            for rawType in filteredTypes {
                print("")
                print("---")
                print("type: \(rawType)")

                guard let data = item.data(forType: rawType) else {
                    print("(no data)")
                    continue
                }

                print("size: \(data.count) bytes")

                if shouldRenderAsText(type: rawType, force: force), let text = decodeText(from: data) {
                    print("")
                    writeRawToStdout(text)
                    if !text.hasSuffix("\n") {
                        print("")
                    }
                } else {
                    print("view: hex")
                    print("")
                    print(hexDump(data: data, maxBytes: 256))
                }
            }
        }
    }

    func renderList(snapshot: ClipboardSnapshot, targetIndexes: [Int], typeFilter: String?) {
        guard !snapshot.items.isEmpty else {
            print("clipboard:")
            print("  changeCount: \(snapshot.changeCount)")
            print("  items: []")
            return
        }

        print("clipboard:")
        print("  changeCount: \(snapshot.changeCount)")
        print("  totalItems: \(snapshot.items.count)")
        print("  targets: [\(targetIndexes.map(String.init).joined(separator: ", "))]")
        print("  items:")

        for itemIndex in targetIndexes {
            let item = snapshot.items[itemIndex]
            let filteredTypes = filterTypes(item.types, by: typeFilter)

            print("    - index: \(itemIndex)")
            print("      formats:")
            if filteredTypes.isEmpty {
                print("        []")
                continue
            }

            for rawType in filteredTypes {
                let size = item.data(forType: rawType)?.count ?? 0
                print("        - type: \"\(escapeYAMLString(rawType))\"")
                print("          size: \(size)")
            }
        }
    }

    func printClearCompleted() {
        print("Clipboard cleared.")
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
        if let data = text.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
            return
        }
        print(text, terminator: "")
    }
}
