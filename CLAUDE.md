# dotfiles

Personal dotfiles. **Deploy only via provision** — never `cp`/`ln`/hand-write
into managed destinations (`~/.config/...`). Per-machine entries live under
`machines/<m>/`; apply with `provision apply ./<m>.yml`.

mooncake is no longer the applier, but it is still a tool these plans
provision around: the CI images carry it, and moongit's runner execs every
CI step through it.

Mgit workflow: see global CLAUDE.md. No code without an owned issue.
