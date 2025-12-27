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

## Release

```bash
# bump version in plugin.json
git commit -m "chore: release v1.x.x"
git tag v1.x.x
git push --tags
```
