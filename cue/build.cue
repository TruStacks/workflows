package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/commitizen"
    // "trustacks.io/eslint"
    "trustacks.io/react"
    // "trustacks.io/shiftleft"
    "trustacks.io/trivy"
)

// Build the code for release.
#Build: {
    // React source code.
    source: dagger.#FS
    
    // Variable mounts.
    vars: dagger.#FS

    // Secret mounts.
    secrets: dagger.#FS

    // Container image name and tag.
    imageRef: "\(_var.registry)/\(_var.project):\(version.output)"

    // The deployment target.
    targetType: string | *"kubernetes"

    // Variables
    _var: {
        registry:         strings.TrimSpace(_registry.contents)
        project:          strings.TrimSpace(_project.contents)
        registryUsername: strings.TrimSpace(_registryUsername.contents)

        _registry: core.#ReadFile & {
            input: vars
            path:  "registry"
        }
        _project: core.#ReadFile & {
            input: vars
            path:  "project"
        }
        _registryUsername: core.#ReadFile & {
            input: vars
            path:  "registry-username"
        }
    }

    // Secrets
    _secret: {
        registryPassword: core.#NewSecret & {
            input:     secrets
            path:      "registry-password"
            trimSpace: true
        }
    }

    // Configured source.
    _source: configure.output

    // Run the prerequisites.
    configure: react.#Configure & {
        "source": source
    }

    // Fetch the next semantic version.
    version: commitizen.#Version & {
        source: _source
    }
    
    // // Run static analysis.
    // lint: eslint.#Run & {
    //     source: _source
    // }

    // // Run unit tests.
    // test: react.#Test & {
    //     source: _source
    // }

    // // Run static application security testing.
    // sast: shiftleft.#Scan & {
    //     source: _source
    // }

    // Build the react app.
    build: react.#Build & {
        source: _source
    }

    // Build the container image.
    containerize: react.#Containerize & {
        tag:     imageRef
        source:  configure.output
        assets:  ".trustacks/assets"
        "build": build.output
    }

    // Scan for container vulnerabilities.
    vulnerability: trivy.#Scan & {
        image: containerize.output
    }

    // Push the container imag.
    publish: react.#Publish & {
        ref:      imageRef
        image:    containerize.image
        username: _var.registryUsername
        password: _secret.registryPassword.output
    }

    // // Create the tag commit.
    // bump: commitizen.#Bump & {
    //     source:  target.output
    //     include: [".trustacks/assets/kustomize"]
    // }

    // target: {
    //     // Build the kubernetes deployment.
    //     if targetType == "kubernetes" {
    //         kubernetes.#Build & {
    //             "source":            configure.output
    //             "mounts":            mounts
    //             "registry":          registry
    //             ref:                 imageRef
    //             registryCredentials: _registryCredentials
    //         }
    //     }
    // }
}
