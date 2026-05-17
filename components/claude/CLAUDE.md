# Tool routing

- **Refactor / rename / find-refs / diagnostics**: LSP. Never grep+Edit for symbol-level changes.
- **Code search**: `semantic_search` (MCP). Use grep only for exact-string lookups.
- **New code / scaffolding**: `generate_code` (MCP). Don't hand-write what it generates.

# Token discipline

- Read targeted line ranges, not whole files.
- Parallel-call independent tools in one message.
- No preamble, recap, or status narration — the user sees the diff.
- Default to no comments; only add when WHY is non-obvious.
