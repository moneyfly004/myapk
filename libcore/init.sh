#!/bin/bash

chmod -R 777 .build 2>/dev/null
rm -rf .build 2>/dev/null

if [ -z "$GOPATH" ]; then
    GOPATH=$(go env GOPATH)
fi

# Install gomobile-matsuri
if [ ! -f "$GOPATH/bin/gomobile-matsuri" ]; then
    # Clone MatsuriDayo's gomobile to GOPATH so the bind package can be imported
    MOBILE_PATH="$GOPATH/src/golang.org/x/mobile"
    mkdir -p "$(dirname "$MOBILE_PATH")"

    git clone https://github.com/MatsuriDayo/gomobile.git "$MOBILE_PATH"
    pushd "$MOBILE_PATH"
    git checkout origin/master2

    # First, download all dependencies using module mode
    go mod download

    # Install gomobile and gobind commands with GO111MODULE=off to use GOPATH mode
    export GO111MODULE=off
    pushd cmd/gomobile
    go install -v
    popd
    pushd cmd/gobind
    go install -v
    popd
    popd

    # Rename to gomobile-matsuri and gobind-matsuri
    mv "$GOPATH/bin/gomobile" "$GOPATH/bin/gomobile-matsuri"
    mv "$GOPATH/bin/gobind" "$GOPATH/bin/gobind-matsuri"
fi

# Run gomobile init with GO111MODULE=off to ensure GOPATH mode
export GO111MODULE=off
GOBIND=gobind-matsuri gomobile-matsuri init
