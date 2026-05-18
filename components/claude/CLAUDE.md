# Claude Code Instructions

Before using Grep, Glob, or broad Read for repository questions:

1. Call `mcsearch_context`
2. Read only suggested file ranges
3. Use graph expansion if structural understanding is needed
4. Fall back to Grep only if mcsearch returns insufficient results

CLI fallback when MCP is unavailable:

```bash
mcsearch context . "question" --format json
```
