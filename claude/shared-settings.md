# Sharing Claude Code user settings across machines

My Claude Code preferences live in my public dotfiles,
[dotfiles-local](https://github.com/jonathanbranam/dotfiles-local), an [rcm](https://github.com/thoughtbot/rcm)
overlay on [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles). A small script merges them into each
machine's `~/.claude/settings.json`. The file Claude Code reads is never symlinked from the repo.

The pieces in dotfiles-local:

| File | Role |
|---|---|
| [`claude/settings.shared.json`](https://github.com/jonathanbranam/dotfiles-local/blob/main/claude/settings.shared.json) | The shared keys. rcm links it to `~/.claude/settings.shared.json` |
| `host-<name>/claude/settings.host.json` | Optional per-machine overrides, linked to `~/.claude/settings.host.json` on that machine only |
| [`local/bin/claude-settings-sync`](https://github.com/jonathanbranam/dotfiles-local/blob/main/local/bin/claude-settings-sync) | The merge script |
| [`hooks/post-up`](https://github.com/jonathanbranam/dotfiles-local/blob/main/hooks/post-up) | Runs the script after `rcup` |
| [`local/bin/dotfiles-update`](https://github.com/jonathanbranam/dotfiles-local/blob/main/local/bin/dotfiles-update) | The scheduled update job. Runs the script too, because its `rcup -K` skips hooks |

## Why not just symlink settings.json?

- **Claude Code writes to it all the time.** `/tui`, `/config`, `/model`, `/effort`, `/memory`, `/voice` and
  plugin installs all write there. A symlink would turn every one of those into an unreviewed change in the repo,
  or get replaced by a plain file, and then the machines quietly drift apart.
- **Some of its contents must not be public.** `autoMode.environment` describes your repos and infrastructure
  for the auto-mode classifier, and `env` is a common place to put API keys. `apiKeyHelper`, and MCP headers in
  `~/.claude.json`, can hold secrets too.
- **Some keys are per machine**, such as plugins and marketplaces.

**Don't name the tracked file `settings.local.json`**, even though that fits the dotfiles `.local` convention.
Claude Code already uses that name for a project's personal settings (`<repo>/.claude/settings.local.json`):

- **Claude Code would read a `~/.claude/settings.local.json` as project settings** whenever a session starts in
  `$HOME`.
- **It writes "always allow" permission answers into that file**, which would go through the symlink into the
  repo.
- **Global gitignores commonly exclude it.**

## The shared settings

[`claude/settings.shared.json`](https://github.com/jonathanbranam/dotfiles-local/blob/main/claude/settings.shared.json):

```json
{
  "editorMode": "vim",
  "statusLine": {
    "type": "command",
    "command": "bridle statusline"
  },
  "agentPushNotifEnabled": true,
  "autoMemoryEnabled": false,
  "autoDreamEnabled": false,
  "tui": "fullscreen",
  "promptSuggestionEnabled": false,
  "voiceEnabled": false,
  "voice": {
    "enabled": false,
    "mode": "hold"
  },
  "model": "opus",
  "effortLevel": "medium",
  "theme": "dark"
}
```

| Key | Value | What it does |
|---|---|---|
| `editorMode` | `"vim"` | Vim-style editing in the prompt input, with NORMAL, INSERT and VISUAL modes. The default is `"normal"` |
| `statusLine` | command `bridle statusline` | Runs a command to draw a status line below the prompt. The command gets session JSON (model, context window, cost and so on) on stdin and prints the line. `bridle` is my own tool; any script works, and a minimal `jq` example is below. Optional extra fields: `padding`, `refreshInterval` (seconds), `hideVimModeIndicator` |
| `agentPushNotifEnabled` | `true` | Lets Claude push a notification to your phone when it decides one is worth sending, such as when a long task finishes. Arrives while [Remote Control](https://code.claude.com/docs/en/remote-control) is connected. In `/config` it's "Push when Claude decides". The default is `false` |
| `autoMemoryEnabled` | `false` | Turns off [auto memory](https://code.claude.com/docs/en/memory). Claude neither reads nor writes its auto-memory directory. I keep anything worth remembering in repo docs instead, where it's reviewable. `CLAUDE_CODE_DISABLE_AUTO_MEMORY` overrides it for a session |
| `autoDreamEnabled` | `false` | The background "dream" pass that goes with auto memory and consolidates what it stored. It isn't in the settings reference, so treat this description as unofficial. Off to match `autoMemoryEnabled` |
| `tui` | `"fullscreen"` | The flicker-free alternate-screen renderer with mouse support. See [tmux-fullscreen.md](tmux-fullscreen.md). `"default"` is the classic renderer; unset lets Claude Code choose, which depends on when the machine first ran Claude Code |
| `promptSuggestionEnabled` | `false` | Hides the grayed-out predicted prompts in the input box |
| `voice` | `{ "enabled": false, "mode": "hold" }` | Voice dictation off. `mode` is `"hold"` (hold the key while speaking) or `"tap"`. `/voice` writes this object |
| `voiceEnabled` | `false` | The deprecated predecessor of `voice.enabled`, kept because older installs still had it. When both are set, `voice.enabled` wins |
| `model` | `"opus"` | The model each new session starts with. An alias or a full model ID. `/model` still switches mid-session, and `--model` or `ANTHROPIC_MODEL` override it |
| `effortLevel` | `"medium"` | The default reasoning effort: `low`, `medium`, `high` or `xhigh`. It applies only to models you haven't saved a level for with `/effort`, since those per-model levels win (`/effort auto` clears one). `--effort` and `CLAUDE_CODE_EFFORT_LEVEL` override it |
| `theme` | `"dark"` | The color theme. Others include `auto`, `light`, the `-daltonized` and `-ansi` variants, and custom themes. `"dark"` is the default anyway; it's set here so it's explicit |

Descriptions are from the [settings reference](https://code.claude.com/docs/en/settings-reference) as of
Claude Code 2.1.295.

A minimal status-line command, if you don't have one:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0)% context\"'"
  }
}
```

### What stays per machine

These keys are left out of the shared file on purpose, and the merge never touches them:

- **`enabledPlugins` and `extraKnownMarketplaces`**: which plugins each machine needs differs, for example
  rust-analyzer only where I write Rust.
- **`autoMode`**: see below.
- **Anything Claude Code adds later.**

## autoMode: one block per machine, never shared

`autoMode.environment` is free text that tells the auto-mode permission classifier about your environment:
trusted repos, which ones are public, production hosts, where sensitive data lives.

- **It's read only from user or managed settings.** Claude Code ignores it in a repo's `.claude/settings.json`
  and `.claude/settings.local.json`. So it can't be split per repo, and each machine gets exactly one block.
- **Describe the whole machine.** List every trusted repo on it and which are public. A block generated inside
  one repo and saved at user level ends up describing only that repo, even though it applies to every session
  on the machine.
- **Keep it out of any public repo.** It describes infrastructure.

## The merge script

[`local/bin/claude-settings-sync`](https://github.com/jonathanbranam/dotfiles-local/blob/main/local/bin/claude-settings-sync):

```sh
#!/bin/sh
# Added 2026-10-09: merge tracked Claude Code settings into ~/.claude/settings.json.
# Claude Code writes that file itself (/tui, /config, /model, plugins, autoMode), so it can't be a
# symlink into this public repo. Instead the tracked files are deep-merged over it, in order:
#   ~/.claude/settings.shared.json   (claude/settings.shared.json, every machine)
#   ~/.claude/settings.host.json     (host-<name>/claude/settings.host.json, optional)
# Tracked keys win; every other key stays local and never enters the repo. Rewrites only on change,
# keeping the previous file as settings.json.bak. Removing a key from a tracked file doesn't remove
# it locally. Usage: claude-settings-sync [-q]
set -eu

dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
target=$dir/settings.json
quiet=
[ "${1:-}" = -q ] && quiet=1

warn() { echo "claude-settings-sync: $*" >&2; }

command -v jq >/dev/null 2>&1 || { [ -n "$quiet" ] || warn "jq not found, skipping"; exit 0; }

set --
for f in "$dir/settings.shared.json" "$dir/settings.host.json"; do
  [ -f "$f" ] && set -- "$@" "$f"
done
[ $# -gt 0 ] || exit 0

[ -f "$target" ] || printf '{}\n' >"$target"

tmp=$(mktemp "$dir/.settings.json.XXXXXX")
trap 'rm -f "$tmp"' EXIT

# Errors print even with -q: a silent failure would hide a broken settings file.
jq -s 'reduce .[] as $x ({}; . * $x)' "$target" "$@" >"$tmp" || { warn "merge failed, $target unchanged"; exit 1; }

jq -e -s '.[0] == .[1]' "$target" "$tmp" >/dev/null && exit 0

cp "$target" "$target.bak"
chmod 644 "$tmp"
mv "$tmp" "$target"
[ -n "$quiet" ] || echo "claude-settings-sync: updated $target (previous in settings.json.bak)"
```

How it works:

- **The merge is jq's `*`**, which deep-merges objects left to right. The order is the existing
  `settings.json`, then the shared file, then the host file, so tracked values win.
  - **Nested objects merge key by key**: setting `statusLine.padding` locally survives a shared `statusLine`
    that doesn't mention it.
  - **Arrays are replaced whole.** Keep array-valued keys such as `permissions.allow` out of the shared file
    unless you want them identical everywhere.
  - **Key order is preserved**, and new keys are appended, so diffs of `settings.json` stay small.
- **It's idempotent.** It compares the merged result with the current file and writes nothing when they're
  equal, so it's safe to run as often as you like.
- **The write is safe.**
  - It writes to a temp file in the same directory, then `mv`s it into place, so Claude Code never reads a
    half-written file.
  - The previous version is kept as `settings.json.bak`.
  - If the current file isn't valid JSON, it leaves it alone and exits 1, printing an error even with `-q`.
- **It respects `CLAUDE_CONFIG_DIR`**, the same variable Claude Code uses, which also makes it easy to test
  against a scratch copy.

Things to know:

- **Tracked keys win every time it runs.** If you change a shared key with `/model`, `/effort` or `/tui`, the
  next sync puts the tracked value back. Change the JSON for anything permanent.
- **Removing a key from the shared file doesn't remove it from machines.** Delete it from their
  `settings.json` by hand, or set it to the value you want.
- **It needs `jq`.** Without it the script skips the merge and only warns when not in quiet mode.

## When it runs

[`hooks/post-up`](https://github.com/jonathanbranam/dotfiles-local/blob/main/hooks/post-up) runs it after every
`rcup`:

```sh
#!/bin/sh
# Added 2026-10-09: apply claude/settings.shared.json right after rcup links it.
# Called by path because ~/.local/bin may not be on PATH during a first rcup.
exec "$(dirname "$0")/../local/bin/claude-settings-sync"
```

rcm runs `hooks/post-up` from every directory in `DOTFILES_DIRS`, so this runs alongside thoughtbot's own hook.

The scheduled job, `local/bin/dotfiles-update`, does `git pull --ff-only` and then `rcup -K`. The `-K` skips all
hooks, mainly to avoid thoughtbot's `post-up`, which updates vim plugins over the network and resets the
terminal. Neither belongs in an unattended job. So the job calls the script directly:

```sh
# Added 2026-10-09: rcup -K skips hooks/post-up, so apply the tracked Claude Code settings directly.
out=$("$clone/local/bin/claude-settings-sync" 2>&1) || say "ERROR: claude-settings-sync failed: $out"
```

To run it by hand on any machine, use `claude-settings-sync` (it's on `PATH` through `~/.local/bin`).

## Adding a per-machine override

Create `host-<name>/claude/settings.host.json` in dotfiles-local with just the keys that differ, then run
`rcup` on that machine. For example, a machine that should default to high effort:

```json
{
  "effortLevel": "high"
}
```

## Setting it up on a new machine

1. Install `jq`.
2. Clone dotfiles-local and run `rcup`. That links `~/.claude/settings.shared.json` and runs the post-up hook,
   which does the merge.
3. Check the result with `jq . ~/.claude/settings.json`, and compare it with `settings.json.bak` if one was
   written.
4. Fill in that machine's `autoMode.environment` by hand if you use auto mode.
