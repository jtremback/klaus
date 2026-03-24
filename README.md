# Klaus

Sandboxed [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in Docker.

Klaus runs Claude Code inside a container with `--dangerously-skip-permissions`, so you get full autonomous coding without risk to your system. Your project directory is mounted read-write; everything else is isolated.

## Install

```bash
curl -fsSL https://github.com/jtremback/klaus/releases/latest/download/install.sh | bash
```

Or from a local clone:

```bash
git clone https://github.com/jtremback/klaus.git
cd klaus
./install.sh
```

Requires Docker.

## Usage

```bash
cd ~/projects/my-app
klaus                        # interactive session
klaus -p "fix the tests"     # one-shot prompt
klaus --print "explain main" # print mode (no edits)
```

### Klausfile

Drop a `Klausfile` in your project root to pre-install tools. It's a Dockerfile fragment — `RUN`, `ENV`, etc. Commands run as a user with passwordless `sudo`.

```dockerfile
RUN sudo apt-get update && sudo apt-get install -y postgresql-client
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/klaus/.cargo/bin:${PATH}"
RUN pip3 install --break-system-packages numpy pandas
```

The image is cached per Klausfile hash — it only rebuilds when the file changes. If a tool is missing mid-session, Claude can `sudo apt-get install` it on the spot and update the Klausfile for next time.

### Authentication

Klaus finds your Anthropic credentials automatically:

1. `ANTHROPIC_API_KEY` env var
2. `ANTHROPIC_AUTH_TOKEN` env var
3. macOS Keychain (from `claude login`)
4. `~/.claude/.credentials.json` (Linux)

### Other commands

```bash
klaus build       # rebuild the Docker image
klaus seed        # re-copy settings from ~/.claude
klaus update      # update to the latest release
klaus version     # print version
klaus uninstall   # remove everything
klaus help        # full usage info
```

## What's in the base image

Debian bookworm-slim with: git, ripgrep, fd, jq, build-essential, python3, pip, node, npm, curl, wget, ssh, and Claude Code CLI.

## How it works

On first run, Klaus seeds the sandbox from your existing Claude Code setup so you start with all your usual settings:

- `~/.claude/` is copied to `~/.klaus/claude/` — your settings, theme, plugins, memory, conversation history, project-level configs, all of it
- `~/.claude.json` is copied to `~/.klaus/.claude.json` — your app state (skips onboarding, preserves preferences)
- Your project's `CLAUDE.md` and `.claude/` settings come in through the mounted project directory as usual

After seeding, the sandbox is fully independent. Changes Claude makes to settings or memory inside Klaus stay in `~/.klaus/` and don't affect your host `~/.claude/`. Run `klaus seed` any time to refresh the sandbox from your host settings.

### File layout

- `~/.klaus/install/` — the tool itself (Dockerfile, scripts)
- `~/.klaus/claude/` — sandboxed Claude config (isolated copy of `~/.claude/`)
- `~/.klaus/.claude.json` — sandboxed Claude app state (isolated copy of `~/.claude.json`)
- Your project is mounted at its real host path so Claude sees the correct directory

## Uninstall

```bash
klaus uninstall
```
