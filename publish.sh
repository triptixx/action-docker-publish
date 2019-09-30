#!/bin/sh
set -eo pipefail

#source tags.sh

if [ "$1" = '--tags' ]; then
    >&2 echo -e 'Running in --tags test mode'
    shift
    printf '%s\n' "$@" | parse_tags | xargs -n 1 | sort -u
    exit 0
fi

echo "$(jq --raw-output .head_commit.message "$GITHUB_EVENT_PATH")"

if echo "$(jq --raw-output .head_commit.message "$GITHUB_EVENT_PATH")" | grep -qiF -e '[PUBLISH SKIP]' -e '[SKIP PUBLISH]'; then
    >&2 echo -e 'Skipping publish'
    exit 0
fi
