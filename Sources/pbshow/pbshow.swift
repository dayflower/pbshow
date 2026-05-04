import AppKit
import Foundation

@main
struct pbshow {
    enum Command {
        case show(type: String?)
        case list(type: String?)
        case export(type: String, outputPath: String?)
        case clear
        case help
    }

    struct ParsedArguments {
        let command: Command
        let index: Int?
        let force: Bool
    }

    static let textTypes: Set<String> = [
        NSPasteboard.PasteboardType.html.rawValue,
        NSPasteboard.PasteboardType.rtf.rawValue,
        NSPasteboard.PasteboardType.string.rawValue,
        "public.utf16-external-plain-text",
        NSPasteboard.PasteboardType.tabularText.rawValue,
        NSPasteboard.PasteboardType.fileURL.rawValue,
        NSPasteboard.PasteboardType.URL.rawValue,
        "org.chromium.source-url"
    ]

    static func main() {
        do {
            let parsed = try parseArguments(Array(CommandLine.arguments.dropFirst()))
            try run(parsed)
        } catch let error as CLIError {
            fputs("Error: \(error.message)\n\n", stderr)
            printHelp()
            Foundation.exit(2)
        } catch {
            fputs("Unexpected error: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    static func run(_ parsed: ParsedArguments) throws {
        switch parsed.command {
        case let .show(typeFilter):
            try runShow(index: parsed.index, typeFilter: typeFilter, force: parsed.force)
        case let .list(typeFilter):
            try runList(index: parsed.index, typeFilter: typeFilter)
        case let .export(type, outputPath):
            try runExport(type: type, index: parsed.index, outputPath: outputPath)
        case .clear:
            runClear()
        case .help:
            printHelp()
        }
    }

    static func runShow(index: Int?, typeFilter: String?, force: Bool) throws {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else {
            print("[Clipboard contents]")
            print("changeCount: \(pasteboard.changeCount)")
            print("items: 0")
            print("targets: []")
            print("")
            print("Clipboard is empty.")
            return
        }

        let targetIndexes = try resolveTargetIndexes(for: items, selectedIndex: index)

        print("[Clipboard contents]")
        print("changeCount: \(pasteboard.changeCount)")
        print("items: \(items.count)")
        print("targets: \(targetIndexes.map(String.init).joined(separator: ", "))")

        for itemIndex in targetIndexes {
            let item = items[itemIndex]
            print("")
            print("===== item #\(itemIndex) =====")

            let types = item.types.map(\.rawValue)
            if types.isEmpty {
                print("(no types)")
                continue
            }

            let filteredTypes: [String]
            if let typeFilter {
                filteredTypes = types.filter { $0 == typeFilter }
            } else {
                filteredTypes = types
            }

            if filteredTypes.isEmpty {
                if let typeFilter {
                    print("(type not found: \(typeFilter))")
                } else {
                    print("(no types)")
                }
                continue
            }

            for rawType in filteredTypes {
                let type = NSPasteboard.PasteboardType(rawValue: rawType)
                print("")
                print("---")
                print("type: \(rawType)")

                guard let data = item.data(forType: type) else {
                    print("(no data)")
                    continue
                }

                print("size: \(data.count) bytes")

                if shouldRenderAsText(type: rawType, force: force), let text = decodeText(from: data) {
                    print("")
                    writeRawToStdout(text)
                    if !text.hasSuffix("\n") { print("") }
                } else {
                    print("view: hex")
                    print("")
                    print(hexDump(data: data, maxBytes: 256))
                }
            }
        }
    }

    static func runExport(type: String, index: Int?, outputPath: String?) throws {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else {
            throw CLIError("Clipboard is empty.")
        }

        let itemIndex = index ?? 0
        guard itemIndex >= 0 && itemIndex < items.count else {
            throw CLIError("Item index out of range: \(itemIndex)")
        }

        let pasteboardType = NSPasteboard.PasteboardType(rawValue: type)
        guard let data = items[itemIndex].data(forType: pasteboardType) else {
            throw CLIError("Type '\(type)' not found in item #\(itemIndex).")
        }

        if let outputPath {
            let url = URL(fileURLWithPath: outputPath)
            try data.write(to: url)
            print("Exported \(data.count) bytes to \(outputPath)")
        } else {
            let out = FileHandle.standardOutput
            out.write(data)
        }
    }

    static func runList(index: Int?, typeFilter: String?) throws {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else {
            print("clipboard:")
            print("  changeCount: \(pasteboard.changeCount)")
            print("  items: []")
            return
        }

        let targetIndexes = try resolveTargetIndexes(for: items, selectedIndex: index)
        print("clipboard:")
        print("  changeCount: \(pasteboard.changeCount)")
        print("  totalItems: \(items.count)")
        print("  targets: [\(targetIndexes.map(String.init).joined(separator: ", "))]")
        print("  items:")

        for itemIndex in targetIndexes {
            let item = items[itemIndex]
            let types = item.types.map(\.rawValue)
            let filteredTypes: [String]
            if let typeFilter {
                filteredTypes = types.filter { $0 == typeFilter }
            } else {
                filteredTypes = types
            }

            print("    - index: \(itemIndex)")
            print("      formats:")
            if filteredTypes.isEmpty {
                print("        []")
                continue
            }

            for rawType in filteredTypes {
                let type = NSPasteboard.PasteboardType(rawValue: rawType)
                let size = item.data(forType: type)?.count ?? 0
                print("        - type: \"\(escapeYAMLString(rawType))\"")
                print("          size: \(size)")
            }
        }
    }

    static func runClear() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        print("Clipboard cleared.")
    }

    static func shouldRenderAsText(type: String, force: Bool) -> Bool {
        force || textTypes.contains(type)
    }

    static func resolveTargetIndexes(for items: [NSPasteboardItem], selectedIndex: Int?) throws -> [Int] {
        if let selectedIndex {
            guard selectedIndex >= 0 && selectedIndex < items.count else {
                throw CLIError("Item index out of range: \(selectedIndex)")
            }
            return [selectedIndex]
        }
        return Array(items.indices)
    }

    static func decodeText(from data: Data) -> String? {
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

    static func hexDump(data: Data, maxBytes: Int) -> String {
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

    static func parseArguments(_ args: [String]) throws -> ParsedArguments {
        if args.contains("-h") || args.contains("--help") {
            return ParsedArguments(command: .help, index: nil, force: false)
        }

        var index: Int?
        var force = false
        var outputPath: String?
        var positionals: [String] = []

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--index":
                i += 1
                guard i < args.count else {
                    throw CLIError("Missing value for \(arg)")
                }
                guard let parsedIndex = Int(args[i]) else {
                    throw CLIError("Invalid index value: \(args[i])")
                }
                index = parsedIndex
            case "-f", "--force":
                force = true
            case "-o", "--output":
                i += 1
                guard i < args.count else {
                    throw CLIError("Missing value for \(arg)")
                }
                outputPath = args[i]
            default:
                positionals.append(arg)
            }
            i += 1
        }

        guard let first = positionals.first else {
            return ParsedArguments(command: .show(type: nil), index: index, force: force)
        }

        switch first {
        case "show":
            let type = positionals.count >= 2 ? positionals[1] : nil
            if positionals.count > 2 {
                throw CLIError("Too many arguments for 'show'")
            }
            return ParsedArguments(command: .show(type: type), index: index, force: force)
        case "list":
            let type = positionals.count >= 2 ? positionals[1] : nil
            if positionals.count > 2 {
                throw CLIError("Too many arguments for 'list'")
            }
            return ParsedArguments(command: .list(type: type), index: index, force: false)
        case "export":
            guard positionals.count >= 2 else {
                throw CLIError("Missing type for 'export'")
            }
            if positionals.count > 2 {
                throw CLIError("Too many arguments for 'export'")
            }
            return ParsedArguments(command: .export(type: positionals[1], outputPath: outputPath), index: index, force: false)
        case "clear":
            return ParsedArguments(command: .clear, index: nil, force: false)
        case "help":
            return ParsedArguments(command: .help, index: nil, force: false)
        default:
            if positionals.count > 1 {
                throw CLIError("Unknown command: \(first)")
            }
            return ParsedArguments(command: .show(type: first), index: index, force: force)
        }
    }

    static func printHelp() {
        print(
"""
pbshow <subcommand> [options]

Global options:
  -h, --help              Show help text.
  -i, --index <n>         Target clipboard item #n.

Subcommands:
  pbshow show [type]
      Show clipboard items and types.
      Without -i, all items are shown.
      -f, --force         Force text rendering for non-text-target types.

  pbshow list [type]
      Show only metadata in YAML format (no body output).
      Without -i, all items are shown.

  pbshow export <type> [-o <path>]
      Export raw data for one type from one clipboard item.
      Without -i, item #0 is used.
      -o, --output <path> Write to a file instead of stdout.

  pbshow clear
      Clear all clipboard data. (ignores -i)

  pbshow help
      Show help text (same as -h/--help).
"""
        )
    }

    static func escapeYAMLString(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func writeRawToStdout(_ text: String) {
        if let data = text.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
            return
        }
        print(text, terminator: "")
    }
}

struct CLIError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
