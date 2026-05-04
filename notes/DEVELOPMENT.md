# Development

This repository uses `make` and `swift-format`.
CI runs on GitHub Actions in two workflows: `ci.yml` for pull requests to `main`, and `release.yml` for pushes to `main`. Both run the shared verification workflow (`make lint` and `make test`), and `release.yml` additionally creates tags and GitHub Releases when `VERSION` changes.

## Requirements

- macOS 10.15+
- Swift 6.2 toolchain

## Build

```bash
swift build
```

Run directly with SwiftPM:

```bash
swift run pbshow show
```

## Tooling

Install development tooling:

```bash
brew install swift-format
make format
make lint
make build
make test
make check
```

## Release Flow

- Run `./scripts/bump-version.sh <major|minor|patch>` from `main` with a clean working tree.
- The script updates `VERSION` and `Sources/pbshow/Version.swift`, creates a `release/vX.Y.Z` branch, pushes it, and opens a PR.
- Merge the PR into `main`.
- CI detects the `VERSION` change on `main` and then:
  - creates and pushes tag `vX.Y.Z`
  - builds release binary (`swift build -c release`)
  - uploads `pbshow-X.Y.Z-macos.zip` to a public GitHub Release named `vX.Y.Z`
