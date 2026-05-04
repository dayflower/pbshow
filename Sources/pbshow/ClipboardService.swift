import AppKit
import Foundation

struct ClipboardItem {
    let types: [String]
    private let dataByType: [String: Data]

    init(types: [String], dataByType: [String: Data]) {
        self.types = types
        self.dataByType = dataByType
    }

    func data(forType type: String) -> Data? {
        dataByType[type]
    }
}

struct ClipboardSnapshot {
    let changeCount: Int
    let items: [ClipboardItem]
}

protocol ClipboardServiceProtocol {
    func fetchSnapshot() -> ClipboardSnapshot
    func clearContents()
}

struct ClipboardService: ClipboardServiceProtocol {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func fetchSnapshot() -> ClipboardSnapshot {
        let pasteboardItems = pasteboard.pasteboardItems ?? []
        let items = pasteboardItems.map { item in
            let types = item.types.map(\.rawValue)
            var dataByType: [String: Data] = [:]
            for rawType in types {
                let type = NSPasteboard.PasteboardType(rawValue: rawType)
                if let data = item.data(forType: type) {
                    dataByType[rawType] = data
                }
            }
            return ClipboardItem(types: types, dataByType: dataByType)
        }

        return ClipboardSnapshot(changeCount: pasteboard.changeCount, items: items)
    }

    func clearContents() {
        pasteboard.clearContents()
    }
}
