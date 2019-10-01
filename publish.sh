#!/bin/sh
set -eo pipefail

source tags.sh

if [ "$1" = '--tags' ]; then
  >&2 echo -e 'Running in --tags test mode'
  shift
  printf '%s\n' "$@" | parse_tags | xargs -n 1 | sort -u
  exit 0
fi

if echo "$(jq --raw-output .head_commit.message "$GITHUB_EVENT_PATH")" | grep -qiF -e '[PUBLISH SKIP]' -e '[SKIP PUBLISH]'; then
  >&2 echo -e 'Skipping publish'
  exit 0
fi

# $PLUGIN_FROM  re-tag from this repo
# $PLUGIN_REPO  tag to this repo/repo to push to
# $PLUGIN_TAGS  newline or comma separated list of tags to push images with

USERNAME="${INPUT_DOCKER_USERNAME}"
PASSWORD="${INPUT_DOCKER_PASSWORD}"

if [ -z "${USERNAME}" ]; then
  error "Missing required docker 'username' for pushing"
elif [ -z "${PASSWORD}" ]; then
  error "Missing required docker 'username' for pushing"
fi

if [ -z "${INPUT_REPO}" ]; then
  error "Missing 'repo' argument required for publishing"
fi

# If no PLUGIN_FROM specifed, assume PLUGIN_REPO instead
export SRC_REPO="${INPUT_FROM:-${INPUT_REPO}}"

# Log in to the specified Docker registry (or the default if not specified)
echo -n "${PASSWORD}" | \
    docker login \
        --password-stdin \
        --username "${USERNAME}" \
        "${INPUT_REGISTRY}"

# Ensure at least one tag exists
if [ -z "${INPUT_TAGS}" ]; then
  # Take into account the case where the repo already has the tag appended
  if echo "${INPUT_REPO}" | grep -q ':'; then
    TAGS="${INPUT_REPO#*:}"
    INPUT_REPO="${INPUT_REPO%:*}"
  else
    # If none specified, assume 'latest'
    TAGS='latest'
  fi
else
  # Parse and process dynamic tags
  TAGS="$(echo "${INPUT_TAGS}" | tr ',' '\n' | parse_tags | xargs -n 1 | sort -u | xargs)"
fi

for tag in $TAGS; do
  # Tag images
  docker tag "${SRC_REPO}" "${INPUT_REPO}:$tag"
  
  # Push tagged images
  printf "Pushing tag '%s'...\n" $tag
  #docker push "${INPUT_REPO}:$tag"
  printf '\n'
  
  # Remove tagged images
  docker rmi "${INPUT_REPO}:$tag" >/dev/null 2>/dev/null || true
done
docker rmi "${SRC_REPO}" >/dev/null 2>/dev/null || true

# if [ -n "$MICROBADGER_TOKEN" ]; then
#     >&2 echo 'Legacy $MICROBADGER_TOKEN provided, you can remove this'
# fi

# printf '%s... ' "Updating Microbadger metadata for ${PLUGIN_REPO%:*}"
# WEBHOOK_URL="$(curl -sS https://api.microbadger.com/v1/images/${PLUGIN_REPO%:*} | jq -r .WebhookURL)" && \
# curl -sS -X POST "$WEBHOOK_URL" || true
