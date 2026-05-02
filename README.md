# afk-copilot

An autonomous coding agent that uses [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli) to pick up open GitHub issues and apply code changes — no human in the loop.

## Prerequisites

- [GitHub Copilot CLI](https://gh.io/copilot-cli) (`copilot`) in your `PATH`
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated
- `jq`

## Setup

Add an alias to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
alias afk='bash /home/dev/sources/afk-copilot/afk/afk.sh'
```

```bash
echo "alias afk='bash /home/dev/sources/afk-copilot/afk/afk.sh'" >> ~/.bash_aliases
```

Reload your shell or run `source ~/.bashrc`.

## Usage

Run from any repository:

```bash
cd /path/to/repository
afk <iterations>
```

Or specify a target directory:

```bash
afk <iterations> /path/to/repository
```

`<iterations>` is the maximum number of task cycles. Each iteration:

1. Reads the last 5 git commits and all open GitHub issues.
2. Sends them with the prompt to Copilot CLI, which autonomously picks a task, implements it, runs feedback loops, and commits.
3. Stops early if Copilot reports no remaining tasks.