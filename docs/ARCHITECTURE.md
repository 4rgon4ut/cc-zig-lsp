# Architecture

## Components

```
Claude Code
├── Plugin Loader    → reads .claude-plugin/plugin.json
├── LSP Manager      → reads .lsp.json, spawns ZLS
└── Hook Executor    → runs hooks/hooks.json

cc-zig-lsp (this plugin)
├── plugin.json      → metadata
├── .lsp.json        → ZLS config
└── hooks/           → lifecycle scripts

ZLS (external)
└── stdio transport  → LSP protocol
```

## Data Flow

```
1. Claude Code loads plugin
2. Opens .zig file → matches extensionToLanguage
3. Spawns: zls (from .lsp.json command)
4. LSP handshake: initialize → initialized
5. File ops: didOpen → diagnostics
6. User requests: definition/references/hover → results
```

## LSP Capabilities (ZLS)

| Feature | LSP Method |
|---------|------------|
| Go to Definition | textDocument/definition |
| Find References | textDocument/references |
| Hover | textDocument/hover |
| Symbols | textDocument/documentSymbol |
| Completion | textDocument/completion |
| Diagnostics | textDocument/publishDiagnostics |

## Extension Points

```json
// Custom ZLS path
"settings": { "zig_exe_path": "/custom/zig" }

// Custom init
"initializationOptions": { "enable_snippets": false }

// Debug logging
"loggingConfig": { "env": { "ZLS_LOG": "${CLAUDE_PLUGIN_LSP_LOG_FILE}" } }
```
