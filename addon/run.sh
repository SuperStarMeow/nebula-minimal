#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

# create a file to create a config directory if it doesn't exist
touch /config/.tmp

NEBULA_VERSION="$(bashio::config 'nebula_version' 'latest')"
NEBULA_BIN="$(select-nebula.sh "${NEBULA_VERSION}")"

echo "Nebula $("${NEBULA_BIN}" -version)"

"${NEBULA_BIN}" -test -config /config/nebula0.yaml

exec "${NEBULA_BIN}" -config /config/nebula0.yaml
