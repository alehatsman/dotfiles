# dotfiles

Personal dotfiles. **Deploy only via mooncake** — never `cp`/`ln`/hand-write
into managed destinations (`~/.config/...`). Per-machine entries live under
`machines/<m>/`; apply with `mooncake apply -c ./<m>.yml`.

## Workflow — track work as moongit issues (mgit)

Prereq: the repo has a `moongit` remote (code mirror) — or `MOONGIT_SERVER`
points at the server. Export your **own** `MOONGIT_TOKEN` (`mgt_…`); the
token's name is your identity in every claim/comment, so never share one.

1. **Survey:** `mgit issue list --state todo,in_progress`.
2. **Plan as issues** — one issue per unit of work, the plan in the body. Split
   multi-part work into multiple issues:
   `mgit issue create --title "<t>" --body "<plan>"`.
3. **Claim before coding:** `mgit issue claim <n> --state in_progress`. Never
   work an issue already `in_progress` under another identity.
4. **Report progress** at real checkpoints: `mgit issue comment <n> --body "…"`.
5. **Close out** when merged + verified: `mgit issue set-state <n> done`
   (`mgit issue unclaim <n>` if you drop it).

No code without an owned issue. Worktrees for non-trivial changes; never
auto-push; ask before merge; conventional branches/commits.
