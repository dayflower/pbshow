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

Example output:

```text
===== Clipboard contents =====
changeCount: 621
items: 1
targets: 0

[item #0]

---
type: public.html
size: 158 bytes

<meta charset='utf-8'><html><head></head><body><a href="https://github.com/dayflower/pbshow">dayflower/pbshow: macOS clipboard inspector CLI</a></body></html>

---
type: public.utf8-plain-text
size: 35 bytes

https://github.com/dayflower/pbshow

---
type: org.chromium.internal.source-rfh-token
size: 24 bytes
view: hex

0000  14 00 00 00 00 13 00 00 4c 34 0d 48 b7 e4 5c 3a  |........L4.H..\:|
0010  6d f8 e8 fd a3 87 b8 b1                          |m.......|

---
type: org.chromium.source-url
size: 35 bytes

https://github.com/dayflower/pbshow
```

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

## Development

See [notes/DEVELOPMENT.md](notes/DEVELOPMENT.md).

## License

MIT. See [LICENSE](LICENSE).
