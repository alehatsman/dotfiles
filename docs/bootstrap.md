# Bootstrap

Spec for getting `provision` onto a machine that does not have it, and for
keeping it at a known version afterwards.

## Problem

The README's "Bootstrap a fresh machine" section is not true from nothing.
Every command in it assumes `provision` is already on `PATH`, and nothing in
this repo puts it there:

- there is no `components/provision`
- `scripts/` holds only `test-podman.sh`
- `alehatsman/provision` publishes **no GitHub releases** — only a `v0.9.1`
  tag — so there is no checksummed tarball to fetch the way
  `components/nvim` fetches tree-sitter and zk
- `platforms/arch/bootstrap.sh` concedes the gap in a parenthetical:
  "(`provision` itself must already be on PATH)"

This is not hypothetical. mini_pc is a mooncake-era box with `cargo` but no
`provision` and no `just`, and cannot be applied at all until the binary is
installed by hand.

## Goal

One command, on a machine with nothing but `git` and a shell, that ends with
`provision` on `PATH` at a known version — and a declared component that keeps
it there on every subsequent apply.

## Scope

In:

- `scripts/bootstrap.sh` — step zero. Installs a Rust toolchain if missing,
  builds `provision` at a pinned ref, installs to `~/.local/bin`.
- `components/provision/index.yml` — step N. Asserts the installed binary
  matches the pin and fails loudly on drift. It never writes the binary.
- README correction: state the prerequisite honestly.

Out:

- Publishing releases on `alehatsman/provision`. That is the better long-term
  fix and belongs in that repo, not this one. Tracked separately.
- The Windows host. It runs before WSL exists and has its own twin of this
  script, `scripts/bootstrap.ps1` — see `platforms/windows/README.md`.
- Any change to how machines are applied once `provision` is present.

## Interfaces

    scripts/bootstrap.sh [machine]

- No argument: install `provision` only, then print the next command.
- With a machine name: install, then `provision apply ./<machine>.yml`.
- Env `PROVISION_REF` overrides the pinned ref (default: the pin below).
- Env `PREFIX` overrides install dir (default `~/.local/bin`).

Exit non-zero on any failure. Safe to re-run.

## The ref

`provision_ref: main` in `shared/variables.yml`. Not a tag, not a version.

The `v0.9.1` tag (`f61a27c`) predates the `download` and `git` actions that
`components/nvim`, `components/cli` and `components/tmux` use, so a binary
built from it cannot parse this repo's own plans — it fails with
`unknown key \`download\` in a step`. Tracking `main` avoids that.

A version string is not usable as a pin either: `Cargo.toml` still reads
`0.9.1` on `main`, so a tag build and a `main` build report the same string.
Anything comparing versions would silently accept the broken one.

Cost of tracking `main`, accepted knowingly: two machines bootstrapped weeks
apart may get different binaries. `bootstrap.sh` resolves `main` to a commit
and records it in `~/.local/state/provision/installed-ref`, so what each box
is actually running is always answerable.

## Edge cases

- **No cargo.** Install via rustup, non-interactive, default profile. Do not
  touch an existing toolchain.
- **cargo present but old.** Build and let it fail loudly; do not silently
  `rustup update` someone's toolchain.
- **`~/.local/bin` not on PATH.** Install anyway and print the export line.
  `components/zsh` owns PATH; bootstrap does not edit shell rc files.
- **provision already installed at the pinned version.** No-op, exit 0.
- **provision installed at a different version.** Replace it, and say so.
- **Self-replacement during apply.** Resolved by making the component
  verify-only: it never writes the binary, so an apply can never swap the
  tool out from under itself. Upgrading is an explicit `scripts/bootstrap.sh`
  run, the same posture as `just upgrade` — a choice, not declared state.
- **No network / clone fails.** Fail with the actual error, do not retry.
- **Non-x86_64 or non-Linux.** Build from source handles this; there is no
  prebuilt to be wrong about.

## Validation

- `shellcheck scripts/bootstrap.sh` clean.
- `bash -n` clean.
- Re-run on a box that already has the pinned version: no-op, exit 0.
- `provision validate ./<machine>.yml` parses `components/provision`.
- `just ci` renders every machine plan with the new component imported.
- End to end on mini_pc: from no `provision` to a completed `mini_pc.yml`
  apply.
