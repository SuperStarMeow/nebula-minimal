#!/usr/bin/env bash
# Tests for addon/scripts/select-nebula.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${here}/lib.sh"

selector="${here}/../addon/scripts/select-nebula.sh"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

mkdir -p "${workdir}/bundled"
printf '#!/bin/sh\n' > "${workdir}/bundled/nebula"
chmod +x "${workdir}/bundled/nebula"

cat > "${workdir}/installer" <<'EOF'
#!/bin/sh
echo "$1 $2" >> "${INSTALLER_CALLS}"
mkdir -p "$2"
printf '#!/bin/sh\n' > "$2/nebula"
chmod +x "$2/nebula"
EOF
chmod +x "${workdir}/installer"

export NEBULA_BUNDLED_VERSION="1.11.2"
export NEBULA_BUNDLED_BINARY="${workdir}/bundled/nebula"
export NEBULA_CACHE_DIR="${workdir}/cache"
export NEBULA_INSTALLER="${workdir}/installer"
export INSTALLER_CALLS="${workdir}/installer-calls"
: > "${INSTALLER_CALLS}"

assert_eq "${NEBULA_BUNDLED_BINARY}" "$("${selector}" latest)" "latest resolves to the bundled binary"
assert_eq "${NEBULA_BUNDLED_BINARY}" "$("${selector}")" "missing argument resolves to the bundled binary"
assert_eq "${NEBULA_BUNDLED_BINARY}" "$("${selector}" "")" "empty version resolves to the bundled binary"
assert_eq "${NEBULA_BUNDLED_BINARY}" "$("${selector}" "${NEBULA_BUNDLED_VERSION}")" "the bundled version resolves to the bundled binary"
assert_eq "" "$(cat "${INSTALLER_CALLS}")" "the bundled version does not download anything"

assert_eq "${workdir}/cache/1.10.3/nebula" "$("${selector}" 1.10.3)" "other versions are downloaded into the cache"
assert_eq "1.10.3 ${workdir}/cache/1.10.3" "$(cat "${INSTALLER_CALLS}")" "the installer receives version and destination"

assert_eq "${workdir}/cache/1.10.3/nebula" "$("${selector}" 1.10.3)" "cached versions are reused"
assert_eq "1" "$(wc -l < "${INSTALLER_CALLS}" | tr -d ' ')" "the installer runs only once per version"

assert_fails "rejects invalid version strings" "${selector}" "1.10.3; rm -rf /"
assert_fails "rejects path traversal" "${selector}" "../../etc"

finish
