# AGENTS Instructions

## Project Overview

- Project: `pbshow`
- Type: Swift Package executable
- Swift tools version: `6.2`
- Language mode: Swift 6
- Platform target: macOS 10.15+
- Entry point: `Sources/pbshow/pbshow.swift`

## Repository Layout

- `Sources/pbshow/`: application source code
- `Tests/pbshowTests/`: unit tests using the `swift-testing` package
- `Package.swift`: package manifest and dependencies
- `notes/`: design notes and refactor memos

## Working Conventions for Agents

- Follow current code style in nearby files (naming, control flow, error handling).
- Keep comments concise and in English.
- Do not introduce new dependencies unless required by the task.

## Development Tooling

This repository uses:

- `swift-format` for code formatting
- `make` as the primary command entrypoint

Install tools with Homebrew:

```bash
brew install swift-format
```

Common commands:

```bash
make format   # Rewrite formatting in Sources/ and Tests/
make lint     # Run swift-format lint
make build    # Build the package
make test     # Run tests with sandbox-friendly HOME
make check    # Run lint and test
make run      # Run: swift run pbshow show
make clean    # Clean SwiftPM artifacts
```

## Build and Run

- Build:

```bash
swift build
```

- Run (example):

```bash
swift run pbshow show
```

## Swift Test in Sandbox

When running tests from this Codex sandbox environment, use a writable temporary HOME directory.

```bash
mkdir -p /private/tmp/pbshow-swift-cache
HOME=/private/tmp/pbshow-swift-cache swift test
```

Do not run plain `swift test` in this environment because cache path access may fail.

## Testing Expectations

- Run relevant tests after code changes.
- At minimum, run the full test suite before finishing substantial refactors.
- If tests cannot be run, report the reason clearly in the final response.

## Validation Checklist Before Finishing

- Code compiles for touched targets.
- Changed logic is covered by existing tests, or tests are updated as needed.
- No unrelated files are modified.
