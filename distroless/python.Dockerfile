ARG DEBIAN_VERSION_ID=12

# ------------------------------------------------------------------------------

FROM debian:${DEBIAN_VERSION_ID}-slim AS devbase
RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes \
    gcc \
    libpython3-dev \
    python3
COPY --from=ghcr.io/astral-sh/uv:0.5.26 /uv /bin/uv

# ------------------------------------------------------------------------------

FROM devbase AS builder

WORKDIR /app/

ENV PATH=/app/.venv/bin:$PATH

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_FROZEN=1
ENV UV_PYTHON_PREFERENCE=only-system

# install dependencies only
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync \
    --no-dev \
    --no-editable \
    --no-install-project

COPY ./scripts /app/scripts
COPY ./pyproject.toml ./uv.lock ./alembic.ini /app/
COPY ./app /app/app

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync \
    --no-dev \
    --no-editable

# ------------------------------------------------------------------------------

FROM gcr.io/distroless/python3-debian${DEBIAN_VERSION_ID}:nonroot AS production
WORKDIR /app
COPY --from=builder --chown=nonroot:nonroot /app/.venv /app/.venv
ENTRYPOINT [ "/app/.venv/bin/fastapi", "run", "/app/.venv/lib/python3.11/site-packages/app/main.py" ]


# Notes:
# - gcc libpython3-dev are needed to compile C Python modules
# - debian 12 bookworm has python 3.11.2
# - note that 3.11 is hardcoded in the entrypoint
# - https://github.com/GoogleContainerTools/distroless/tree/main/examples/python3-requirements
# - https://docs.astral.sh/uv/guides/integration/docker/#optimizations
# TODO:
# - pin sha https://console.cloud.google.com/artifacts/docker/distroless/us/gcr.io/python3-debian12?inv=1&invt=AbnHRw
