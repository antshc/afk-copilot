# afk-copilot

An autonomous coding agent that uses [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli) to pick up open GitHub issues and apply code changes — no human in the loop.

## Prerequisites

- [GitHub Copilot CLI](https://gh.io/copilot-cli) (`copilot`) in your `PATH`
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated
- `jq`

## Setup

Clone the repository and register the `afk` alias in your shell profile.

**1. Clone the repo:**

```bash
git clone https://github.com/your-org/afk-copilot.git ~/afk-copilot
```

**2. Add the alias** to your shell profile (`~/.bashrc`, `~/.zshrc`, `~/.bash_aliases`, etc.):

```bash
echo "alias afk='bash $HOME/afk-copilot/afk-log.sh'" >> ~/.bashrc
```

Or open the file manually and add:

```bash
alias afk='bash /path/to/afk-copilot/afk-log.sh'
```

**3. Reload your shell:**

```bash
source ~/.bashrc
```

Verify with `which afk` or `type afk`.

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