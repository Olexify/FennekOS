#!/usr/bin/env bash
# Verifies Universal Blue's cosign signature on the base image and prints "image@sha256:..." of exactly the
# digest that was signed (taken from the verified signature payload). Build FROM that, never the bare tag:
# a tampered or re-pointed tag fails here, before any build. Needs cosign + jq.
set -euo pipefail
tag=${1:-ghcr.io/ublue-os/kinoite-main:44}
key=$(dirname "$0")/keys/ublue-cosign.pub   # pinned copy of github.com/ublue-os/main/cosign.pub
out=$(cosign verify --key "$key" "$tag" 2>/dev/null) || { echo "BASE IMAGE SIGNATURE CHECK FAILED: $tag" >&2; exit 1; }
digest=$(jq -r '.[0].critical.image."docker-manifest-digest"' <<<"$out")
[[ $digest == sha256:* ]] || { echo "no signed digest for $tag" >&2; exit 1; }
echo "${tag%:*}@$digest"
