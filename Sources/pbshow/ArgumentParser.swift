import Foundation

struct ArgumentParser {
    func parse(_ args: [String]) throws -> ParsedArguments {
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

    func printHelp() {
        print(helpText)
    }

    private var helpText: String {
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
    }
}
