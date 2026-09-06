### Nvim - Shortcuts

```
<leader> - <space>
```

#### Window / Splits

```
<c-h> - move focus left (falls through to tmux)
<c-j> - move focus down
<c-k> - move focus up
<c-l> - move focus right
<c-w>o - close all splits except focused one
<alt-h/j/k/l> - resize split (narrower/taller/shorter/wider)
<leader>wv - vsplit
<leader>ws - split
<leader>wq - close split
```

#### Tabs

```
<leader>tt - new tab
<leader>tp - go to prev tab
<leader>tn - go to next tab
<leader>to - close all tabs except current one
<leader>tc - close tab
<leader>th - move tab left
<leader>tl - move tab right

<leader>1 - go to tab 1
<leader>2 - go to tab 2
.
<leader>9 - go to tab 9
<leader>0 - go to last tab
```

#### File explorer

While buffer is in focus:
```
<leader>fe - toggle file tree
<leader>ff - find current file
```

While the file tree is in focus:
```
o / enter - open file in the main buffer
v - open file in a vsplit
s - open file in a hsplit
a - create file/dir
r - rename
d - delete
y / Y / gy - copy name / relative path / absolute path
R - refresh
q - close tree
```

#### Search

```
<ctrl>p - find files (fzf-lua)
<ctrl>f - live grep (fzf-lua)
<leader>hh - help search
```

#### LSP

```
<c-]> - go to definition
K - hover docs
<c-k> - signature help
<c-space> - code actions
<leader>rn - rename symbol
<leader>dd - diagnostics -> quickfix
```

Format-on-save is automatic (lsp-format.nvim) — no manual format keymap.

#### Lint

```
<leader>ll - lint current buffer
```

Also runs automatically on save and on leaving insert mode.

#### Git

```
<leader>gb - git blame
<leader>gd - toggle diff view (diffview.nvim)
<leader>gl - file history (current buffer)
<leader>gL - file history (whole repo)
```

Hunks (gitsigns), in a modified buffer:
```
]h / [h - next / previous hunk
<leader>hs - stage hunk
<leader>hr - reset hunk
<leader>hp - preview hunk
```

#### Notes (zk)

```
<leader>nn - new note
<leader>nd - new daily note
<leader>no - open/list notes (sorted by modified)
<leader>nf - search notes
<leader>nt - tags
<leader>nb - backlinks
<leader>nl - links
<leader>np - paste image from clipboard
```

Visual mode, inside a note: `<leader>nn` new note from selected title, `<leader>nf` match selection.

#### Filetype-local

Go (`ftplugin/go.vim`):
```
<leader>gt - GoTest
<leader>gr - GoRename
<leader>glr - GoBuildTags ''
```

Clojure (`ftplugin/clojure.vim`), localleader = `<tab>`:
```
<localleader>cc - ConjureConnect
<localleader>f - cljfmt fix current file
```
