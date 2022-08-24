package main

import (
    "dagger.io/dagger"

    "trustacks.io/react"
)

// Build the production bundle.
#Build: {
    // React source code.
    source: dagger.#FS

    // React production bundle.
    output: _build.output

    _build: react.#Build & {
        "source": source
    }
}
