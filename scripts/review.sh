#!/usr/bin/env bash
set -euo pipefail

API_KEY="$INPUT_API_KEY"
API_URL="$INPUT_API_URL"
WAIT="$INPUT_WAIT"
POST_COMMENT="$INPUT_POST_COMMENT"
TIMEOUT="$INPUT_TIMEOUT"

# Mask the API key in logs
echo "::add-mask::$API_KEY"

# --- Step 1: Build request payload ---

if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  echo "Running as manual dispatch"
  BRANCH="${GITHUB_HEAD_REF:-$GITHUB_REF_NAME}"
  PR_TITLE="Manual review: ${BRANCH}"
  PR_BODY="Manual code review triggered via workflow_dispatch"
  PR_NUMBER=0
  HEAD_SHA="$GITHUB_SHA"
  HEAD_REF="$BRANCH"
  BASE_SHA=""
  BASE_REF="${GITHUB_BASE_REF:-main}"
  ACTION="manual"
  CLONE_URL="https://github.com/${REPO_NAME}.git"
  DEFAULT_BRANCH="${GITHUB_BASE_REF:-main}"
else
  echo "Running as ${EVENT_NAME} event"

  PR_TITLE=$(jq -r '.pull_request.title // ""' "$GITHUB_EVENT_PATH")
  PR_BODY=$(jq -r '.pull_request.body // ""' "$GITHUB_EVENT_PATH")
  PR_NUMBER=$(jq -r '.pull_request.number // 0' "$GITHUB_EVENT_PATH")
  HEAD_SHA=$(jq -r '.pull_request.head.sha // ""' "$GITHUB_EVENT_PATH")
  HEAD_REF=$(jq -r '.pull_request.head.ref // ""' "$GITHUB_EVENT_PATH")
  BASE_SHA=$(jq -r '.pull_request.base.sha // ""' "$GITHUB_EVENT_PATH")
  BASE_REF=$(jq -r '.pull_request.base.ref // ""' "$GITHUB_EVENT_PATH")
  ACTION=$(jq -r '.action // ""' "$GITHUB_EVENT_PATH")
  CLONE_URL=$(jq -r '.repository.clone_url // ""' "$GITHUB_EVENT_PATH")
  DEFAULT_BRANCH=$(jq -r '.repository.default_branch // "main"' "$GITHUB_EVENT_PATH")
fi

PR_DATA=$(jq -n \
  --arg repo_name "$REPO_NAME" \
  --arg clone_url "$CLONE_URL" \
  --arg default_branch "$DEFAULT_BRANCH" \
  --argjson pr_number "$PR_NUMBER" \
  --arg pr_title "$PR_TITLE" \
  --arg pr_body "$PR_BODY" \
  --arg head_sha "$HEAD_SHA" \
  --arg head_ref "$HEAD_REF" \
  --arg base_sha "$BASE_SHA" \
  --arg base_ref "$BASE_REF" \
  --arg action "$ACTION" \
  --arg api_key "$API_KEY" \
  '{
    repository: {
      full_name: $repo_name,
      clone_url: $clone_url,
      default_branch: $default_branch
    },
    pull_request: {
      number: $pr_number,
      title: $pr_title,
      body: $pr_body,
      head: { sha: $head_sha, ref: $head_ref },
      base: { sha: $base_sha, ref: $base_ref }
    },
    action: $action,
    api_key: $api_key
  }')

# --- Step 2: Send review request ---

echo "Sending review request to ${API_URL}/v1/webhooks/github"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "$PR_DATA" \
  "${API_URL}/v1/webhooks/github")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 1)

echo "HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" -ge 400 ]; then
  echo "::error::CodeCritic API returned error $HTTP_STATUS: $HTTP_BODY"
  exit 1
fi

JOB_ID=$(echo "$HTTP_BODY" | jq -r '.job_id // empty')
if [ -z "$JOB_ID" ] || [ "$JOB_ID" = "null" ]; then
  echo "::error::No review ID received from CodeCritic"
  exit 1
fi

echo "review_id=$JOB_ID" >> "$GITHUB_OUTPUT"
echo "Review created: $JOB_ID"

# --- Step 3: Wait for completion ---

if [ "$WAIT" != "true" ]; then
  echo "Skipping wait (wait_for_completion=false)"
  exit 0
fi

INTERVAL=10
ELAPSED=0

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  RESPONSE=$(curl -s "${API_URL}/v1/webhooks/status?job_id=$JOB_ID")
  STATUS=$(echo "$RESPONSE" | jq -r '.status // "unknown"')
  PROGRESS=$(echo "$RESPONSE" | jq -r '.progress // 0')

  if [ "$STATUS" = "completed" ]; then
    echo "Review completed!"
    break
  elif [ "$STATUS" = "failed" ]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error_message // "Unknown error"')
    echo "::error::Review failed: $ERROR_MSG"
    exit 1
  fi

  echo "Status: $STATUS ($PROGRESS%) - ${ELAPSED}s / ${TIMEOUT}s"
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ "$STATUS" != "completed" ]; then
  echo "::warning::Review did not complete within ${TIMEOUT}s timeout"
  exit 0
fi

# --- Step 4: Fetch results and post ---

REVIEW_DATA=$(curl -s "${API_URL}/v1/webhooks/results?job_id=$JOB_ID")
SUMMARY=$(echo "$REVIEW_DATA" | jq -r '.review.summary // "No summary available"')
SCORE=$(echo "$REVIEW_DATA" | jq -r '.review.score // "N/A"')

echo "score=$SCORE" >> "$GITHUB_OUTPUT"

# Write GitHub Step Summary
{
  echo "## CodeCritic Review Results"
  echo ""
  echo "**Score:** ${SCORE}/100"
  echo ""
  echo "**Summary:**"
  echo "$SUMMARY"
  echo ""
  echo "---"
  echo "*AI-generated review by [CodeCritic](https://code-critic.com). Results may contain inaccuracies — verify before applying.*"
} >> "$GITHUB_STEP_SUMMARY"

# Post PR comment
if [ "$POST_COMMENT" = "true" ] && [ "$EVENT_NAME" = "pull_request" ] && [ -n "$SUMMARY" ] && [ "$SUMMARY" != "No summary available" ] && [ "$SUMMARY" != "null" ]; then
  PR_NUM=$(jq -r '.pull_request.number' "$GITHUB_EVENT_PATH")
  COMMENT_BODY=$(jq -n \
    --arg score "$SCORE" \
    --arg summary "$SUMMARY" \
    '{body: "## CodeCritic Review\n\n**Score:** \($score)/100\n\n**Summary:**\n\($summary)\n\n---\n*AI-generated code review by [CodeCritic](https://code-critic.com). Results may contain inaccuracies — always verify suggestions before applying. [Report an issue](https://github.com/CodeCritic-Reviews/review-action/issues) | [Terms](https://code-critic.com/terms) | [Privacy](https://code-critic.com/privacy)*"}')

  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$COMMENT_BODY" \
    "https://api.github.com/repos/${REPO_NAME}/issues/${PR_NUM}/comments"

  echo "Posted review comment to PR #${PR_NUM}"
elif [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  echo "Manual dispatch -- results available in Step Summary"
fi
