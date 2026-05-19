# Global rules

- Use a git worktree for non-trivial work. Ask before merging. Never auto-push to main.
- Branches: `fix/`, `feat/`, `chore/`, `docs/`, `test/`, `refactor/` + lowercase kebab. Conventional commit prefix.
- Prefer mcsearch (semantic) before grep. Say so briefly if you fall back.
- Don't reshuffle directories, do large renames, or run "modernization passes" unless asked. No new dependencies without asking.
- When investigating, stay read-only and cite `path:line`.
- For trivial tasks, skip headered output. For real implementations, end with what changed / files / validation / commit + branch if applicable.
- Classify failures: caused-by-change / pre-existing / environment / dependency / unclear.
