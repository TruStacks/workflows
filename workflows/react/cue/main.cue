package main

import (
    "dagger.io/dagger"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "/assets":      read: contents: dagger.#FS
            "/tmp/source":  read: contents: dagger.#FS
            "/mnt/vars":    read: contents: dagger.#FS
            "/mnt/secrets": read: contents: dagger.#FS
        }
    }
    actions: {
        // React source code.
        _source:  client.filesystem."/tmp/source".read.contents
        _vars:    client.filesystem."/mnt/vars".read.contents
        _secrets: client.filesystem."/mnt/secrets".read.contents

        // Build the react project.
        build: #Build & {
            source:  _source
            assets:  client.filesystem."/assets".read.contents
            vars:    _vars
            secrets: _secrets
        }
    }
}
