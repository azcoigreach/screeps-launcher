FROM golang:1.23-bookworm AS builder

ARG ARCH=amd64
WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=${ARCH} \
    go build -o screeps-launcher ./cmd/screeps-launcher

FROM buildpack-deps:buster

ARG UID=1000
ARG GID=1000
RUN if [[ "${GID}" != "0" ]] ; then \
        groupadd --gid ${GID} screeps ; \
    fi && \
    if [[ "${UID}" != "0" ]] ; then \
        useradd --uid ${UID} --gid ${GID} --shell /bin/bash --create-home screeps ; \
    fi && \
    mkdir /screeps && chown -R ${UID}:${GID} /screeps

ENV HOME=/home/screeps
ENV YARN_CACHE_FOLDER=$HOME/.cache/yarn
RUN mkdir -p $YARN_CACHE_FOLDER && chown -R ${UID}:${GID} $HOME

# Install Node.js and Yarn
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

USER ${UID}:${GID}
WORKDIR /screeps

# Copy the screeps-launcher executable
COPY --from=builder /app/screeps-launcher /usr/bin/

ENTRYPOINT ["screeps-launcher"]
