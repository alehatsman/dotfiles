# dotfiles

Personal dotfiles. **Deploy only via provision** — never `cp`/`ln`/hand-write
into managed destinations (`~/.config/...`). Per-machine entries live under
`machines/<m>/`; apply with `provision apply ./<m>.yml`.

mooncake has been fully removed from this repo (components/mooncake,
components/provision's CI image, the fleet agentd, scripts/install_mooncake.sh
are all gone). moongit's own CI runner still execs `mooncake step` inside
every CI job — that's a contract in moongit's source (a separate repo), not
this one — so CI (mgitci.yml) will not run until moongit's runner is changed
to stop requiring mooncake. Do not silently re-add mooncake to work around
that; it needs a moongit-side fix.

Mgit workflow: see global CLAUDE.md. No code without an owned issue.
