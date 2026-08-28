# ---------------------------------------------------------------------------
# Stage 1: Verify and extract anon binary
# Pre-downloaded files required — run ./download.sh first
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg \
    binutils \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY anon.asc .
COPY anon.deb .

# Verify signing key ID
RUN gpg --show-keys --with-fingerprint --with-colons anon.asc 2>/dev/null | grep -qi "DC73B31AA1F797B180A87CBC7571AA42A0CBEFE9" || \
    (echo "ERROR: GPG key ID mismatch — aborting" && exit 1)

RUN gpg --import anon.asc

# Verify SHA256
RUN echo "2073a0eee48aa2bfe7fd7594c19869b722517e6a2971a8be2295a1efd81001fa  anon.deb" \
    | sha256sum -c - || (echo "ERROR: SHA256 mismatch — aborting" && exit 1)

# Extract binary
RUN ar x anon.deb
RUN tar -xf data.tar* ./usr/bin/anon

# ---------------------------------------------------------------------------
# Stage 2: Minimal runtime image
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libevent-2.1-7 \
    zlib1g \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/usr/bin/anon /usr/local/bin/anon
RUN chmod +x /usr/local/bin/anon
RUN anon --version
RUN sha256sum /usr/local/bin/anon

# anonrc is NOT baked in — mounted at runtime per machine
RUN mkdir -p /etc/anon

RUN groupadd --gid 1000 anon && \
    useradd --uid 1000 --gid anon --no-create-home --shell /bin/false anon

RUN mkdir -p /var/lib/anon && \
    chown -R anon:anon /var/lib/anon && \
    chmod 700 /var/lib/anon

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER anon

CMD ["/entrypoint.sh"]
