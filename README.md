# agent-anon

This repository provides a containerized Anon Network client designed to run as a local SOCKS5 proxy, with optional support for exposing services through Anon hidden services.

## Instructions

0. ./download.sh
1. podman build -t agent-anon:latest .
2. podman compose -f local-compose.yml up -d

`download.sh` is deliberately run separately from the image build. This makes subsequent builds offline and reproducible, using the locally downloaded anon.deb and anon.asc.

## Description
agent-anon builds a minimal Debian-based container containing the Anon Network client. The build process downloads a specific anon Debian package, verifies its SHA-256 checksum and expected GPG signing key, extracts the binary, and places it into a minimal runtime image.

At runtime, the container:

- Runs the Anon client as an unprivileged anon user (UID/GID 1000).
- Uses /var/lib/anon for runtime state.
- Mounts the Anon configuration at /etc/anon/anonrc rather than baking machine-specific configuration into the image.
- Provides a SOCKS5 proxy on 127.0.0.1:9050.
- Supports HiddenServiceDir entries in anonrc and waits for their .hostname files to become available.
- Uses pasta networking through Podman for local container networking.
- Removes cached/state files on startup to ensure a fresh client state.
- Automatically restarts through the Compose configuration.

## Security / verification

The build performs several integrity checks before installing the binary:

- Verifies that the downloaded signing key matches the expected fingerprint:
    `DC73B31AA1F797B180A87CBC7571AA42A0CBEFE9`
- Verifies the downloaded Debian package against a pinned SHA-256 checksum.
- Extracts only /usr/bin/anon from the package.
- Runs anon --version and calculates the resulting binary's SHA-256 hash.
- Runs the service without root privileges.
- Restricts /var/lib/anon to mode 700.
