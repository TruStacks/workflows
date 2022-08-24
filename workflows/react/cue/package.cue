package main

import (
    "dagger.io/dagger"

    "trustacks.io/react"
    "trustacks.io/shiftleft"
    "trustacks.io/trivy"
)

// Package the project build.
#Package: {
    // React source code.
    source: dagger.#FS
    
    // Build assets.
    assets: dagger.#FS

    // Input variables.
    vars: [name=string]: string
    
    // Input secrets.
    secrets: [name=string]: dagger.#Secret
    
    // The build version.
    version: string

    // How to package the application.
    packageAs: string | *null

    // Application production bundle.
    outputs: "build": build.output

    // Build the react app.
    build: react.#Build & {
        "source": source
    } 

    // Static application security testing.
    sast: shiftleft.#Scan & {
        "source": source
    }

    if packageAs == "container" {                
        // Container image ref.
        _imageRef: "\(vars."registryHost")/\(vars."project"):\(version)"

        // Build the container image.
        _container: react.#Containerize & {
            tag:      _imageRef
            "assets": assets
            "build":  build.output
        }

        // Scan the container.
        _vulnerability: trivy.#Scan & {
            source: _container.output
        }

        // Push the container imag.
        publish: react.#Publish & {
            input:    source
            image:    _container.image
            ref:      _imageRef
            username: vars."registryUsername"
            password: secrets."registryPassword"
            requires: [_vulnerability.code]
        }
    }
}