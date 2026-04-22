# claude-multi

Run multiple Claude Code accounts in parallel. Shared sessions, full flag support, zero friction.

## Why claude-multi?

When you hit your token limit on one account, just switch profiles and resume the **same session** on another account. No re-login, no lost context.

### What makes it different

| Feature | claude-multi | claude-switch | CCS |
|---|---|---|---|
| Full flag forwarding (`-r`, `-c`, `-p`) | **Yes** | No | Yes |
| Auto-shared sessions across profiles | **Yes** | No | No |
| Parallel accounts | **Yes** | Yes | Yes |
| Resume same session on different account | **Yes** | No | No |
| Zero dependencies (just bash + gum) | **Yes** | Yes | No (Node.js) |
| Interactive menu | **Yes** | Yes | Yes |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hemilpatel/claude-multi/main/install.sh | sh
```

Or manually:
```bash
curl -fsSL https://raw.githubusercontent.com/hemilpatel/claude-multi/main/claude-multi -o ~/.local/bin/claude-multi
chmod +x ~/.local/bin/claude-multi
```

**Requires:** Claude Code CLI, [gum](https://github.com/charmbracelet/gum) (for interactive menus)

## Quick Start

```bash
# 1. Create profiles
claude-multi create work
claude-multi create personal

# 2. Log in to each (one-time)
claude-multi work            # type /login, authenticate with account 1
claude-multi personal        # type /login, authenticate with account 2

# 3. Run both in parallel
# Terminal 1:
claude-multi work

# Terminal 2:
claude-multi personal
```

## Usage

```
claude-multi <profile> [flags]    Launch with any Claude Code flags
claude-multi <command> [args]     Manage profiles
```

### Commands

| Command | Description |
|---|---|
| `claude-multi <name>` | Launch Claude with that profile |
| `claude-multi <name> -r` | Resume a session picker |
| `claude-multi <name> -c` | Continue most recent session |
| `claude-multi <name> -p "prompt"` | Print mode |
| `claude-multi create [name]` | Create a new profile (auto-shares sessions) |
| `claude-multi list` | Show all profiles, login status, sharing status |
| `claude-multi delete [name]` | Delete a profile |
| `claude-multi share [name]` | Enable session sharing for existing profile |
| `claude-multi status` | Show active Claude sessions |
| `claude-multi` | Interactive menu |

## When You Hit the Limit

```bash
# 1. Exit current session
Ctrl+D

# 2. Switch profile, resume same session
claude-multi personal -r

# 3. Pick the same session from the list
# Continue — billed to the other account
```

Sessions are shared across all profiles via symlink. Credentials stay isolated.

## How It Works

```
~/.claude/                    Default Claude config (source of truth)
~/.claude/projects/           All session data lives here
~/.claude-work/               Work profile
    projects -> ~/.claude/projects/   (symlink — shared sessions)
    .claude.json                      (own credentials)
    settings.json -> ~/.claude/...    (symlink — shared settings)
~/.claude-personal/           Personal profile
    projects -> ~/.claude/projects/   (symlink — shared sessions)
    .claude.json                      (own credentials)
    settings.json -> ~/.claude/...    (symlink — shared settings)
```

- **Credentials:** Isolated per profile (macOS Keychain / `.credentials.json`)
- **Sessions:** Shared via symlink to `~/.claude/projects/`
- **Settings, skills, plugins:** Symlinked from `~/.claude/`

## Uninstall

```bash
# Remove the tool
curl -fsSL https://raw.githubusercontent.com/hemilpatel/claude-multi/main/install.sh | sh -s -- --uninstall

# Or manually
rm ~/.local/bin/claude-multi

# Optionally remove profiles
rm -rf ~/.claude-work ~/.claude-personal
```

## License

MIT
