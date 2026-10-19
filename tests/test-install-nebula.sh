#!/usr/bin/env bash
# Tests for addon/scripts/install-nebula.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${here}/lib.sh"

installer="${here}/../addon/scripts/install-nebula.sh"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# Creates a fake release with an executable "nebula" that prints version/arch.
make_release() {
    local version=$1 asset_arch=$2
    local stage="${workdir}/stage-${asset_arch}"
    local release="${workdir}/releases/v${version}"
    mkdir -p "${stage}" "${release}"

    printf '#!/bin/sh\necho "nebula %s %s"\n' "${version}" "${asset_arch}" > "${stage}/nebula"
    printf '#!/bin/sh\necho "nebula-cert %s"\n' "${version}" > "${stage}/nebula-cert"
    chmod +x "${stage}/nebula" "${stage}/nebula-cert"

    tar -czf "${release}/nebula-linux-${asset_arch}.tar.gz" -C "${stage}" nebula nebula-cert
    (cd "${release}" && sha256sum "nebula-linux-${asset_arch}.tar.gz" > SHASUM256.txt)
}

install_version() { # apk-arch version destination
    NEBULA_ARCH="$1" NEBULA_DOWNLOAD_BASE="file://${workdir}/releases" \
        "${installer}" "$2" "$3"
}

make_release 1.2.3 amd64

assert_ok "installs a release for x86_64" \
    install_version x86_64 1.2.3 "${workdir}/dest"
assert_eq "nebula 1.2.3 amd64" "$("${workdir}/dest/nebula")" "unpacks the requested binary"
assert_ok "installs nebula-cert" test -x "${workdir}/dest/nebula-cert"

for mapping in "aarch64:arm64" "armv7:arm-7" "armhf:arm-6" "x86:386"; do
    source_arch="${mapping%%:*}"
    asset_arch="${mapping##*:}"
    make_release 1.2.3 "${asset_arch}"
    assert_ok "maps ${source_arch} to nebula-linux-${asset_arch}" \
        install_version "${source_arch}" 1.2.3 "${workdir}/dest-${asset_arch}"
done
assert_eq "nebula 1.2.3 arm64" "$("${workdir}/dest-arm64/nebula")" "installs arm64 assets"

assert_fails "rejects an empty version" \
    install_version x86_64 "" "${workdir}/dest-empty"
assert_fails "rejects a version without patch level" \
    install_version x86_64 1.2 "${workdir}/dest-short"
assert_fails "rejects a prefixed version" \
    install_version x86_64 v1.2.3 "${workdir}/dest-prefixed"
assert_fails "rejects path traversal in the version" \
    install_version x86_64 "../../etc" "${workdir}/dest-escape"
assert_fails "rejects a missing destination" \
    install_version x86_64 1.2.3 ""
assert_fails "rejects an unsupported architecture" \
    install_version riscv64 1.2.3 "${workdir}/dest-riscv"

printf '%s  nebula-linux-amd64.tar.gz\n' \
    "$(printf 'corrupted' | sha256sum | cut -d' ' -f1)" > "${workdir}/releases/v1.2.3/SHASUM256.txt"
assert_fails "rejects a checksum mismatch" \
    install_version x86_64 1.2.3 "${workdir}/dest-corrupt"
assert_fails "does not install a binary on checksum mismatch" \
    test -e "${workdir}/dest-corrupt/nebula"

: > "${workdir}/releases/v1.2.3/SHASUM256.txt"
assert_fails "rejects a release without a checksum for the asset" \
    install_version x86_64 1.2.3 "${workdir}/dest-nosum"

finish
