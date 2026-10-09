# Claude Code setup notes

How I set up and use [Claude Code](https://code.claude.com/docs) across machines (macOS with iTerm2 or
Ghostty, plus an Ubuntu box over SSH, with tmux everywhere).

| Note | What it covers |
|---|---|
| [tmux-fullscreen.md](tmux-fullscreen.md) | The fullscreen renderer in tmux: clean mouse selection, scrolling, transcript mode, Alt-key scroll bindings, and iTerm2 and Ghostty settings |
| [shared-settings.md](shared-settings.md) | Sharing `~/.claude/settings.json` preferences through public dotfiles: what each shared key does, the merge script, and what to keep per machine (`autoMode`, plugins) |
| [keybindings.json](keybindings.json) | My `~/.claude/keybindings.json`: Alt+J/K/G scroll keys for the fullscreen view |

My dotfiles, including the shared settings and the merge script, are in
[dotfiles-local](https://github.com/jonathanbranam/dotfiles-local).
