import Testing
import Foundation
@testable import pbshow

@Test func parse_defaultsToShowWithoutArgs() throws {
    let parser = ArgumentParser()
    let parsed = try parser.parse([])

    #expect(parsed.index == nil)
    #expect(parsed.force == false)
    switch parsed.command {
    case let .show(type):
        #expect(type == nil)
    default:
        Issue.record("Expected show command")
    }
}

@Test func parse_parsesShowWithIndexAndForce() throws {
    let parser = ArgumentParser()
    let parsed = try parser.parse(["show", "public.utf8-plain-text", "-i", "2", "-f"])

    #expect(parsed.index == 2)
    #expect(parsed.force == true)
    switch parsed.command {
    case let .show(type):
        #expect(type?.rawValue == "public.utf8-plain-text")
    default:
        Issue.record("Expected show command")
    }
}

@Test func parse_parsesListWithTypeFilter() throws {
    let parser = ArgumentParser()
    let parsed = try parser.parse(["list", "public.html", "-i", "0"])

    #expect(parsed.index == 0)
    #expect(parsed.force == false)
    switch parsed.command {
    case let .list(type):
        #expect(type?.rawValue == "public.html")
    default:
        Issue.record("Expected list command")
    }
}

@Test func parse_rejectsInvalidIndexValue() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["show", "-i", "abc"])
    }
}

@Test func parse_rejectsMissingIndexValue() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["show", "-i"])
    }
}

@Test func parse_rejectsOutputForShow() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["show", "-o", "out.bin"])
    }
}

@Test func parse_rejectsOutputForList() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["list", "-o", "out.bin"])
    }
}

@Test func parse_rejectsOutputForClear() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["clear", "-o", "out.bin"])
    }
}

@Test func parse_rejectsOutputForHelpCommand() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["help", "-o", "out.bin"])
    }
}

@Test func parse_rejectsForceForList() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["list", "-f"])
    }
}

@Test func parse_rejectsForceForExport() throws {
    let parser = ArgumentParser()

    #expect(throws: CLIError.self) {
        _ = try parser.parse(["export", "public.utf8-plain-text", "-f"])
    }
}

@Test func parse_acceptsOutputForExport() throws {
    let parser = ArgumentParser()
    let parsed = try parser.parse(["export", "public.utf8-plain-text", "-o", "out.bin"])

    switch parsed.command {
    case let .export(type, outputPath):
        #expect(type.rawValue == "public.utf8-plain-text")
        #expect(outputPath == "out.bin")
    default:
        Issue.record("Expected export command")
    }
}

@Test func decodeText_decodesUTF8() throws {
    let renderer = Renderer()
    let data = Data("hello".utf8)

    let decoded = renderer.decodeText(from: data)
    #expect(decoded == "hello")
}

@Test func decodeText_returnsNilForEmptyData() throws {
    let renderer = Renderer()
    let data = Data()

    let decoded = renderer.decodeText(from: data)
    #expect(decoded == nil)
}

@Test func hexDump_formatsOffsetHexAndAscii() throws {
    let renderer = Renderer()
    let data = Data("ABC".utf8)

    let dump = renderer.hexDump(data: data, maxBytes: 256)
    #expect(dump.contains("0000"))
    #expect(dump.contains("41 42 43"))
    #expect(dump.contains("|ABC|"))
}

@Test func hexDump_appendsTruncationNotice() throws {
    let renderer = Renderer()
    let data = Data((0...20).map(UInt8.init))

    let dump = renderer.hexDump(data: data, maxBytes: 16)
    #expect(dump.contains("... truncated: showing first 16 of 21 bytes"))
}
