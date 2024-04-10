#!/bin/sh
set -ex
rm -rf /tmp/roskakori.at/
poetry run lektor build --output-path /tmp/roskakori.at/
set +x
echo "INFO The built files are located in /tmp/roskakori.at/."
