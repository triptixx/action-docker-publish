#!/bin/sh
set -eo pipefail

source tags.sh

# $INPUT_TEST  Running in tags test mode

if [ -n "$INPUT_TEST" ]; then
    >&2 echo -e 'Running in tags test mode'
    shift
    printf '%s\n' "$@" | parse_tags | xargs -n 1 | sort -u
    exit 0
fi

if echo "$(jq --raw-output .head_commit.message "$GITHUB_EVENT_PATH")" | grep -qiF -e '[PUBLISH SKIP]' -e '[SKIP PUBLISH]'; then
    >&2 echo -e 'Skipping publish'
    exit 0
fi

# $INPUT_FROM  re-tag from this repo
# $INPUT_REPO  tag to this repo/repo to push to
# $INPUT_TAGS  newline or comma separated list of tags to push images with

USERNAME="${INPUT_DOCKER_USERNAME}"
PASSWORD="${INPUT_DOCKER_PASSWORD}"

if [ -z "${USERNAME}" ]; then
    error "Missing required docker 'username' for pushing"
elif [ -z "${PASSWORD}" ]; then
    error "Missing required docker 'password' for pushing"
fi

if [ -z "${INPUT_REPO}" ]; then
    error "Missing 'repo' argument required for publishing"
fi

# If no INPUT_FROM specifed, assume INPUT_REPO instead
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
    docker image tag "${SRC_REPO}" "${INPUT_REPO}:$tag"
    
    # Push tagged images
    printf "Pushing tag '%s'...\n" $tag
    docker image push "${INPUT_REPO}:$tag"
    printf '\n'
    
    # Remove tagged images
    docker image rm "${INPUT_REPO}:$tag" >/dev/null 2>/dev/null || true
done
docker image rm "${SRC_REPO}" >/dev/null 2>/dev/null || true

printf '%s... ' "Updating Microbadger metadata for ${INPUT_REPO%:*}"
WEBHOOK_URL="$(curl -sS https://api.microbadger.com/v1/images/${INPUT_REPO%:*} | jq -r .WebhookURL)" && \
curl -sS -X POST "$WEBHOOK_URL" || true
