#!/usr/bin/with-contenv bashio

# create a file to create a config directory if it doesn't exist
touch /config/.tmp

echo "Nebula $(nebula --version)"

nebula -test -config /config/nebula0.yaml

nebula -config /config/nebula0.yaml
