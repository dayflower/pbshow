# pbshow

`pbshow` is a macOS clipboard inspector CLI built with Swift.

It can:

- Show clipboard item contents (`show`)
- List clipboard metadata in YAML (`list`)
- Export raw bytes for a specific pasteboard type (`export`)
- Clear clipboard contents (`clear`)

## Install

### Homebrew

```bash
brew install dayflower/tap/pbshow
brew upgrade dayflower/tap/pbshow
pbshow --version
```

### GitHub Releases

Download the latest release archive from:

- https://github.com/dayflower/pbshow/releases

Then extract and install the `pbshow` binary from `pbshow-X.Y.Z-macos.zip`:

```bash
unzip pbshow-X.Y.Z-macos.zip
install -m 755 pbshow /usr/local/bin/pbshow
pbshow --version
```

If you prefer a user-local install path:

```bash
mkdir -p "$HOME/.local/bin"
install -m 755 pbshow "$HOME/.local/bin/pbshow"
chmod +x "$HOME/.local/bin/pbshow"
pbshow --version
```

## Usage

```text
pbshow <subcommand> [options]
```

Global options:

- `-h`, `--help`: Show help text
- `-v`, `--version`: Show CLI version
- `-i`, `--index <n>`: Target clipboard item index

### show

Show clipboard items and their data.

```bash
pbshow show
pbshow show public.utf8-plain-text
pbshow show public.html -i 0
pbshow show public.rtf -f
```

Notes:

- Without `-i`, all items are shown.
- `-f`, `--force` forces text rendering for non-text-target types.
- When text rendering is not applied, output falls back to a hex dump.

### list

Show only metadata in YAML format.

```bash
pbshow list
pbshow list public.html
pbshow list public.url -i 0
```

### export

Export raw data from one clipboard item/type.

```bash
pbshow export public.utf8-plain-text
pbshow export public.html -i 1 -o clip.html
pbshow export public.rtf -i 0 > clip.rtf
```

Notes:

- Without `-i`, item `#0` is used.
- `-o`, `--output <path>` writes bytes to a file.
- If `-o` is omitted, bytes are written to stdout.

### clear

Clear clipboard contents.

```bash
pbshow clear
```

## Development

This repository uses `make` and `swift-format`.
CI runs on GitHub Actions in two workflows: `ci.yml` for pull requests to `main`, and `release.yml` for pushes to `main`. Both run the shared verification workflow (`make lint` and `make test`), and `release.yml` additionally creates tags and GitHub Releases when `VERSION` changes.

### Requirements

- macOS 10.15+
- Swift 6.2 toolchain

### Build

```bash
swift build
```

Run directly with SwiftPM:

```bash
swift run pbshow show
```

### Tooling

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

## License

MIT. See [LICENSE](LICENSE).
