### Tmux - Shortcuts

Most of the shortcuts have a prefix key as part of them. My prefix is `<ctrl>t`. For example to create new window `<prefix> c`, I have to hold `<ctrl>t` + `c`. 

```
<c-a> - Prefix
<prefix>r - reload config
```

#### Sessions

```
<prefix>:new -s <session-name> - creates new session
<prefix>w - open session list with tabs
```

#### Windows 

```
<prefix>c - create new window
<prefix>1 - go to window 1
<prefix>2 - go to window 2
.
<prefix><N> - go to window N
```

#### Splits

```
<prefix>v - vertical split
<prefix>s - horizontal split
<prefix>x - close split
```

#### Navigation

```
<ctrl>h - go to left split
<ctrl>l - go to right split
<ctrl>k - go to top split
<ctrl>j - go to bottom split
```

#### Copy mode

```
<prefix><c-]> - activate copy mode
v - start copy selection
y - copy selection
p - paste selection
```

#### Show all colors

```
for i in {0..255}; do                                             <<< printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
done
```
