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

# Make sure we fetch the latest changes before calculating diffs
git fetch origin

if [[ "$EVENT_NAME" == "push" ]]; then
  echo "Push event detected"
  echo "Comparing $GITHUB_EVENT_BEFORE -> $COMMIT"
  
  # Ensure we get the diff for all changed files in the push
  CHANGED_FILES=$(git diff --name-only "$GITHUB_EVENT_BEFORE" "$COMMIT")
  
  echo "Changed files:"
  echo "$CHANGED_FILES"
  
  # Get the number of changed files
  COUNT=$(echo "$CHANGED_FILES" | wc -l)

elif [[ "$EVENT_NAME" == "pull_request" ]]; then
  echo "Pull request event detected"
  PR_FILE="$GITHUB_EVENT_PATH"
  PR_NUMBER=$(jq --raw-output .number "$PR_FILE")
  PR_MERGED=$(jq --raw-output .pull_request.merged "$PR_FILE")

  if [[ "$PR_MERGED" == "true" ]]; then
    echo "PR #$PR_NUMBER was merged"

    API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER/files")

    COUNT=$(echo "$API_RESPONSE" | jq length)
  else
    echo "PR not merged. Skipping."
    exit 0
  fi

else
  echo "Unsupported event: $EVENT_NAME"
  exit 1
fi

echo "Found $COUNT changed files"

echo "Sending payload to webhook..."
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"repo\": \"$REPO\", \"commit\": \"$COMMIT\", \"changed_files_count\": \"$COUNT\"}"

curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"repo\": \"$REPO\", \"commit\": \"$COMMIT\", \"changed_files_count\": \"$COUNT\"}"


