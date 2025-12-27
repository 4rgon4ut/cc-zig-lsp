# Test Protocol

## Prerequisites
```bash
zig version      # 0.13+
zls --version    # must match zig
export ENABLE_LSP_TOOLS=1
```

## Validation Script
```bash
#!/bin/bash
set -e
jq . .lsp.json .claude-plugin/plugin.json >/dev/null
jq -e '.zig.command, .zig.extensionToLanguage' .lsp.json >/dev/null
[ -f hooks/check-zls.sh ] && shellcheck hooks/check-zls.sh
command -v zls >/dev/null && echo "ZLS: $(zls --version 2>/dev/null)"
echo "PASS"
```

## Test Matrix

| Test | Command | Expected |
|------|---------|----------|
| Plugin loads | `/plugins list` | zig-lsp listed |
| ZLS starts | open .zig file | no errors |
| goToDefinition | LSP on call site | jumps to def |
| findReferences | LSP on function | lists call sites |
| hover | LSP on symbol | shows type |
| documentSymbol | LSP on file | lists symbols |
| Missing ZLS | remove from PATH | graceful error |
| .zon support | open build.zig.zon | syntax works |

## Debug
```bash
claude --enable-lsp-logging
# reproduce issue
cat ~/.claude/debug/lsp-*.log
```
