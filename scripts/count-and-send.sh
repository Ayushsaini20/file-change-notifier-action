#!/bin/bash

API_URL=$1

echo "🔍 Detecting changes..."

if [[ "$GITHUB_EVENT_NAME" == "push" ]]; then
  git fetch origin "$GITHUB_EVENT_BEFORE"
  CHANGED_FILES=$(git diff --name-only "$GITHUB_EVENT_BEFORE" "$GITHUB_SHA")
elif [[ "${{ github.event.pull_request.merged }}" == "true" ]]; then
  CHANGED_FILES=$(git diff --name-only origin/main HEAD)
else
  echo "❌ Unsupported event"
  exit 1
fi

COUNT=$(echo "$CHANGED_FILES" | wc -l)
echo "✅ Found $COUNT changed files"

# Send to Webhook
echo "📡 Sending payload to webhook..."
curl -X POST "$API_URL" \
-H "Content-Type: application/json" \
-d "{\"repo\": \"$GITHUB_REPOSITORY\", \"commit\": \"$GITHUB_SHA\", \"changed_files_count\": \"$COUNT\"}"
