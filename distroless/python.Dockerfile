ARG UV_TAG=latest
ARG DEBIAN_TAG=12-slim
ARG PYTHON_VERSION=3.12.9

# ------------------------------------------------------------------------------

# download uv
FROM ghcr.io/astral-sh/uv:${UV_TAG} AS uv

# ------------------------------------------------------------------------------

FROM debian:${DEBIAN_TAG} AS builder
COPY --from=uv /uv /bin/

# re-declare PYTHON_VERSION in this scope
ARG PYTHON_VERSION

ENV UV_PYTHON=${PYTHON_VERSION}
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_FROZEN=1
ENV UV_PYTHON_PREFERENCE=only-managed
ENV UV_PYTHON_INSTALL_DIR=/python

# install python (before project for caching)
RUN uv python install

WORKDIR /app

# install dependencies only
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync \
    --no-dev \
    --no-editable \
    --no-install-project

# copy code (dockerignore is important)
COPY . .

# install in non-editable mode
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync \
    --no-dev \
    --no-editable

# ------------------------------------------------------------------------------

# may pin sha for reproducibility
FROM gcr.io/distroless/python3-debian12:nonroot

COPY --from=builder --chown=nonroot:nonroot --chmod=500 /python /python
COPY --from=builder --chown=nonroot:nonroot /app/.venv /app/.venv

ENTRYPOINT [ "/app/.venv/bin/start" ]
