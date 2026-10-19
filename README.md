# Nebula Minimal

A minimal [Home Assistant app](https://developers.home-assistant.io/docs/apps/)
(add-on) that runs a single [Nebula](https://github.com/slackhq/nebula) VPN node.

## Installation

1. In Home Assistant open **Settings → Add-ons → Add-on store**.
2. Use the ⋮ menu → **Repositories** and add
   `https://github.com/SuperStarMeow/nebula-minimal`.
3. Install **Nebula Minimal**.
4. Place your `nebula0.yaml` in the app's configuration folder (`/config` inside
   the container, also reachable through the **Nebula Minimal** app options).

## Configuration

| Option           | Type   | Default  | Description                                                                                                                                        |
| ---------------- | ------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nebula_version` | list   | `latest` | Nebula release to run. `latest` uses the version bundled in the app image, other versions are downloaded from the official GitHub release on first start. |

### Choosing a Nebula version

The app image bundles one Nebula release (the newest entry in the
`nebula_version` list). Selecting `latest` runs that bundled binary, so the app
starts without network access.

Selecting any other version downloads that release from
[slackhq/nebula releases](https://github.com/slackhq/nebula/releases) the first
time the app starts with that selection. Downloads are checksum-verified and
cached in the app's private `/data` volume, so later starts work offline. The
`nebula-cert` binary of the selected version is installed next to `nebula`.

## Development

The tests need Docker, bash and Python 3 with [PyYAML](https://pypi.org/project/PyYAML/).

```bash
# Unit tests for the version handling plus configuration checks
./tests/run.sh

# Build the image the same way CI does and check the bundled binary
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.22 -t nebula-minimal addon
docker run --rm --entrypoint nebula nebula-minimal -version
```

CI runs these tests together with ShellCheck, Hadolint and an image build on
every pull request and on `main`.

## Maintenance

The **Update Nebula versions** workflow runs every Monday. It adds every newly
released Nebula version that ships the Linux assets this app supports to the
`nebula_version` list and bundles the newest one into the image. Existing
entries are kept so pinned versions keep working. The workflow only opens a
pull request, nothing is merged automatically.
