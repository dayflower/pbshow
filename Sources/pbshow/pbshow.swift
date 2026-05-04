import Foundation

@main
struct pbshow {
    private static let parser = ArgumentParser()
    private static let renderer = Renderer()
    private static let output = OutputWriter.standard
    private typealias ClipboardTargets = (snapshot: ClipboardSnapshot, targetIndexes: [Int])

    static func main() {
        do {
            let parsed = try parser.parse(Array(CommandLine.arguments.dropFirst()))
            try run(parsed)
        } catch let error as CLIError {
            output.writeErrorLine("Error: \(error.message)")
            output.writeErrorLine()
            parser.printHelp()
            Foundation.exit(2)
        } catch {
            output.writeErrorLine("Unexpected error: \(error.localizedDescription)")
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
            parser.printHelp()
        }
    }

    static func runShow(index: Int?, typeFilter: String?, force: Bool) throws {
        let targets = try collectTargetEntries(selectedIndex: index)
        let snapshot = targets.snapshot
        let targetIndexes = targets.targetIndexes
        renderer.renderShow(snapshot: snapshot, targetIndexes: targetIndexes, typeFilter: typeFilter, force: force)
    }

    static func runList(index: Int?, typeFilter: String?) throws {
        let targets = try collectTargetEntries(selectedIndex: index)
        let snapshot = targets.snapshot
        let targetIndexes = targets.targetIndexes
        renderer.renderList(snapshot: snapshot, targetIndexes: targetIndexes, typeFilter: typeFilter)
    }

    static func runExport(type: String, index: Int?, outputPath: String?) throws {
        let clipboardService = ClipboardService()
        let snapshot = clipboardService.fetchSnapshot()
        guard !snapshot.items.isEmpty else {
            throw CLIError("Clipboard is empty.")
        }

        let itemIndex = index ?? 0
        guard itemIndex >= 0 && itemIndex < snapshot.items.count else {
            throw CLIError("Item index out of range: \(itemIndex)")
        }

        guard let data = snapshot.items[itemIndex].data(forType: type) else {
            throw CLIError("Type '\(type)' not found in item #\(itemIndex).")
        }

        if let outputPath {
            let url = URL(fileURLWithPath: outputPath)
            try data.write(to: url)
            output.writeLine("Exported \(data.count) bytes to \(outputPath)")
        } else {
            output.writeData(data)
        }
    }

    static func runClear() {
        let clipboardService = ClipboardService()
        clipboardService.clearContents()
        renderer.printClearCompleted()
    }

    static func resolveTargetIndexes(itemCount: Int, selectedIndex: Int?) throws -> [Int] {
        if let selectedIndex {
            guard selectedIndex >= 0 && selectedIndex < itemCount else {
                throw CLIError("Item index out of range: \(selectedIndex)")
            }
            return [selectedIndex]
        }
        return Array(0..<itemCount)
    }

    private static func collectTargetEntries(selectedIndex: Int?) throws -> ClipboardTargets {
        let clipboardService = ClipboardService()
        let snapshot = clipboardService.fetchSnapshot()

        let targetIndexes: [Int]
        if snapshot.items.isEmpty {
            targetIndexes = []
        } else {
            targetIndexes = try resolveTargetIndexes(itemCount: snapshot.items.count, selectedIndex: selectedIndex)
        }

        return (snapshot: snapshot, targetIndexes: targetIndexes)
    }
}
