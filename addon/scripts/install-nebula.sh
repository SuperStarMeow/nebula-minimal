#!/usr/bin/env bash
# Download a Nebula release for this machine's architecture, verify its
# checksum and unpack it into the given directory.
set -euo pipefail

readonly DOWNLOAD_BASE="${NEBULA_DOWNLOAD_BASE:-https://github.com/slackhq/nebula/releases/download}"

version="${1:-}"
destination="${2:-}"

if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid Nebula version: '${version}'" >&2
    exit 1
fi

if [[ -z "${destination}" ]]; then
    echo "Usage: install-nebula.sh <version> <destination-directory>" >&2
    exit 1
fi

arch="${NEBULA_ARCH:-$(apk --print-arch)}"
case "${arch}" in
    x86_64 | amd64) asset_arch="amd64" ;;
    aarch64 | arm64) asset_arch="arm64" ;;
    armv7) asset_arch="arm-7" ;;
    armhf) asset_arch="arm-6" ;;
    x86 | i386) asset_arch="386" ;;
    *)
        echo "Unsupported architecture: '${arch}'" >&2
        exit 1
        ;;
esac

asset="nebula-linux-${asset_arch}.tar.gz"
release_url="${DOWNLOAD_BASE}/v${version}"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

curl -fsSL -o "${workdir}/${asset}" "${release_url}/${asset}"
curl -fsSL -o "${workdir}/SHASUM256.txt" "${release_url}/SHASUM256.txt"

expected="$(awk -v asset="${asset}" '$2 == asset { print $1 }' "${workdir}/SHASUM256.txt")"
if [[ -z "${expected}" ]]; then
    echo "No checksum found for ${asset} in SHASUM256.txt" >&2
    exit 1
fi

actual="$(sha256sum "${workdir}/${asset}" | cut -d' ' -f1)"
if [[ "${expected}" != "${actual}" ]]; then
    echo "Checksum mismatch for ${asset}: expected ${expected}, got ${actual}" >&2
    exit 1
fi

mkdir -p "${destination}"
tar -xzf "${workdir}/${asset}" -C "${destination}" nebula nebula-cert
chmod 0755 "${destination}/nebula" "${destination}/nebula-cert"
