# Keybindings — Unified Vim-style Reference

A cross-tool view of every keybinding the dotfiles define, plus the
remaining proposals for tightening them. The single-tool cheatsheets
(`nvim.md`, `tmux.md`) stay authoritative for their own tools.

## The five layers

Keys travel through nested contexts. Each layer should use a distinct
modifier so layers don't fight each other:

| Layer | Tool | Primary modifier | Mode |
| --- | --- | --- | --- |
| Window manager | Hyprland | `Super` | none |
| Terminal | Alacritty | `Ctrl` / `Super` (minimal) | none |
| Multiplexer | Tmux | `Prefix = Ctrl+T` | none |
| Shell | Zsh | none (`bindkey -v`) | vi |
| Editor | Nvim | `Leader = Space` | vi (modal) |
| Editor (in Claude Code TUI) | Claude Code | n/a (`editorMode = vim`) | vi |

The rule of thumb: **plain keys belong to the editor, `Ctrl+` to the
multiplexer, `Super+` to the window manager.** Anything that breaks that
hierarchy is a candidate for cleanup.

---

## Motion across layers (the vim-key core)

The strongest part of the setup — consistent across every layer:

| Combo | Layer | Action |
| --- | --- | --- |
| `h j k l` | Nvim (normal) | cursor motion |
| `h j k l` | Tmux copy-mode-vi | cursor motion in scrollback |
| `h j k l` | Zsh (vicmd) | cursor motion on the command line |
| `Ctrl+h/j/k/l` | Nvim ⇄ Tmux | pane navigation (via vim-tmux-navigator) |
| `Super+h/j/k/l` | Hyprland | focus left / down / up / right window |
| `Super+Shift+h/j/k/l` | Hyprland | move window left / down / up / right |
| `Super+Alt+h/j/k/l` | Hyprland | resize: narrower / taller / shorter / wider |
| `Alt+h/j/k/l` | Nvim | resize split: narrower / taller / shorter / wider |
| `Alt+h/j/k/l` | Tmux | resize pane 3 cells in that direction |

All three resize tiers now agree: `l` extends right, `h` contracts;
`j` extends down, `k` contracts.

---

## Per-tool inventory

### Nvim — leader `Space`, localleader `Tab`

Window / split
- `Ctrl+h/j/k/l` — move focus (vim-tmux-navigator falls through to tmux)
- `Ctrl+W o` — only this window
- `Alt+h/j/k/l` — resize (narrower / taller / shorter / wider)
- `<leader>wv / ws / wq` — vsplit / split / close

Tabs (`<leader>t…`)
- `tt` new · `tn` next · `tp` prev · `tc` close · `to` only · `th/tl` move
- `<leader>1…9` — jump to tab N; `<leader>0` — last tab

Find / search
- `Ctrl+P` — files (fzf)
- `Ctrl+F` — live grep (fzf)
- `<leader>hh` — help search

Files / explorer (`<leader>f…`)
- `fe` toggle nvim-tree · `ff` reveal current file
- inside the tree: `o`/`<CR>` open, `v` vsplit, `s` hsplit, `a` add, `r` rename, `d` delete, `y/Y/gy` copy name/relpath/abspath

LSP / code
- `Ctrl+]` definition · `K` hover · `Ctrl+K` signature
- `Ctrl+Space` code actions · `<leader>rn` rename · `<leader>dd` diagnostics → quickfix

Git (gitsigns)
- `]h / [h` next/prev hunk · `<leader>hs/hr/hp` stage / reset / preview
- `<leader>gb` blame · `<leader>gd` diff · `<leader>gl` log

Completion (insert mode)
- `Ctrl+N / Ctrl+P` next / prev · `Ctrl+Space` complete · `CR` confirm · `Ctrl+E` cancel
- `Ctrl+F` scroll docs forward (overloaded — same chord is "grep" in normal mode, separate modes so it's fine)
- `Ctrl+J` accept Copilot suggestion

Filetype-local
- Go (`<leader>g…`): `gt` test, `gr` rename, `glr` build-tags
- Clojure (`<localleader>…`): `cc` Conjure connect, `f` format

### Tmux — prefix `Ctrl+T`

Sessions / windows
- `<prefix> r` reload config
- `<prefix> c` new window (cwd preserved) · `<prefix> v` vsplit · `<prefix> s` hsplit
- `<prefix> w` choose-tree (session/window picker)
- `Shift+Left / Shift+Right` — swap window left / right (no prefix)

Panes
- `Ctrl+h/j/k/l` — vim-tmux-navigator (falls through to nvim when active)
- `Ctrl+\` — last pane
- `Alt+h/j/k/l` — resize 3 cells

Copy mode (vi)
- `<prefix> [` enter · `v` begin selection
- `y` — tmux-yank handles, picks `pbcopy` / `wl-copy` / `xclip` per OS
- `Enter` — same as `y` (relies on tmux-sensible's `set-clipboard on` + OSC52)
- `<prefix> p` paste from tmux buffer
- `h/j/k/l`, `w/b/e`, `gg/G`, `/` — vim motions in scrollback

### Zsh — `bindkey -v` (vi mode)

- Cursor shape switches **bar ↔ block** on insert/normal mode change; `KEYTIMEOUT=1` so Esc-to-vicmd is instant
- `Ctrl+R` — fzf history (oh-my-zsh fzf plugin default)
- `Ctrl+P` — fzf file widget
- `Ctrl+N` — accept autosuggestion
- `Up / Down` — history substring search
- vicmd `y` — yank line to system clipboard (cross-platform: `pbcopy` on macOS, `wl-copy` elsewhere; no trailing newline)
- `Alt+B / Alt+F / Alt+D / Alt+.` — emacs-style word nav even in vi-mode

### Hyprland — modifier `Super`

Apps
- `Super+Return` Alacritty · `Super+E` Yazi · `Super+D` / `Super+Space` Wofi
- `Super+V` clipboard history · `Super+Shift+L` lock screen

Windows
- `Super+h/j/k/l` focus · `Super+Shift+h/j/k/l` move · `Super+Alt+h/j/k/l` resize
- `Super+Q` kill · `Super+F` fullscreen · `Super+Shift+F` toggle floating · `Super+P` pseudo
- `Super+LMB` drag-move · `Super+RMB` drag-resize

Workspaces
- `Super+1…9` switch · `Super+Shift+1…9` move window to · `Super+Scroll` cycle

Media / system keys
- `XF86Audio*` volume / play / pause / next / prev · `XF86MonBrightness*` brightness
- `Print` / `Shift+Print` — screenshots (region / full)

### Alacritty

Hyprland deploy
- `Alt+B/F/D/.` — emacs word-nav escape sequences (zsh consumes)
- `Ctrl+C` copy · `Ctrl+V` paste · `Super+C` send ETX (SIGINT)

macOS deploy (mac)
- Comprehensive `Alt+<letter>` → ESC+letter mapping (zsh word nav)
- `Cmd+N` new window · middle-click paste

### Claude Code

- `editorMode: vim` set in both `~/.claude/settings.json` and `dotfiles/claude/settings.json` — all built-in vim motions in the prompt buffer.
- No custom `keybindings.json` defined (the file is opt-in; doesn't exist yet).

---

## Where it's already good

1. **`h j k l` is universal** — motion in nvim, tmux copy-mode, zsh vicmd, and hyprland focus all behave the same.
2. **Resize is universal** — `Alt+h/j/k/l` in nvim, tmux, and `Super+Alt+h/j/k/l` in Hyprland all extend in the direction of the key (`l` rightward, `j` downward).
3. **vim-tmux-navigator** unifies `Ctrl+h/j/k/l` across nvim and tmux without conflict.
4. **`Shift` = move** convention holds in Hyprland (`Super+Shift+H` moves windows) and Tmux window swap (`Shift+Left/Right`).
5. **Numerics are parallel**: `Space+N` jumps to tab N in nvim; `Super+N` jumps to workspace N in Hyprland. Same mental model, different modifier per layer.
6. **Vi mode in shell** matches the editor — yanking, motion, and `.` all transfer. Cursor shape advertises the current mode; mode-switching is instant.
7. **Copy/paste** is uniform inside terminals: `Ctrl+C / Ctrl+V` in Alacritty, `Super+C` for interrupt; tmux copy-mode `y` and `Enter` both reach the system clipboard; zsh vicmd `y` reaches the same clipboard; nvim `"+y` reaches the same clipboard.
8. **Split creation feels the same** in tmux (`<prefix> v / s`) and nvim (`<leader>wv / ws`).
9. **Cross-platform clipboard** — tmux-yank, the zsh yank function, and the keybindings doc itself all auto-detect `pbcopy` vs `wl-copy` per machine.

---

## Remaining proposals

Each item independent. R-numbers carry through from the original plan for git-history traceability; H/M/L items came from the second-pass review.

### R-3: Change tmux prefix to `Ctrl+Space`

`Ctrl+T` is fine, but it (a) shadows readline's `transpose-chars` for anyone who occasionally uses emacs mode, and (b) doesn't telegraph "tmux is in front of me." `Ctrl+Space` is the most common alternative for vim-flavoured tmux setups (no shell conflicts, single chord, easy to chord with letters).

Lower priority — only worth it if `Ctrl+T` has ever bitten.

### R-5: Lock in tmux digit binds

Today:
- Nvim:     `<leader>1…9` → tab N
- Hyprland: `Super+1…9` → workspace N
- Tmux:     `<prefix> 0…9` (default) → window N

Consistent in spirit, but the tmux side relies on tmux's default. Worth a comment in `.tmux.conf.j2` noting "1..9 must reach select-window" so nobody accidentally rebinds them.

### R-6: Claude Code — start a `keybindings.json`

`editorMode: vim` covers the prompt buffer. Beyond that, Claude Code supports a `~/.claude/keybindings.json` for TUI-level chords (submit key, accept/reject, plan mode).

Low-effort wins worth considering:
- A non-Enter submit (Ctrl+Enter or similar) so Enter can stay "newline".
- A chord for `/plan` so plan mode is one keystroke from any state.
- A bind to dismiss/cancel a running turn that doesn't conflict with Alacritty's new `Super+C` semantics.

The `keybindings-help` skill (`/keybindings-help` in Claude Code) documents the surface — invoke once and pick.

### R-8: Leader mental model in one paragraph

A consistent way to describe each tier to muscle-memory:

- **Window manager:** `Super` is the leader. `Super+letter` does WM-global things.
- **Terminal application (tmux):** `Ctrl+T` (or `Ctrl+Space` per R-3) then letter.
- **Editor (nvim):** `Space` then letter; `Tab` is localleader for ftplugin-only things.
- **Claude Code TUI:** built-in vim mode — no leader beyond what nvim teaches.

Worth pinning to the top of this doc once the layout stabilises (or just leaving it here — the five-layer table at the top already conveys it).

### M-1: Buffer cycling in nvim

You have `<leader>tn`/`tp` for tabs but no buffer-cycle chord. If you ever open files without `:tabnew`, you're stuck doing `:bn`/`:bp`. Add:

```lua
vim.keymap.set('n', ']b', ':bnext<CR>')
vim.keymap.set('n', '[b', ':bprev<CR>')
```

Matches the `]h`/`[h` (hunks) pattern.

### M-2: Tmux paste-from-system-clipboard

`<prefix> p` pastes from tmux's internal buffer. To paste from the *system* clipboard you have to use the terminal's paste chord. Add:

```tmux
bind P run-shell "tmux set-buffer \"$(wl-paste)\" && tmux paste-buffer"
```

With an `if-shell` Darwin branch using `pbpaste` (same shape as the late `@copy_cmd` we removed in H-3).

### L-1: Tab as localleader is overloaded

`<localleader> = Tab` collides conceptually with Tab-for-completion in insert mode and Tab-for-indent in normal mode. They're in separate modes so there's no actual conflict, but the mental model is muddy. Candidates: `,` (classic), `\\` (default), or just keep Space-localleader equal to Space-leader.

Low priority — only matters in clojure/go ftplugin where localleader is actually used.

---

## Quick consistency table

A snapshot of the current state. Rows are *concepts*; columns are *layers*.

| Concept | WM (Super) | Mux (Prefix=Ctrl+T) | Editor (Space leader) | Shell (vi) |
| --- | --- | --- | --- | --- |
| Move focus left/down/up/right | `Super+h/j/k/l` | `Ctrl+h/j/k/l` | `Ctrl+h/j/k/l` | `h/j/k/l` (vicmd) |
| Move thing | `Super+Shift+h/j/k/l` | `Shift+Left/Right` | (rare) | — |
| Resize | `Super+Alt+h/j/k/l` | `Alt+h/j/k/l` | `Alt+h/j/k/l` | — |
| New split / window | (auto-tile) | `Prefix v / s` | `Space wv / ws` | — |
| Switch to N | `Super+N` | `Prefix N` | `Space N` | — |
| Find files | — | — | `Ctrl+P` | `Ctrl+P` |
| Find text | — | — | `Ctrl+F` | — |
| History | — | — | — | `Ctrl+R` |
| Copy selection | — | copy-mode `y` / `Enter` | `y` | vicmd `y` |
| Paste | `Super+V` (clipboard hist) | `Prefix p` (internal) / *M-2 (system)* | `p` | `Ctrl+V` (insert raw) |
| Interrupt (TUI) | — | — | — | `Super+C` |

---

## Suggested adoption order for the remainder

1. **M-1** (buffer cycling) — three-line additive change, mirrors `]h`/`[h`.
2. **R-5** (lock in tmux digits) — defensive comment, no functional change.
3. **M-2** (tmux paste from system clipboard) — small additive change.
4. **R-8** (leader mental model) — paragraph; arguably already covered by the five-layer table.
5. **R-6** (Claude `keybindings.json`) — when a long prompt pushes you to want a non-Enter submit.
6. **R-3** (tmux prefix swap) and **L-1** (localleader change) — opt-in, do only if pain shows up.

---

## Changelog

- **2026-05** — Implemented R-1, R-2, R-4, R-7, H-1, H-2, H-3 and the zsh yank cross-platform fix. See commits `ae0041c`, `cdef02e`, `2b8e145`, `dcf59fd`, `57c16d4`, `e379971`.
