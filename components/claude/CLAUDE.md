# Tool routing

- **Refactor / rename / find-refs / diagnostics**: LSP. Never grep+Edit for symbol-level changes.
- **Code search by meaning**: `semantic_search` (MCP). Use grep only for exact-string lookups.
- **Codebase Q&A**: `ask_codebase` (MCP). Don't `Read` and synthesize yourself.
- **File or range gist**: `summarize_path` (MCP). Don't `Read` a whole file just to orient.
- **New code / scaffolding**: `generate_code` (MCP). Don't hand-write what it generates.
- **Search seems wrong**: `mcsearch_status` (MCP). Check before chasing a "missing" result through code.

# Token discipline

- Read targeted line ranges, not whole files.
- Parallel-call independent tools in one message.
- No preamble, recap, or status narration — the user sees the diff.
- Default to no comments; only add when WHY is non-obvious.
