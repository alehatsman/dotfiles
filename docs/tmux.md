### Tmux - Shortcuts

Most of the shortcuts have a prefix key as part of them. The prefix is
`<ctrl>t`. For example, to create a new window `<prefix> c`, hold `<ctrl>t`
then press `c`.

```
<ctrl>t - Prefix
<prefix>r - reload config
```

#### Sessions

```
<prefix>:new -s <session-name> - creates new session
<prefix>w - open session/window picker (choose-tree)
```

#### Windows

```
<prefix>c - create new window (in current pane's cwd)
<prefix>1 - go to window 1
<prefix>2 - go to window 2
.
<prefix><N> - go to window N
<shift-left> / <shift-right> - swap window left / right (no prefix)
<prefix><ctrl-j> - fuzzy-jump to any Claude Code pane on the server
```

#### Splits / panes

```
<prefix>v - vertical split
<prefix>s - horizontal split
<prefix>x - close pane (tmux default, unbound here)
```

Move a pane instead of splitting:
```
<prefix>m - mark current pane
<prefix>V - join marked pane in as a vertical split
<prefix>S - join marked pane in as a horizontal split
<prefix>B - break current pane out to its own window
```

#### Navigation

```
<ctrl>h - go to left split
<ctrl>l - go to right split
<ctrl>k - go to top split
<ctrl>j - go to bottom split
<ctrl>\ - go to last split
<alt-h/j/k/l> - resize pane 3 cells in that direction
```

These fall through to the app in the pane (nvim, fzf, ...) when one is
running, instead of moving panes.

#### Copy mode

```
<prefix><c-[> - activate copy mode
v - start copy selection
y / <enter> - copy selection (OSC 52 -> system clipboard)
<prefix>p - paste selection
```

#### Show all colors

```
for i in {0..255}; do
  printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
done
```
