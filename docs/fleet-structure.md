# Fleet structure

Spec for removing the per-machine duplication in `machines/*/index.yml`, and
for making this repo's validation run automatically instead of by memory.

## Problem

Four separate symptoms, one root cause: the fleet grew to six machines and
nothing in the repo scales with machine count.

### 1. Validation is opt-in

`codefort.yml` is the only declared CI, and it cannot run: both jobs pin
`image: provision-ci:latest`, which was removed along with mooncake
(`codefort.yml:15` says so outright). There is no other automated gate.

So the only thing standing between a broken render and `main` is remembering
to type `just ci`. Every structural failure this fleet has hit recently —
`unknown key 'download'`, `brew must not run as root`, a dispatcher matching
no hostname and exiting 0 — is in the class `just ci` catches in 0.8s.

GitHub Actions is explicitly out of scope (owner's call). Validation stays
local, which means it has to be wired into a thing that fires on its own.

### 2. Machine indexes are copy-paste

`machines/x1/index.yml` and `machines/mini_pc/index.yml` differ in **4 lines**
out of ~80. Every machine repeats the same core block:

    palette claude codex git cli languages zsh tmux nvim

Adding a component to the fleet is five edits with nothing checking you made
all five. `components/cli` and `components/gdrive-mirror` are already absent
from the README's component list — the same failure, one directory over.

### 3. The cross-machine guard is hand-maintained five times

Each `machines/<m>/index.yml` opens with its own `case` statement listing the
*other* five hostnames. The lists are maintained by hand and by eye.

This has already failed. Every guard listed `work-mac`, a name that box has
not answered to since MDM took its hostname — so for an unknown stretch the
work mac was unguarded against every other machine's plan. The guard was
fixed by editing five files; the next machine added will need five more
edits, and the failure mode is silent (fail-open, exit 0).

The exclusion list is also the wrong shape. Each machine already declares
`computer_name` — its own identity. A guard that compares the live hostname
to *that* needs no list of peers at all.

### 4. Documentation references files that do not exist

- `README.md:18` names `provision_version`; the variable is `provision_ref`
  (`shared/variables.yml:27`)
- `justfile:2,51` and `platforms/windows/README.md:27` cite `docs/migration.md`
  §2/§6/§3.9 — the file is gone
- `provision.yml:14` and `machines/mini_pc/index.yml:9` cite
  `mini_pc_server.yml` — gone
- `README.md:54` and `codefort.yml:8,10` say "five" machine plans; there are six
- five machine indexes say the provision component checks "the version this
  repo pins"; it checks **capability**, and `components/provision/index.yml:8`
  explains at length why version is useless here
- `README.md:109` says track work as codefort issues; `CLAUDE.md` says GitHub
  issues on `alehatsman/dotfiles`
- the README component list omits `cli`, `gdrive-mirror`, `provision`

None of these break a run. All of them cost a reader trust, and the "version"
one actively misleads: it invites someone to bump a string that does nothing.

## Goal

- Validation that runs without being remembered, locally, on every push.
- One place to declare the fleet's common component set.
- One guard, parameterized, that cannot fail open when a machine is added.
- Docs that match the tree.

## Scope

In:

- `scripts/hooks/pre-push` — runs the local validation suite; refuses the push
  on failure.
- `scripts/bootstrap.sh` — installs that hook into `.git/hooks/pre-push`.
- `just hooks` — same install, for a checkout that was never bootstrapped.
- `shared/core.yml` — the component set every machine gets.
- `shared/guard.yml` — one parameterized cross-machine guard.
- `known_hostnames` in `shared/variables.yml` — the fleet roster.
- `machines/*/index.yml` — import the two shared files instead of inlining.
- `codefort.yml` — add `pixel.yml`, the one machine with no coverage at all.
- The stale references listed above.

Out:

- **GitHub Actions.** Owner's call: validation is local.
- Making `codefort.yml` runnable. It needs a fix in codefort's own repo
  (`CLAUDE.md`); this spec only corrects its machine list.
- Changing what any component does. This is a structural refactor — the set
  of steps a machine runs must be identical before and after.
- Namespacing `shared/variables.yml`. Real, but a separate change.
- Component input documentation. Real, but separate.

## Interfaces

### `shared/core.yml`

The components every machine in the fleet runs, in dependency order. Imported
after the machine's platform, before anything machine-specific.

Palette stays first — every later component's templates read `palette.*` and
`editor.*` from the variant `palette_variant` selects.

`nvim` and `zsh` are `use:` with props, so they stay at the call site where
their props live, at the end of the file.

Not in core, deliberately, because they are not universal:

| component | where |
|---|---|
| `hyprland` | x1 only |
| `alacritty` | GUI machines (mac, work_mac) |
| `teleport` | mac, work_mac |
| `codefort` | main_pc |
| `asciinema` | main_pc |
| `gdrive-mirror` | mac |
| `usql` | work_mac |
| `fleet-peer` | opt-in via `fleet_peer_enabled` |
| `termux` | pixel (which shares no core at all) |

### `shared/guard.yml`

    - import: ../shared/guard.yml

Reads `computer_name` (the machine's own declared identity, already in every
`machines/<m>/vars.yml`) and `known_hostnames` (the roster). Asserts:

    lower(hostname) == lower(computer_name)   OR
    lower(hostname) not in known_hostnames

The second clause is what keeps first-time bootstrap working: a fresh box
whose hostname has never been set is nobody's machine, so it is not blocked.
A box answering to *another machine's* name is.

Case-insensitive, because the work mac's MDM-assigned name is uppercase and a
case-sensitive compare is exactly how the guard failed open before.

### `known_hostnames`

    known_hostnames: [x1, mac, gj4vg9p1vj, mainpc, minipc]

Lowercase. The roster, declared once. Adding a machine is one edit here plus
its own `computer_name` — and if you forget this file, the new machine is
simply unguarded-against rather than silently mismatched, which is the
failure mode that is at least visible.

`pixel` is absent: it is a target reached over adb, never a host running a
plan, so it has no hostname in this sense.

### `scripts/hooks/pre-push`

No arguments; git supplies refs on stdin, which this hook ignores — the check
is on the tree, not the refs.

    $ git push
    == validating all machine plans
    ...
    pre-push: all six machine plans render clean

Runs `provision validate` and `provision plan --plan-no-probe` for every
machine. Non-zero exit refuses the push. `--no-verify` bypasses it, which is
the operator's call to make deliberately.

Skipped with a printed notice, not a failure, when `provision` is not on PATH
— a box mid-bootstrap must still be able to push.

### Install path

`scripts/bootstrap.sh` symlinks `.git/hooks/pre-push` →
`../../scripts/hooks/pre-push` when run inside a dotfiles checkout.

The global dispatcher (`components/git/hooks/hook-dispatch`) already chains
`core.hooksPath` back to `$git_dir/hooks/$hook`, so a repo-local hook fires
normally despite `core.hooksPath` replacing `.git/hooks` wholesale. Nothing
about the dispatcher changes.

A symlink, not a copy, so editing the tracked script takes effect with no
reinstall.

## Edge cases

- **Worktrees.** `--git-common-dir` resolves to the main checkout's `.git`,
  so a hook installed once covers every worktree. Verified: that is why the
  dispatcher uses `--git-common-dir` and not `--git-path`.
- **`provision` missing.** Hook prints a skip notice and exits 0. A box that
  cannot yet build provision must still be able to push the fix.
- **Hook already present and not ours.** `bootstrap.sh` leaves a non-symlink
  `.git/hooks/pre-push` alone and says so. Never clobber an operator's hook.
- **Fresh box, hostname unset.** `known_hostnames` membership fails, guard
  passes. Same posture as the exclusion lists it replaces.
- **A machine whose `computer_name` is not in `known_hostnames`.** Guard
  passes (the box matches its own name). The roster is for catching *other*
  machines, not for self-validation.
- **work mac's uppercase name.** Both sides lowercased before compare.
- **pixel.** Imports neither `core.yml` nor `guard.yml` — it provisions a
  phone over adb from whatever mac is at hand, and already carries its own
  "exactly one authorized device attached" assert.

## Validation

The refactor is only correct if it changes nothing about what runs.

- `just ci` exits 0.
- **Step-set equality**: for all six machines, the step list from
  `provision plan --plan-no-probe` is identical before and after, modulo the
  guard step's name. This is the acceptance test — captured as files and
  diffed, not eyeballed.
- `shellcheck scripts/hooks/pre-push` and `scripts/bootstrap.sh` clean.
- `bash -n` clean on both.
- Guard proven in both directions: passes on this host, and fails when fed
  another machine's `computer_name`.
- Hook proven to fire and to refuse a push on a deliberately broken plan.
- No reference in the tree to a path that does not exist.
