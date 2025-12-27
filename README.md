# cc-zig-lsp

Zig LSP plugin for [Claude Code](https://claude.ai/code). Integrates [ZLS](https://github.com/zigtools/zls) with automatic installation and version management.

## Features

- **Auto-install**: Downloads ZLS automatically if not present
- **Project-aware**: Matches ZLS version to your project's Zig version
- **Multi-version**: Caches multiple ZLS versions for different projects
- **Secure**: [SHA256 checksum verification](https://github.com/4rgon4ut/cc-zig-lsp/blob/main/hooks/check-zls.sh#L148-L158) on downloads

## Installation

```bash
claude plugin install zig-lsp@cc-zig-lsp
```

Or from GitHub:

```bash
claude plugin install github:pr0x1m4/cc-zig-lsp
```

## Requirements

- [Zig](https://ziglang.org/download/) installed and in PATH
- ZLS will be auto-installed, or you can install it manually

## How It Works

Once installed, Claude Code automatically uses ZLS when you work with `.zig` or `.zon` files. No configuration needed.

### Version Detection

The plugin detects the required Zig/ZLS version in this order:

1. `build.zig.zon` → `.minimum_zig_version` field
2. `.zigversion` file (for zvm, zigup, zv)
3. Global `zig version`

### Storage

```
~/.local/share/zls/
├── 0.13.0/zls    # Cached versions
├── 0.14.0/zls
└── ...

~/.local/bin/zls  # Symlink to active version
```

## Manual ZLS Installation

If you prefer to install ZLS manually:

```bash
# macOS
brew install zls

# Arch Linux
pacman -S zls

# From source
git clone https://github.com/zigtools/zls
cd zls && zig build -Doptimize=ReleaseSafe
```

## Verification

Check that LSP is working:

```bash
claude --enable-lsp-logging
# Work with .zig files
cat ~/.claude/debug/lsp-*.log
```

## Supported Platforms

| OS | Architecture |
|----|--------------|
| macOS | x86_64, aarch64 |
| Linux | x86_64, aarch64 |

## License

MIT
