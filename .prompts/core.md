# Implementation Protocol

## Phases

```
1. CONFIG   → .lsp.json + plugin.json
2. HOOKS    → check-zls.sh
3. TEST     → LSP operations
4. DOCS     → README
```

## Priority

| P0 (Required) | P1 (Essential) | P2 (Optional) |
|---------------|----------------|---------------|
| .lsp.json | hooks/ | custom ZLS path |
| plugin.json | initOptions | version warnings |
| extensionToLanguage | loggingConfig | |

## .lsp.json Schema

```json
{
  "zig": {
    "command": "zls",
    "extensionToLanguage": { ".zig": "zig", ".zon": "zig" },
    "initializationOptions": {},
    "maxRestarts": 3
  }
}
```

## plugin.json Schema

```json
{
  "name": "zig-lsp",
  "description": "Zig language support via ZLS",
  "version": "1.0.0",
  "author": { "name": "..." }
}
```

## ZLS Init Options

```json
{
  "enable_snippets": true,
  "enable_import_analysis": true
}
```

## Decision Tree

```
ZLS in PATH? → NO  → warn, continue
            → YES → version match? → NO  → warn
                                   → YES → init LSP
```

## Error Recovery

| Error | Detection | Action |
|-------|-----------|--------|
| Binary missing | `command -v zls` empty | show install URL |
| Version mismatch | ZLS stderr | log warning |
| Init failure | LSP error response | retry minimal |
