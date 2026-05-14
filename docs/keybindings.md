# Keybindings — Unified Vim-style Plan

A cross-tool view of every keybinding the dotfiles define, plus a proposal
for tightening them into one coherent vim-style scheme. The single-tool
cheatsheets (`nvim.md`, `tmux.md`) stay authoritative for their own tools.

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

This is already mostly consistent and is the strongest part of the setup:

| Combo | Layer | Action |
| --- | --- | --- |
| `h j k l` | Nvim (normal) | cursor motion |
| `h j k l` | Tmux copy-mode-vi | cursor motion in scrollback |
| `h j k l` | Zsh (vicmd) | cursor motion on the command line |
| `Ctrl+h/j/k/l` | Nvim ⇄ Tmux | pane navigation (via vim-tmux-navigator) |
| `Super+h/j/k/l` | Hyprland | focus left / down / up / right window |
| `Super+Shift+h/j/k/l` | Hyprland | move window left / down / up / right |
| `Super+Alt+h/j/k/l` | Hyprland | resize: narrower / taller / shorter / wider |
| `Alt+h/j/k/l` | Nvim | resize split: **wider / taller / shorter / narrower** ⚠ |
| `Alt+h/j/k/l` | Tmux | resize pane 3 cells in that direction |

⚠ Nvim's resize binds are **inverted** compared to Hyprland — `Alt+H`
makes the nvim split *wider*, but `Super+Alt+H` makes the Hyprland window
*narrower*. See [Issue R-1](#r-1-flip-nvim-resize-binds).

---

## Per-tool inventory

### Nvim — leader `Space`, localleader `Tab`

Window / split
- `Ctrl+h/j/k/l` — move focus (vim-tmux-navigator falls through to tmux)
- `Ctrl+W o` — only this window
- `Alt+h/j/k/l` — resize (see ⚠ above)

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
- `<prefix> [` enter · `v` begin selection · `y` copy to system clipboard · `<prefix> p` paste
- `h/j/k/l`, `w/b/e`, `gg/G`, `/` — vim motions in scrollback

### Zsh — `bindkey -v` (vi mode)

- `Ctrl+R` — history (default) · `Ctrl+Space` — fzf history widget
- `Ctrl+F` — fzf file widget · `Ctrl+N` — accept autosuggestion
- `Up / Down` — history substring search
- vicmd `y` — yank line to system clipboard (xclip)
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
2. **vim-tmux-navigator** unifies `Ctrl+h/j/k/l` across nvim and tmux without conflict — the kind of plumbing every tier deserves.
3. **`Shift` = move** convention holds in Hyprland (`Super+Shift+H` moves windows) and Tmux window swap (`Shift+Left/Right`).
4. **Numerics are parallel**: `Space+N` jumps to tab N in nvim; `Super+N` jumps to workspace N in Hyprland. Same mental model, different modifier per layer.
5. **Vi mode in shell** matches the editor — yanking, motion, and `.` all transfer.
6. **Copy/paste** is now uniform inside terminals after the recent Alacritty change: `Ctrl+C / Ctrl+V` everywhere, `Super+C` for interrupt.

---

## Inconsistencies and proposals

Each item below is independent — adopt or skip individually.

### R-1: Flip nvim resize binds to match Hyprland

Today:
- Nvim: `Alt+H` = wider, `Alt+L` = narrower (left key grows, right key shrinks)
- Hyprland: `Super+Alt+H` = narrower, `Super+Alt+L` = wider (left key shrinks, right key grows)

Hyprland's mapping is the more common tiling-WM convention (`l` extends to the right). Flip nvim to match.

```vim
" nvim/templates/init.lua — change these four lines
" before:
"   Alt-H → :vertical resize +2   (wider)
"   Alt-L → :vertical resize -2   (narrower)
" after:
"   Alt-H → :vertical resize -2   (narrower)
"   Alt-L → :vertical resize +2   (wider)
```

Tmux's `Alt+h/j/k/l` resize already matches Hyprland (the key direction *is* the resize direction), so this change brings nvim into line with both.

### R-2: Align FZF chords across nvim and zsh

Today:
- Nvim: `Ctrl+P` files, `Ctrl+F` grep
- Zsh:   `Ctrl+F` files, `Ctrl+Space` history

The same chord (`Ctrl+F`) opens *files* in zsh but does *grep* in nvim. Suggest the canonical fzf trio everywhere:

| Chord | Nvim | Zsh |
| --- | --- | --- |
| `Ctrl+P` | files (already) | **files (new)** |
| `Ctrl+F` | grep (already) | **grep — over history? skip** |
| `Ctrl+R` | (not used) | history (zsh default) |

Concrete `.zshrc.j2` change: rebind the fzf file widget from `Ctrl+F` to `Ctrl+P`, leave history on `Ctrl+R` (zsh's default behaviour). Drop `Ctrl+Space` for fzf-history — it overlaps with nvim's code-actions chord and is non-discoverable.

### R-3: Change tmux prefix to `Ctrl+Space`

`Ctrl+T` is fine, but it (a) shadows readline's `transpose-chars` for anyone who occasionally uses emacs mode, and (b) doesn't telegraph "tmux is in front of me." `Ctrl+Space` is the most common alternative for vim-flavoured tmux setups (no shell conflicts, single chord, easy to chord with letters).

Lower priority — only worth it if `Ctrl+T` has ever bitten. Otherwise leave it.

### R-4: Add `<leader>w…` window splits in nvim

Nvim has no shortcut for `:vsp` / `:sp`; you fall back to `:` commands or to `Ctrl+W v / s`. To match tmux's `<prefix> v / s`:

```
<leader>wv → :vsplit
<leader>ws → :split
<leader>wo → <C-w>o   " already roughly covered by <C-w>o
<leader>wq → :close
```

This makes "open a split" feel the same in tmux and nvim — both use `v` / `s` after a tier-leader.

### R-5: Mirror Hyprland's workspace digits with tmux windows

Today:
- Nvim:     `<leader>1…9` → tab N
- Hyprland: `Super+1…9` → workspace N
- Tmux:     `<prefix> 0…9` (default) → window N

This is already consistent in spirit but the tmux side relies on tmux's default. Worth a one-line confirmation in `.tmux.conf.j2` so it's not accidentally lost if someone rebinds `0…9`.

### R-6: Claude Code — start a `keybindings.json`

The user already runs `editorMode: vim`, which gets most of what matters in the prompt buffer. Beyond that, Claude Code supports a `~/.claude/keybindings.json` for TUI-level chords (submit key, accept/reject, plan mode, etc.).

Low-effort wins worth considering:
- A chord for "send and keep working" (alternative submit) for long prompts.
- A binding for `/plan` so plan mode is one keystroke from any state.

The `keybindings-help` skill (`/keybindings-help` in Claude Code) documents the full surface — invoke once and pick the bindings that match the rest of the scheme.

### R-7: Tmux copy-mode `Enter` should also yank

Today only `y` copies in tmux copy mode; `Enter` is unbound. Most users hit Enter reflexively after selecting. Add:

```
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
```

(or `pbcopy` on macOS — match the existing `y` binding's command).

### R-8: Standardise the "leader" mental model

A consistent way to describe each tier to muscle-memory:

- **Window manager:** `Super` is the leader. `Super+letter` does WM-global things.
- **Terminal application (tmux):** `Ctrl+T` (or `Ctrl+Space` per R-3) then letter.
- **Editor (nvim):** `Space` then letter; `Tab` is localleader for ftplugin-only things.
- **Claude Code TUI:** built-in vim mode — no leader beyond what nvim teaches.

Worth a one-paragraph note pinned to the top of this doc once the layout above stabilises.

---

## Quick consistency table

A snapshot of the proposed end state. Rows are *concepts*; columns are *layers*.

| Concept | WM (Super) | Mux (`Prefix=…`) | Editor (Space leader) | Shell (vi) |
| --- | --- | --- | --- | --- |
| Move focus left/down/up/right | `Super+h/j/k/l` | `Ctrl+h/j/k/l` | `Ctrl+h/j/k/l` | `h/j/k/l` (vicmd) |
| Move thing | `Super+Shift+h/j/k/l` | `Shift+Left/Right` | (rare) | — |
| Resize | `Super+Alt+h/j/k/l` | `Alt+h/j/k/l` | `Alt+h/j/k/l` *(post R-1)* | — |
| New split / window | (auto-tile) | `Prefix v / s` | `Space wv / ws` *(post R-4)* | — |
| Switch to N | `Super+N` | `Prefix N` | `Space N` | — |
| Find files | — | — | `Ctrl+P` | `Ctrl+P` *(post R-2)* |
| Find text | — | — | `Ctrl+F` | — |
| History | — | — | — | `Ctrl+R` |
| Copy selection | — | copy-mode `y` / `Enter` | `y` | vicmd `y` |
| Paste | `Super+V` (clipboard hist) | `Prefix p` | `p` | `Ctrl+V` (insert raw) |
| Interrupt (TUI) | — | — | — | `Super+C` |

---

## Recommended adoption order

1. **R-1 (flip nvim resize)** — one-line change, removes the only daily-pain inconsistency.
2. **R-7 (tmux Enter to copy)** — one-line change, matches reflex.
3. **R-2 (fzf chords)** — small change, gives `Ctrl+P` a single global meaning.
4. **R-4 (nvim split leader)** — small additive change, no breakage.
5. **R-5 (confirm tmux digit binds)** — defensive.
6. **R-8 (document leaders)** — paragraph at the top of this file.
7. **R-3 (tmux prefix swap)** and **R-6 (Claude keybindings.json)** — opt-in, do only if pain shows up.
