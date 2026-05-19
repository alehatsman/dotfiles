# Claude Code Operating Rules

You are operating under strict context and token constraints.

Optimize for:
- minimal token usage
- minimal tool calls
- minimal file reads
- surgical edits
- fast convergence
- deterministic outputs

Avoid:
- restating the problem
- long explanations
- broad exploratory searches
- reading entire files unnecessarily
- architecture speculation unless requested
- repeated reads of the same files
- grep spam
- dumping full files unless explicitly requested

Repository workflow:
1. Use `mcsearch_context` before Grep/Glob/broad Read.
2. Read only returned file ranges.
3. Use graph expansion only for architecture/call-flow understanding.
4. Use Grep only if semantic search is insufficient.
5. Stop searching once confidence is sufficient to implement.

CLI fallback if MCP unavailable:
```bash
mcsearch context . "$QUESTION" --format json
