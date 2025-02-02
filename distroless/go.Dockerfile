ARG GO_VERSION=1.23

FROM golang:${GO_VERSION} AS builder
WORKDIR /go/src/app

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download

ARG PROGRAM=myapp
ARG PROGRAM_FOLDER=${PROGRAM}
ENV CGO_ENABLED=0
ENV GOCACHE=/root/.cache/go-build
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=bind,target=. \
    go build -o /go/bin/${PROGRAM} cmd/${PROGRAM_FOLDER}/*.go

FROM gcr.io/distroless/static-debian12:nonroot AS production
ARG PROGRAM
WORKDIR /home/nonroot
COPY --from=builder --chown=nonroot --chmod=500 /go/bin/${PROGRAM} demo
ENTRYPOINT [ "./demo" ]
