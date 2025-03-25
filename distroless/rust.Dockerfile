ARG RUST_VERSION=1.85.1
ARG RUST_IMAGE_VARIANT=-slim-bookworm
ARG APP_NAME=myapp

# ------------------------------------------------------------------------------

FROM rust:${RUST_VERSION}${RUST_IMAGE_VARIANT} AS builder
WORKDIR /app
ARG APP_NAME

# Build the application.
# Leverage a cache mount to /usr/local/cargo/registry/
# for downloaded dependencies and a cache mount to /app/target/ for
# compiled dependencies which will speed up subsequent builds.
# Leverage a bind mount to the src directory to avoid having to copy the
# source code into the container. Once built, copy the executable to an
# output directory before the cache mounted /app/target is unmounted.
RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    <<EOF
set -e
cargo build --locked --release
cp ./target/release/$APP_NAME /bin/rustapp
EOF

# ------------------------------------------------------------------------------

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder --chown=nonroot --chmod=500 /bin/rustapp /bin/
ENTRYPOINT [ "/bin/rustapp" ]
