import Testing
@testable import pbshow

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
