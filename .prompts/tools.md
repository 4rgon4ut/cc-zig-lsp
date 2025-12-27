# Tool Reference

## MCP Tools

### Serena (Code Navigation)
```
get_symbols_overview(relative_path, depth)
find_symbol(name_path_pattern, include_body, relative_path)
find_referencing_symbols(name_path, relative_path)
search_for_pattern(substring_pattern, restrict_search_to_code_files)
```

### Sutra (Reasoning)
```
understand_question(question, context, constraints)
verify_logic(claim, reasoning_trace)
backtracking(objective, failed_step, trace)
```

### Context7 (Docs)
```
resolve-library-id(libraryName="zls")
get-library-docs(context7CompatibleLibraryID, topic, mode)
```

## Terminal

```bash
# Validate
jq . .lsp.json .claude-plugin/plugin.json
shellcheck hooks/*.sh

# ZLS
which zls && zls --version
curl -s https://api.github.com/repos/zigtools/zls/releases/latest | jq -r .tag_name

# Debug
claude --enable-lsp-logging
ls ~/.claude/debug/
```

## LSP Operations

```
LSP(operation, filePath, line, character)
```
Operations: `goToDefinition`, `findReferences`, `hover`, `documentSymbol`
