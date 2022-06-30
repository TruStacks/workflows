package main

import (
    "dagger.io/dagger"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "../":          read: contents: dagger.#FS
            "/mnt/vars":    read: contents: dagger.#FS
            "/mnt/secrets": read: contents: dagger.#FS
            // "./_repo":     write: contents: actions.build.bump.output
        }
    }
    actions: {
        // React source code.
        _source: client.filesystem."../".read.contents
        
        // Build the react project.
        build: {
            #Build & {
                source:  _source
                vars:    client.filesystem."/mnt/vars".read.contents
                secrets: client.filesystem."/mnt/secrets".read.contents
            }
        }
    }
}
