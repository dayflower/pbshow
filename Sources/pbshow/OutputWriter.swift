import Foundation

struct OutputWriter {
    static let standard = OutputWriter()

    private let stdout: FileHandle
    private let stderr: FileHandle

    init(stdout: FileHandle = .standardOutput, stderr: FileHandle = .standardError) {
        self.stdout = stdout
        self.stderr = stderr
    }

    func writeLine(_ text: String = "") {
        write(text + "\n")
    }

    func write(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            return
        }
        stdout.write(data)
    }

    func writeData(_ data: Data) {
        stdout.write(data)
    }

    func writeErrorLine(_ text: String = "") {
        guard let data = (text + "\n").data(using: .utf8) else {
            return
        }
        stderr.write(data)
    }
}
