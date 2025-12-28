# cc-zig-lsp

Zig LSP plugin for Claude Code. Integrates [ZLS](https://github.com/zigtools/zls).

## Conventions

### Commits
```
<type>(<scope>): <description>
```

| Type | Scope |
|------|-------|
| feat, fix, docs, chore | plugin, lsp, hooks |

### Branches
- `main` ← stable releases
- `feat/*`, `fix/*` → PR to main

### Files
```
.claude-plugin/plugin.json       # metadata (runtime)
.claude-plugin/marketplace.json  # marketplace registry (keep version in sync!)
.lsp.json                        # ZLS config
hooks/check-zls.sh               # binary detection
```

## Implementation

See `.prompts/core.md` for protocol.

## References

| Topic | Location |
|-------|----------|
| Implementation | `.prompts/core.md` |
| Tools | `.prompts/tools.md` |
| Testing | `.prompts/test.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| Versioning | `docs/VERSIONING.md` |
