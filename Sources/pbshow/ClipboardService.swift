import AppKit
import Foundation

struct ClipboardItem {
    let types: [ClipboardType]
    private let dataByType: [ClipboardType: Data]

    init(types: [ClipboardType], dataByType: [ClipboardType: Data]) {
        self.types = types
        self.dataByType = dataByType
    }

    func data(forType type: ClipboardType) -> Data? {
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
            let types = item.types.map { ClipboardType(rawValue: $0.rawValue) }
            var dataByType: [ClipboardType: Data] = [:]
            for type in types {
                let pasteboardType = NSPasteboard.PasteboardType(rawValue: type.rawValue)
                if let data = item.data(forType: pasteboardType) {
                    dataByType[type] = data
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
