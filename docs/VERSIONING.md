# Versioning

## Plugin Version (SemVer)

- MAJOR: breaking config changes
- MINOR: new ZLS options
- PATCH: bug fixes

## Compatibility

The plugin is **version-agnostic** by design: at session start it detects the
project's Zig version and installs the matching ZLS release on demand. There is
no static mapping from a plugin version to a specific Zig release.

| Component | Supported |
|-----------|-----------|
| Zig | any release with a corresponding ZLS tag (`0.9.0` – `0.16.0` at time of writing) |
| ZLS | resolved automatically to the exact Zig version, or the highest `major.minor` match when ZLS lags behind a Zig release |

## Constraint

ZLS must match the Zig `major.minor`. No binary is bundled — the hook downloads
ZLS from the official releases on demand.

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
