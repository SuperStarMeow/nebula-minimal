#!/usr/bin/env python3
"""Validate the app configuration and the Nebula versions it advertises."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "addon" / "config.yaml"
DOCKERFILE = ROOT / "addon" / "Dockerfile"
RUN_SCRIPT = ROOT / "addon" / "run.sh"

SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
# Mirrors supervisor/apps/options.py:RE_SCHEMA_ELEMENT.
SCHEMA_ELEMENT = re.compile(
    r"^(?:"
    r"bool|email|url|port|device(?:\(subsystem=[a-z]+\))?|"
    r"str(?:\(\d*,\d*\))?|password(?:\(\d*,\d*\))?|"
    r"int(?:\(-?\d*,-?\d*\))?|float(?:\(-?\d*\.?\d+,-?\d*\.?\d+\))?|"
    r"match\(.*\)|list\(.+\)"
    r")\??$"
)
HOME_ASSISTANT_ARCHITECTURES = {"aarch64", "amd64", "armhf", "armv7", "i386"}

errors: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def validate_config(config: dict) -> list[str]:
    for key in (
        "name",
        "description",
        "version",
        "slug",
        "arch",
        "boot",
        "map",
        "host_network",
        "privileged",
        "options",
        "schema",
    ):
        check(key in config, f"addon/config.yaml is missing the '{key}' key")

    check(
        bool(SEMVER.match(str(config.get("version", "")))),
        f"addon version '{config.get('version')}' is not a semantic version",
    )
    check(
        set(config.get("arch", [])) <= HOME_ASSISTANT_ARCHITECTURES,
        f"unsupported architecture in {config.get('arch')}",
    )
    check(
        "addon_config:rw" in config.get("map", []),
        "the addon_config mapping is required, run.sh writes to /config",
    )

    options = config.get("options", {})
    schema = config.get("schema", {})
    check(
        set(options) == set(schema),
        f"options {sorted(options)} and schema {sorted(schema)} define different keys",
    )
    for name, definition in schema.items():
        check(
            bool(SCHEMA_ELEMENT.match(str(definition))),
            f"schema definition for '{name}' is not valid: {definition}",
        )
        check(name in options, f"schema key '{name}' has no default in options")

    check(
        options.get("nebula_version") == "latest",
        "nebula_version must default to 'latest'",
    )
    match = re.fullmatch(r"list\((.*)\)", str(schema.get("nebula_version", "")))
    if not match:
        return []

    entries = match.group(1).split("|")
    check(entries[0] == "latest", "the version list must start with 'latest'")
    versions = entries[1:]
    check(len(versions) > 0, "the version list must contain at least one release")
    check(len(set(entries)) == len(entries), "the version list contains duplicates")
    check(
        all(SEMVER.match(version) for version in versions),
        f"the version list contains invalid versions: {versions}",
    )
    check(
        versions == sorted(versions, key=version_key, reverse=True),
        "the version list must be sorted newest first",
    )
    check(
        options.get("nebula_version") in entries,
        "the nebula_version default is not part of the version list",
    )
    return versions


def validate_dockerfile(versions: list[str]) -> None:
    dockerfile = DOCKERFILE.read_text(encoding="utf-8")
    match = re.search(r"^ARG NEBULA_VERSION=(\S+)$", dockerfile, re.MULTILINE)
    check(match is not None, "addon/Dockerfile must define ARG NEBULA_VERSION")
    if match and versions:
        check(
            match.group(1) == versions[0],
            f"the bundled version '{match.group(1)}' is not the newest listed version '{versions[0]}'",
        )
        check(
            f"ENV NEBULA_BUNDLED_VERSION=${{NEBULA_VERSION}}" in dockerfile,
            "addon/Dockerfile must export NEBULA_BUNDLED_VERSION for select-nebula.sh",
        )


def validate_run_script() -> None:
    run_script = RUN_SCRIPT.read_text(encoding="utf-8")
    check(
        "bashio::config 'nebula_version'" in run_script,
        "addon/run.sh must read the nebula_version option",
    )
    check(
        "select-nebula.sh" in run_script,
        "addon/run.sh must resolve the binary through select-nebula.sh",
    )


def validate_automation_files() -> None:
    for workflow in sorted((ROOT / ".github" / "workflows").glob("*.yml")):
        try:
            yaml.safe_load(workflow.read_text(encoding="utf-8"))
        except yaml.YAMLError as error:
            errors.append(f"{workflow.relative_to(ROOT)} is not valid YAML: {error}")

    for name in ("release-please-config.json", ".release-please-manifest.json"):
        path = ROOT / name
        if not path.exists():
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"{name} is not valid JSON: {error}")


def main() -> int:
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    if not isinstance(config, dict):
        print("addon/config.yaml must be a YAML mapping", file=sys.stderr)
        return 1

    versions = validate_config(config)
    validate_dockerfile(versions)
    validate_run_script()
    validate_automation_files()

    if errors:
        print("Configuration validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"addon/config.yaml is valid ({len(versions)} Nebula versions listed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
