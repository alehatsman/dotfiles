```json
{
  "globalRules": {
    "mcsearch": {
      "readToolDocs": true
    },
    "explorationSearch": {
      "rules": [
        "Use mcsearch_context before Grep/Glob/broad Read",
        "Read only returned file ranges",
        "Use graph expansion only for architecture/call-flow understanding",
        "Use Grep only if semantic search is insufficient",
        "Stop searching once confidence is sufficient to implement"
      ],
      "cliFallback": {
        "condition": "MCP unavailable",
        "command": "mcsearch context . \"$QUESTION\" --format json"
      }
    },
    "tokenUsage": {
      "optimizeForReducedTokenUsage": true
    },
    "generalRules": {
      "worktree": {
        "useForNonTrivialWork": true,
        "askBeforeMerging": true,
        "neverAutoPushToMain": true
      },
      "branches": {
        "prefixes": [
          "fix/",
          "feat/",
          "chore/",
          "docs/",
          "test/",
          "refactor/"
        ],
        "format": "lowercase-kebab",
        "commitStyle": "conventional-commit-prefix"
      },
      "search": {
        "preferMcsearchBeforeGrep": true,
        "brieflyExplainFallbackToGrep": true
      },
      "scopeControl": {
        "noDirectoryReshuffleUnlessAsked": true,
        "noLargeRenamesUnlessAsked": true,
        "noModernizationPassesUnlessAsked": true,
        "noNewDependenciesWithoutAsking": true
      },
      "investigation": {
        "stayReadOnly": true,
        "citeFormat": "path:line"
      },
      "output": {
        "trivialTasks": "skip headered output",
        "realImplementations": [
          "what changed",
          "files",
          "validation",
          "commit + branch if applicable"
        ]
      },
      "failureClassification": [
        "caused-by-change",
        "pre-existing",
        "environment",
        "dependency",
        "unclear"
      ]
    }
  }
}
```
