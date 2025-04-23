# #!/bin/bash

# API_URL=$1

# echo "Detecting changes..."

# if [[ "$GITHUB_EVENT_NAME" == "push" ]]; then
#   git fetch origin "$GITHUB_EVENT_BEFORE"
#   CHANGED_FILES=$(git diff --name-only "$GITHUB_EVENT_BEFORE" "$GITHUB_SHA")
# elif [[ "${{ github.event.pull_request.merged }}" == "true" ]]; then
#   CHANGED_FILES=$(git diff --name-only origin/main HEAD)
# else
#   echo "Unsupported event"
#   exit 1
# fi

# COUNT=$(echo "$CHANGED_FILES" | wc -l)
# echo "Found $COUNT changed files"

# # Send to Webhook
# echo "Sending payload to webhook..."
# curl -X POST "$API_URL" \
# -H "Content-Type: application/json" \
# -d "{\"repo\": \"$GITHUB_REPOSITORY\", \"commit\": \"$GITHUB_SHA\", \"changed_files_count\": \"$COUNT\"}"

#!/bin/bash

API_URL=$1

echo "Detecting changes..."

EVENT_NAME="${GITHUB_EVENT_NAME}"
REPO="${GITHUB_REPOSITORY}"
COMMIT="${GITHUB_SHA}"
COUNT=0

if [[ "$EVENT_NAME" == "push" ]]; then
  echo "Push event detected"
  git fetch origin "$GITHUB_EVENT_BEFORE"
  CHANGED_FILES=$(git diff --name-only "$GITHUB_EVENT_BEFORE" "$COMMIT")

elif [[ "$EVENT_NAME" == "pull_request" ]]; then
  echo "Pull request event detected"
  PR_FILE="$GITHUB_EVENT_PATH"
  PR_MERGED=$(jq --raw-output .pull_request.merged "$PR_FILE")

  if [[ "$PR_MERGED" == "true" ]]; then
    echo "PR was merged"
    git fetch origin main
    CHANGED_FILES=$(git diff --name-only origin/main HEAD)
  else
    echo "PR not merged. Skipping."
    exit 0
  fi

else
  echo "Unsupported event: $EVENT_NAME"
  exit 1
fi

COUNT=$(echo "$CHANGED_FILES" | wc -l)
echo "Found $COUNT changed files"

echo "Sending payload to webhook..."
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"repo\": \"$REPO\", \"commit\": \"$COMMIT\", \"changed_files_count\": \"$COUNT\"}"


