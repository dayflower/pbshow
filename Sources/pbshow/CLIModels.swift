import Foundation

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

struct CLIError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
