package main

import (
    "dagger.io/dagger"

    "trustacks.io/eslint"
    "trustacks.io/react"
)

// Run unit tests and lint.
#Test: {
    // React source code.
    source: dagger.#FS

    // Lint source.
    lint: eslint.#Run & {
        "source": source
    }

    // Run Unit tests.
    unit: react.#Test & {
        "source": source
    }
}
