# Versioning

## Plugin Version (SemVer)

- MAJOR: breaking config changes
- MINOR: new ZLS options
- PATCH: bug fixes

## Compatibility Matrix

| Plugin | ZLS | Zig |
|--------|-----|-----|
| 1.0.x | 0.13+ | 0.13.x |
| 1.1.x | 0.14+ | 0.14.x |

## Constraint

ZLS must match Zig version. No bundled binary - user installs.

## Version Sources

**⚠️ MANDATORY: All version sources MUST be kept in sync!**

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata (runtime) |
| `.claude-plugin/marketplace.json` | Marketplace registry (discovery) |
| Git tag | Release reference |

Version mismatch causes marketplace display issues (missing "new" tags, stale versions shown).

## Release

```bash
# 1. Bump version in BOTH files
#    - .claude-plugin/plugin.json
#    - .claude-plugin/marketplace.json

# 2. Commit and tag
git commit -m "chore: release 1.x.x"
git tag 1.x.x
git push --tags
```
