#!/bin/bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

iterations=5
target_repo=""

if [[ -n "$1" ]]; then
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    iterations="$1"
    target_repo="$2"
  else
    target_repo="$1"
  fi
fi

if [ -n "$target_repo" ]; then
  cd "$target_repo"
fi

# jq filter to extract streaming text deltas
stream_text='select(.type == "assistant.message_delta") | .data.deltaContent // empty'

# jq filter to extract final complete message
final_message='select(.type == "assistant.message") | .data.content // empty'

for ((i=1; i<=iterations; i++)); do
  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT

  commits=$(git log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")
  issues=$(gh issue list --state open --json number,title,body,comments)
  prompt=$(cat "$SCRIPT_DIR/prompt.md")

  copilot \
    -p "$(printf '# GitHub Issues\n\n%s\n\n# Previous Commits\n\n%s\n\n%s' "$issues" "$commits" "$prompt")" \
    --model claude-sonnet-4.6 \
    --effort medium \
    --output-format json \
    --allow-all-tools \
    --no-ask-user \
    --log-level debug \
    --log-dir "$SCRIPT_DIR/logs" \
    --deny-tool='shell(git push)' \
    --deny-tool='shell(git reset)' \
    --deny-tool='shell(git rebase)' \
    --deny-tool='shell(git clean)' \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$stream_text"

  result=$(jq -r "$final_message" "$tmpfile" | tail -1)

  if [[ "$result" == *"<promise>NO MORE TASKS</promise>"* ]]; then
    echo "Ralph complete after $i iterations."
    exit 0
  fi
done
