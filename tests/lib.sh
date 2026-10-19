#!/usr/bin/env bash
# Minimal assertion helpers for the shell test scripts.
set -euo pipefail

tests=0
failures=0

pass() {
    tests=$((tests + 1))
    printf 'ok - %s\n' "$1"
}

fail() {
    tests=$((tests + 1))
    failures=$((failures + 1))
    printf 'not ok - %s\n' "$1"
}

assert_eq() {
    local expected=$1 actual=$2 name=$3
    if [[ "${expected}" == "${actual}" ]]; then
        pass "${name}"
    else
        fail "${name} (expected '${expected}', got '${actual}')"
    fi
}

assert_contains() {
    local haystack=$1 needle=$2 name=$3
    if [[ "${haystack}" == *"${needle}"* ]]; then
        pass "${name}"
    else
        fail "${name} (expected '${needle}' in '${haystack}')"
    fi
}

assert_ok() {
    local name=$1
    shift
    local status=0
    "$@" >/dev/null 2>&1 || status=$?
    assert_eq "0" "${status}" "${name}"
}

assert_fails() {
    local name=$1
    shift
    local status=0
    "$@" >/dev/null 2>&1 || status=$?
    if [[ "${status}" -ne 0 ]]; then
        pass "${name}"
    else
        fail "${name} (command unexpectedly succeeded)"
    fi
}

finish() {
    printf '\n%d assertions, %d failed\n' "${tests}" "${failures}"
    [[ "${failures}" -eq 0 ]]
}
