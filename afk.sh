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

# jq filter to extract streaming text from assistant messages
stream_text='select(.type == "assistant.message_delta").data.text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'

# jq filter to extract final result (accumulated assistant text content)
final_result='[select(.type == "assistant.message").data.content // empty] | add // empty'

LOG_DIR="$SCRIPT_DIR/runtime/logs/afk"
mkdir -p "$LOG_DIR"
RUN_LOG="$LOG_DIR/run_$(date +%Y%m%dT%H%M%S).log"

for ((i=1; i<=iterations; i++)); do
  tmpfile=$(mktemp)
  prompt_file=$(mktemp)
  trap "rm -f $tmpfile $prompt_file" EXIT

  commits=$(git log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")
  issues=$(gh issue list --state open --json number,title,body,comments)
  prompt=$(cat "$SCRIPT_DIR/prompt.md")

  printf '# GitHub Issues\n\n%s\n\n# Previous Commits\n\n%s\n\n%s' "$issues" "$commits" "$prompt" > "$prompt_file"

  docker run --rm -i \
    --cap-add NET_ADMIN --cap-add SETUID --cap-add SETGID --cap-drop ALL \
    --network host \
    -e COPILOT_GITHUB_TOKEN="$COPILOT_GITHUB_TOKEN" \
    -e COPILOT_OUTPUT_FORMAT=json \
    -e COPILOT_EFFORT=medium \
    -e COPILOT_LOG_LEVEL=debug \
    -e COPILOT_MODEL=claude-sonnet-4.6 \
    -v "$SCRIPT_DIR/runtime/logs/mitmproxy:/var/log/mitmproxy" \
    -v "$SCRIPT_DIR/runtime/logs/copilot:/var/log/copilot" \
    -v "$(pwd):/home/ubuntu/workspace" \
    -v "$prompt_file:/tmp/prompt.md" \
    khdevnet/sandbox copiloty \
      "@/tmp/prompt.md" \
  | tee "$tmpfile" \
  | tee -a "$RUN_LOG" \
  | jq --unbuffered -rj "$stream_text"

  result=$(jq -r "$final_result" "$tmpfile")

  if [[ "$result" == *"<promise>NO MORE TASKS</promise>"* ]]; then
    echo "Ralph complete after $i iterations."
    exit 0
  fi
done
