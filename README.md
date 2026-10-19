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
