#!/bin/sh
set -eo pipefail

export TMP="$(jq --raw-output . "$GITHUB_EVENT_PATH")"
echo "$TMP"
