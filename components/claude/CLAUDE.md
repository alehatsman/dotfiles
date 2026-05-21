# Global Rules

## Search and exploration

Always call `mcsearch_context` before reaching for Grep, Glob, or broad file reads. Read only the line ranges it returns. Use graph expansion only when you need architecture or call-flow understanding. Fall back to Grep only if semantic search is genuinely insufficient — briefly say why when you do. Stop searching once you have enough confidence to implement; don't keep exploring for completeness.

If the MCP server is unavailable, fall back to: `mcsearch context . "$QUESTION" --format json`

Read the mcsearch tool docs at the start of each session.

## Token usage

Optimize for reduced token usage throughout. Prefer targeted reads over broad ones, and stop gathering context as soon as it's sufficient.

## Git workflow

Use a worktree for any non-trivial change. Never auto-push to main. Always ask before merging a worktree back.

Branch names use conventional prefixes (`fix/`, `feat/`, `chore/`, `docs/`, `test/`, `refactor/`) in lowercase-kebab format. Commits use conventional-commit prefixes (`feat:`, `fix:`, `chore:`, etc.).

## Scope control

Don't reshuffle directories, rename things at scale, run modernization passes, or add new dependencies unless explicitly asked. Stay within the scope of what was requested.

## Investigation

Stay read-only during investigation. Cite locations as `path:line`.

## Output format

For trivial tasks, skip headers and sections — just give the answer. For real implementations, cover: what changed, which files, how to validate, and the commit/branch if applicable.

## Failure classification

When something breaks, classify it as one of: `caused-by-change`, `pre-existing`, `environment`, `dependency`, or `unclear`. State the classification before diving into the fix.
