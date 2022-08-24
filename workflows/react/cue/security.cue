package main

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/shiftleft"
    "trustacks.io/trivy"
)

// Run source and container security scans.
#Security: {
    // React source code.
    source: dagger.#FS
    
    // Path containing the image.tar.
    artifacts: dagger.#FS

    // Static application security testing.
    sast: shiftleft.#Scan & {
        "source": source
    }

    // Scan the container.
    vulnerability: trivy.#Scan & {
        _imageTar: core.#Subdir & {
            input: artifacts
            path: "container"
        }
        source: _imageTar.output
    }
}
