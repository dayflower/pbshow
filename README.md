# pbshow

`pbshow` is a macOS clipboard inspector CLI built with Swift.

It can:

- Show clipboard item contents (`show`)
- List clipboard metadata in YAML (`list`)
- Export raw bytes for a specific pasteboard type (`export`)
- Clear clipboard contents (`clear`)

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
CI runs on GitHub Actions for `push` and `pull_request` to `main`, and executes `make lint` and `make test`.

### Requirements

- macOS 10.15+
- Swift 6.3 toolchain

### Build

```bash
swift build
```

Run directly with SwiftPM:

```bash
swift run pbshow show
```

### Tooling

```bash
brew install swift-format
make format
make lint
make build
make test
make check
```

## License

MIT. See [LICENSE](LICENSE).
