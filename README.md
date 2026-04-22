<p align="center">
  <h1 align="center">claude-multi</h1>
  <p align="center">
    Run multiple Claude Code accounts in parallel.<br>
    Shared sessions. Full flag support. Zero friction.
  </p>
  <p align="center">
    <a href="#install">Install</a> &nbsp;&bull;&nbsp;
    <a href="#quick-start">Quick Start</a> &nbsp;&bull;&nbsp;
    <a href="#commands">Commands</a> &nbsp;&bull;&nbsp;
    <a href="#how-it-works">How It Works</a>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue" alt="Platform">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
    <img src="https://img.shields.io/badge/version-1.0.0-orange" alt="Version">
    <img src="https://img.shields.io/badge/shell-bash-yellow" alt="Shell">
  </p>
</p>

---

## The Problem

You're deep in a coding session. Claude is on fire. Then —

```
Usage limit reached. Please wait before sending another message.
```

You lose your flow. You wait. Minutes pass. Momentum gone.

## The Solution

**claude-multi** lets you run multiple Claude Code accounts side by side. When one account hits its limit, switch to another and **resume the exact same session** — no re-login, no lost context, no waiting.

```bash
# Account 1 hit the limit? Just switch.
claude-multi personal -r    # pick the same session, keep going
```

---

## Install

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/Hemil4/claude-multi/main/install.sh | sh
```

<details>
<summary><strong>Manual install</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/Hemil4/claude-multi/main/claude-multi -o ~/.local/bin/claude-multi
chmod +x ~/.local/bin/claude-multi
```

</details>

<details>
<summary><strong>Requirements</strong></summary>

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) — the official CLI
- [gum](https://github.com/charmbracelet/gum) — for interactive menus (auto-installed via Homebrew)
- macOS or Linux

</details>

---

## Quick Start

**30 seconds to set up. Use forever.**

### 1. Create profiles

```bash
claude-multi create work
claude-multi create personal
```

### 2. Log in to each (one-time)

```bash
claude-multi work        # Claude opens → type /login → authenticate account 1
claude-multi personal    # Claude opens → type /login → authenticate account 2
```

### 3. Run both in parallel

```bash
# Terminal 1                    # Terminal 2
claude-multi work               claude-multi personal
```

Both accounts running. Side by side. Shared sessions. Independent credentials.

---

## When You Hit the Limit

This is the killer feature. Here's the workflow:

```
1. You're working in:   claude-multi work
2. Account hits limit   → Exit with Ctrl+D
3. Switch account:      claude-multi personal -r
4. Pick same session    → Continue where you left off
5. Billed to personal   → Zero downtime
```

Sessions are shared across all profiles. Only credentials are isolated.

---

## Commands

```
claude-multi <profile> [flags]     Launch with any Claude Code flags
claude-multi <command> [args]      Manage profiles
```

### Profile Management

| Command | Description |
|---|---|
| `claude-multi create [name]` | Create a new profile (auto-shares sessions) |
| `claude-multi list` | Show all profiles with login & sharing status |
| `claude-multi delete [name]` | Delete a profile (with confirmation) |
| `claude-multi share [name]` | Enable session sharing for existing profile |
| `claude-multi status` | Show active Claude processes |
| `claude-multi` | Interactive menu |

### Launching Profiles

All Claude Code flags work natively:

```bash
claude-multi work                   # launch work profile
claude-multi work -r                # resume session picker
claude-multi work -c                # continue most recent session
claude-multi work -p "fix the bug"  # print mode
claude-multi personal -r            # resume on personal account
```

---

## How It Works

```
~/.claude/                          Source of truth
  projects/                         All sessions live here
  settings.json                     Your settings
  skills/                           Your skills
  plugins/                          Your plugins

~/.claude-work/                     Work profile
  projects  -->  ~/.claude/projects/     Symlink (shared sessions)
  settings  -->  ~/.claude/settings.json Symlink (shared config)
  skills    -->  ~/.claude/skills/       Symlink (shared skills)
  .claude.json                           Own credentials (isolated)

~/.claude-personal/                 Personal profile
  projects  -->  ~/.claude/projects/     Symlink (shared sessions)
  settings  -->  ~/.claude/settings.json Symlink (shared config)
  skills    -->  ~/.claude/skills/       Symlink (shared skills)
  .claude.json                           Own credentials (isolated)
```

### What's shared vs isolated

| | Shared | Isolated |
|---|---|---|
| Sessions & history | Symlinked from `~/.claude/projects/` | |
| Settings, skills, plugins | Symlinked from `~/.claude/` | |
| OAuth credentials | | Per-profile (Keychain / file) |
| Login identity | | Per-profile |
| Billing & quota | | Per-account |

---

## Comparison

| Feature | claude-multi | claude-switch | CCS |
|---|---|---|---|
| Full flag forwarding (`-r`, `-c`, `-p`) | **Yes** | No | Yes |
| Auto-shared sessions | **Yes** | No | No |
| Resume same session on another account | **Yes** | No | No |
| Parallel accounts | **Yes** | Yes | Yes |
| Zero dependencies (bash + gum) | **Yes** | Yes | No (Node.js) |
| Interactive menu | **Yes** | Yes | Yes |
| Profile status dashboard | **Yes** | No | Yes |
| Multi-provider (Gemini, etc.) | No | No | Yes |

---

## FAQ

<details>
<summary><strong>Can I resume a session started on account A using account B?</strong></summary>

Yes — that's the whole point. Sessions are shared across all profiles via symlink. When you resume on a different account, it continues the same conversation but bills the new account.

</details>

<details>
<summary><strong>Will account credentials leak between profiles?</strong></summary>

No. Credentials are stored separately per profile (in macOS Keychain or `.claude.json`). Only conversation history and settings are shared.

</details>

<details>
<summary><strong>Does it work with VS Code extension?</strong></summary>

claude-multi is a terminal tool. For VS Code, you'd need to configure `CLAUDE_CONFIG_DIR` in your extension settings per workspace.

</details>

<details>
<summary><strong>Can I use more than 2 accounts?</strong></summary>

Yes. Create as many profiles as you have accounts:

```bash
claude-multi create work
claude-multi create personal
claude-multi create team
claude-multi create freelance
```

</details>

<details>
<summary><strong>What happens if I reinstall Claude Code?</strong></summary>

claude-multi is independent of Claude Code. Your profiles and sessions are safe. Just re-login to each profile after reinstalling Claude.

</details>

<details>
<summary><strong>Is it safe?</strong></summary>

claude-multi is a single bash script (~300 lines). It doesn't touch tokens, make network calls, or send telemetry. It only manages config directories and calls the official `claude` binary. [Read the source](https://github.com/Hemil4/claude-multi/blob/main/claude-multi) — it takes 5 minutes.

</details>

---

## Uninstall

```bash
# Remove the tool
curl -fsSL https://raw.githubusercontent.com/Hemil4/claude-multi/main/install.sh | sh -s -- --uninstall

# Or manually
rm ~/.local/bin/claude-multi

# Optionally remove profiles (keeps your default ~/.claude/ intact)
rm -rf ~/.claude-work ~/.claude-personal
```

---

## Contributing

Contributions welcome! Feel free to open issues or submit PRs.

```bash
git clone https://github.com/Hemil4/claude-multi.git
cd claude-multi
# Edit claude-multi (it's just bash)
# Test locally: ./claude-multi help
```

---

## License

MIT - see [LICENSE](LICENSE)

---

<p align="center">
  <strong>Stop waiting. Start switching.</strong><br>
  <sub>Built for developers who refuse to lose momentum.</sub>
</p>
