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

  docker run --rm -i \
    --cap-add NET_ADMIN --cap-add SETUID --cap-add SETGID --cap-drop ALL \
    --network host \
    -e COPILOT_GITHUB_TOKEN="$COPILOT_GITHUB_TOKEN" \
    -e COPILOT_OUTPUT_FORMAT=json \
    -e COPILOT_EFFORT=medium \
    -e COPILOT_LOG_LEVEL=debug \
    -e COPILOT_MODEL=claude-sonnet-4.6 \
    -v "/home/pet/_projects/sandbox_runtime/logs/mitmproxy:/var/log/mitmproxy" \
    -v "/home/pet/_projects/sandbox_runtime/logs/copilot:/var/log/copilot" \
    -v "$(pwd):/home/ubuntu/workspace" \
    khdevnet/sandbox copiloty \
      "$(printf '# GitHub Issues\n\n%s\n\n# Previous Commits\n\n%s\n\n%s' "$issues" "$commits" "$prompt")" \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$stream_text"

  result=$(jq -r "$final_message" "$tmpfile" | tail -1)

  if [[ "$result" == *"<promise>NO MORE TASKS</promise>"* ]]; then
    echo "Ralph complete after $i iterations."
    exit 0
  fi
done
