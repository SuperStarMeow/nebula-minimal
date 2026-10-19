#!/usr/bin/env bash
# Print the Nebula binary that should be used for the requested version.
#
# The version bundled in the image is used as-is. Any other version is
# downloaded once into the persistent /data volume and reused afterwards.
set -euo pipefail

readonly bundled_version="${NEBULA_BUNDLED_VERSION:?NEBULA_BUNDLED_VERSION is not set}"
readonly bundled_binary="${NEBULA_BUNDLED_BINARY:-/usr/local/bin/nebula}"
readonly cache_dir="${NEBULA_CACHE_DIR:-/data/nebula}"
readonly installer="${NEBULA_INSTALLER:-/usr/local/bin/install-nebula.sh}"

requested_version="${1:-latest}"

if [[ -z "${requested_version}" || "${requested_version}" == "latest" || "${requested_version}" == "${bundled_version}" ]]; then
    echo "${bundled_binary}"
    exit 0
fi

if [[ ! "${requested_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid Nebula version: '${requested_version}'" >&2
    exit 1
fi

binary="${cache_dir}/${requested_version}/nebula"
if [[ ! -x "${binary}" ]]; then
    echo "Nebula ${requested_version} is not cached yet, downloading it..." >&2
    "${installer}" "${requested_version}" "$(dirname "${binary}")"
fi

echo "${binary}"
