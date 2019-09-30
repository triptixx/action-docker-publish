#!/bin/sh
set -eo pipefail

#source tags.sh

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

USERNAME="${DOCKER_USERNAME:-${INPUT_DOCKER_USERNAME}}"
PASSWORD="${DOCKER_PASSWORD:-${INPUT_DOCKER_PASSWORD}}"

if [ -z "${USERNAME}" ]; then
    error "Missing required docker 'username' for pushing"
elif [ -z "${PASSWORD}" ]; then
    error "Missing required docker 'username' for pushing"
fi

# If no PLUGIN_FROM specifed, assume PLUGIN_REPO instead
export SRC_REPO="${INPUT_FROM:-${INPUT_REPO}}"
