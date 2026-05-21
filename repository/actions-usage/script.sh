#!/bin/bash

set -euo pipefail

# gh CLI uses GH_TOKEN or GITHUB_TOKEN
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

ORG="${1}"
REPOS_FILE="${2}"
SINCE=$(date -u -d "90 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-90d +%Y-%m-%dT%H:%M:%SZ)

mkdir -p ../../reports

REPOS=$(jq -r '.[].nameWithOwner' "$REPOS_FILE")

if [ -z "$REPOS" ]; then
  echo "No repositories found."
  echo "[]" > ../../reports/actions-usage.json
  echo "repo,workflow_count,total_runs,success,failure,cancelled,skipped,total_duration_minutes,artifacts_size_mb,cache_size_mb,runner_types" > ../../reports/actions-usage.csv
  exit 0
fi

REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')
echo "Found $REPO_COUNT repositories"

# Initialize output files
echo "[" > ../../reports/actions-usage.json
echo "repo,workflow_count,total_runs,success,failure,cancelled,skipped,total_duration_minutes,artifacts_size_mb,cache_size_mb,runner_types" > ../../reports/actions-usage.csv

FIRST=true

while IFS= read -r REPO; do
  echo "Processing: $REPO"

  # Workflow count
  WORKFLOW_COUNT=$(gh api "/repos/${REPO}/actions/workflows" --jq '.total_count' 2>/dev/null || echo "0")

  # Workflow runs (last 90 days)
  RUNS_DATA=$(gh api --paginate "/repos/${REPO}/actions/runs?created=>=${SINCE}" --jq '.workflow_runs[] | {status: .status, conclusion: .conclusion, started: .run_started_at, updated: .updated_at}' 2>/dev/null || echo "")

  TOTAL_RUNS=0
  SUCCESS=0
  FAILURE=0
  CANCELLED=0
  SKIPPED=0
  TOTAL_DURATION_SEC=0

  if [ -n "$RUNS_DATA" ]; then
    TOTAL_RUNS=$(echo "$RUNS_DATA" | jq -s 'length')
    SUCCESS=$(echo "$RUNS_DATA" | jq -s '[.[] | select(.conclusion == "success")] | length')
    FAILURE=$(echo "$RUNS_DATA" | jq -s '[.[] | select(.conclusion == "failure")] | length')
    CANCELLED=$(echo "$RUNS_DATA" | jq -s '[.[] | select(.conclusion == "cancelled")] | length')
    SKIPPED=$(echo "$RUNS_DATA" | jq -s '[.[] | select(.conclusion == "skipped")] | length')

    TOTAL_DURATION_SEC=$(echo "$RUNS_DATA" | jq -s '
      [.[] | select(.started != null and .updated != null) |
        (((.updated | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) -
          (.started | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime)))] |
      add // 0
    ')
  fi

  TOTAL_DURATION_MIN=$(echo "scale=2; ${TOTAL_DURATION_SEC} / 60" | bc)

  # Artifacts size
  ARTIFACTS_SIZE_BYTES=$(gh api --paginate "/repos/${REPO}/actions/artifacts" --jq '[.artifacts[].size_in_bytes] | add // 0' 2>/dev/null || echo "0")
  ARTIFACTS_SIZE_MB=$(echo "scale=2; ${ARTIFACTS_SIZE_BYTES} / 1048576" | bc)

  # Cache usage
  CACHE_SIZE_BYTES=$(gh api "/repos/${REPO}/actions/cache/usage" --jq '.active_caches_size_in_bytes // 0' 2>/dev/null || echo "0")
  CACHE_SIZE_MB=$(echo "scale=2; ${CACHE_SIZE_BYTES} / 1048576" | bc)

  # Runner types (sampled from most recent run per workflow)
  RUNNER_TYPES=""
  if [ "$WORKFLOW_COUNT" -gt 0 ] 2>/dev/null; then
    WORKFLOW_IDS=$(gh api "/repos/${REPO}/actions/workflows" --jq '.workflows[].id' 2>/dev/null || echo "")
    RUNNERS=""
    while IFS= read -r WF_ID; do
      [ -z "$WF_ID" ] && continue
      LATEST_RUN_ID=$(gh api "/repos/${REPO}/actions/workflows/${WF_ID}/runs?per_page=1" --jq '.workflow_runs[0].id // empty' 2>/dev/null || echo "")
      if [ -n "$LATEST_RUN_ID" ]; then
        RUN_RUNNERS=$(gh api "/repos/${REPO}/actions/runs/${LATEST_RUN_ID}/jobs" --jq '[.jobs[].labels[]] | unique | join(",")' 2>/dev/null || echo "")
        if [ -n "$RUN_RUNNERS" ]; then
          RUNNERS="${RUNNERS},${RUN_RUNNERS}"
        fi
      fi
    done <<< "$WORKFLOW_IDS"
    RUNNER_TYPES=$(echo "$RUNNERS" | tr ',' '\n' | sort -u | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
  fi

  # Short repo name
  REPO_SHORT="${REPO#*/}"

  # Append to CSV
  echo "\"${REPO_SHORT}\",${WORKFLOW_COUNT},${TOTAL_RUNS},${SUCCESS},${FAILURE},${CANCELLED},${SKIPPED},${TOTAL_DURATION_MIN},${ARTIFACTS_SIZE_MB},${CACHE_SIZE_MB},\"${RUNNER_TYPES}\"" >> ../../reports/actions-usage.csv

  # Append to JSON
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> ../../reports/actions-usage.json
  fi
  cat >> ../../reports/actions-usage.json <<EOF
  {
    "repo": "${REPO_SHORT}",
    "workflow_count": ${WORKFLOW_COUNT},
    "total_runs": ${TOTAL_RUNS},
    "success": ${SUCCESS},
    "failure": ${FAILURE},
    "cancelled": ${CANCELLED},
    "skipped": ${SKIPPED},
    "total_duration_minutes": ${TOTAL_DURATION_MIN},
    "artifacts_size_mb": ${ARTIFACTS_SIZE_MB},
    "cache_size_mb": ${CACHE_SIZE_MB},
    "runner_types": "${RUNNER_TYPES}"
  }
EOF

  sleep 1

done <<< "$REPOS"

echo "]" >> ../../reports/actions-usage.json

echo "Audit complete. Processed $REPO_COUNT repositories."
