#!/bin/bash

chmod -R 777 .build 2>/dev/null
rm -rf .build 2>/dev/null

if [ -z "$GOPATH" ]; then
    GOPATH=$(go env GOPATH)
fi

# Install gomobile-matsuri
if [ ! -f "$GOPATH/bin/gomobile-matsuri" ]; then
    # Clone MatsuriDayo's gomobile to a local directory
    MOBILE_PATH="../gomobile-matsuri"

    git clone https://github.com/MatsuriDayo/gomobile.git "$MOBILE_PATH"
    pushd "$MOBILE_PATH"
    git checkout origin/master2

    # Install gomobile and gobind commands
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

    # Add replace directive to go.mod to use local gomobile-matsuri
    if ! grep -q "replace golang.org/x/mobile" go.mod; then
        echo "" >> go.mod
        echo "replace golang.org/x/mobile => $MOBILE_PATH" >> go.mod
    fi
fi

GOBIND=gobind-matsuri gomobile-matsuri init
