#!/usr/bin/env bash
# Run every test in this directory.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

for test_script in "${here}"/test-*.sh; do
    printf '=== %s\n' "$(basename "${test_script}")"
    bash "${test_script}" || status=1
done

printf '=== test-config.py\n'
python3 "${here}/test-config.py" || status=1

exit "${status}"
