# Claude Code in tmux: fullscreen rendering and keyboard scrolling

This note gets Claude Code working well inside tmux on macOS: mouse selection without the left margin,
scrolling that works, and scrolling from the keyboard. It covers iTerm2 and Ghostty.

## The problem

Running Claude Code in a tmux pane with tmux mouse mode on:

- Mouse selection copied the two-space left margin Claude Code draws.
- tmux scrollback came out garbled, because Claude Code's classic renderer redraws and trims the screen.

Yet running Claude Code over SSH on a NUC (a small Ubuntu box), inside tmux there, worked perfectly. Mouse
selection and wheel scrolling went to Claude Code in its pane and to tmux in every other pane, with no margin in
copied text.

## The cause

Claude Code has two renderers:

- **classic** (`"tui": "default"`): prints into the terminal's normal scrollback. tmux copy mode sees it, but
  redraws garble it, and selection includes the margin.
- **fullscreen** (`"tui": "fullscreen"`): draws on the alternate screen, like vim. It handles the mouse itself,
  selecting without the margin and copying on release (to the clipboard and the tmux paste buffer). It also
  scrolls itself, and keeps memory flat in long conversations.

Which one you start in depends on when you first used Claude Code on that machine. Machines first used on or
after 2026-05-06 default to fullscreen, which is why the NUC worked. Older installs default to classic.
Claude Code offers a startup dialog to switch, but stops offering after three launches, so it's easy to miss.
The full rules are in the [fullscreen docs](https://code.claude.com/docs/en/fullscreen#fullscreen-by-default).

## The fix

In any Claude Code session:

```
/tui fullscreen
```

It relaunches in place with the conversation intact and saves `"tui": "fullscreen"` to
`~/.claude/settings.json`. `/tui default` switches back, and `/tui` on its own reports which renderer is active.

The alternatives are the setting itself or an environment variable (the variable overrides the setting):

```json
{
  "tui": "fullscreen"
}
```

```sh
export CLAUDE_CODE_NO_FLICKER=1
```

To share the setting across machines, see [shared-settings.md](shared-settings.md).

tmux needs mouse mode, or the wheel goes to tmux instead of Claude Code:

```tmux
set -g mouse on
```

tmux 3.7 supports synchronized output. Releases through the 3.6 series don't, so they flicker more during
redraws.

## What works differently in fullscreen

| Before (classic) | Now (fullscreen) |
|---|---|
| Terminal/tmux click and drag | In-app selection, copies on mouse release. Hold Option (iTerm2) or Shift (Ghostty) for native selection |
| tmux copy mode or Cmd+F to search | `Ctrl+O` for transcript mode, then `/` to search |
| Scroll with tmux copy mode | Wheel, `PgUp`/`PgDn`, or the keybindings below |

**Transcript mode** (`Ctrl+O`, which also shows thinking and expanded tool output) has less-style keys:

| Key | Action |
|---|---|
| `j` / `k` | Scroll one line |
| `Ctrl+U` / `Ctrl+D` | Scroll half a page |
| `Ctrl+B` / `Ctrl+F`, `b` / `Space` | Scroll a full page |
| `g` / `G` | Jump to top / bottom |
| `{` / `}` | Jump to previous / next prompt |
| `/`, then `n` / `N` | Search, next / previous match |
| `[` | Write the whole conversation into the real scrollback, so tmux copy mode works on it |
| `v` | Open the conversation in `$EDITOR` |
| `q`, `Esc`, `Ctrl+O` | Back to the prompt |

**From the prompt:**
- `PgUp` / `PgDn` (`Fn+↑` / `Fn+↓` on a Mac keyboard) scroll half a screen.
- `Ctrl+Home` / `Ctrl+End` jump to the ends. `Ctrl+End` doesn't get through from a Mac keyboard, which is one
  reason for the keybindings below.
- `/scroll-speed` adjusts wheel speed.

**tmux:** don't press a key that tmux binds to enter copy mode (for example `bind -n M-Up copy-mode`) in a
Claude Code pane. tmux copy mode only shows the alternate screen, not the conversation history.

## Keyboard scrolling without Page Up and Page Down

[`keybindings.json`](keybindings.json) adds vim-ish Alt keys in the `Scroll` context, which is the fullscreen
conversation view. Copy it to `~/.claude/keybindings.json`:

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "$docs": "https://code.claude.com/docs/en/keybindings",
  "bindings": [
    {
      "context": "Scroll",
      "bindings": {
        "alt+k": "scroll:halfPageUp",
        "alt+j": "scroll:halfPageDown",
        "alt+g": "scroll:top",
        "alt+shift+g": "scroll:bottom"
      }
    }
  ]
}
```

- **The bindings add to the defaults**, so `PgUp`/`PgDn` and transcript mode keep working.
- **`alt+shift+g` re-enables auto-follow**, which is what `Ctrl+End` would do.
- **The file is portable.** It has nothing machine-specific in it, and Claude Code never rewrites it, so a
  plain dotfiles symlink is fine.
- **Copy it to every machine that runs Claude Code.** Claude Code reads it on the machine where it runs, so a
  machine you SSH into needs its own copy.
- **Why not Ctrl keys?** They're crowded. `ctrl+d` can't be rebound, vim-tmux-navigator uses `ctrl+h/j/k/l`,
  and the prompt or Claude Code already uses `ctrl+u/f/b/y`.

The terminal has to send Option as Alt, or these keys type `∆`, `˚` and `©` instead. See the next section.

## Terminal settings

### iTerm2

| Setting | Where | Why |
|---|---|---|
| Enable mouse reporting: **on** | Settings → Profiles → Terminal | Without it the wheel, selection and click-to-expand don't reach Claude Code |
| Left Option key: **Esc+** | Settings → Profiles → Keys → General (every profile you use) | Alt keybindings. Leave Right Option on Normal if you type `é` and friends |
| Applications in terminal may access clipboard: **on** | Settings → General → Selection | Copying from a Claude Code running over SSH (OSC 52). A local one uses `pbcopy`. `/terminal-setup` turns this on |

- **Native selection:** hold Option while dragging.
- **Don't use `tmux -CC`:** iTerm2's tmux integration mode is incompatible with fullscreen rendering, so
  Claude Code falls back to classic there. Plain `tmux` inside iTerm2 is fine.

### Ghostty

In `~/.config/ghostty/config`:

```
# Option as Alt for the Claude Code scroll keybindings; right Option still types symbols
macos-option-as-alt = left
```

Reload with `Cmd+Shift+,`. Use `true` instead of `left` for both Option keys.

- **No other settings needed:** mouse reporting and OSC 52 clipboard writes are on by default.
- **Native selection:** hold Shift while dragging.
- **Links:** a plain click on a URL opens it, and Cmd-click still works.
- **Wheel speed:** Ghostty already accelerates wheel events. If scrolling is too fast, lower it with
  `/scroll-speed`.

**Side effect, in either terminal:** Option now works as Meta in the shell, so `Alt+B` / `Alt+F` move by word
and `Alt+.` inserts the last argument.
