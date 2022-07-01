package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/commitizen"
    "trustacks.io/eslint"
    "trustacks.io/flux2"
    "trustacks.io/react"
    "trustacks.io/shiftleft"
    "trustacks.io/trivy"
)

// Build the code for release.
#Build: {
    // React source code.
    source: dagger.#FS
    
    // Build assets.
    assets: dagger.#FS

    // Variable mounts.
    vars: dagger.#FS

    // Secret mounts.
    secrets: dagger.#FS

    // The deployment target.
    deployType: string | *"kubernetes"
    
    // Container image name and tag.
    _imageRef: "\(_var.registry)/\(_var.project):\(version.output)"

    // Variables
    _var: {
        remote:           strings.TrimSpace(_remote.contents)
        registry:         strings.TrimSpace(_registry.contents)
        project:          strings.TrimSpace(_project.contents)
        registryUsername: strings.TrimSpace(_registryUsername.contents)
        ageKey:           strings.TrimSpace(_ageKey.contents)

        _remote: core.#ReadFile & {
            input: vars
            path:  "remote"
        }
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
        _ageKey: core.#ReadFile & {
            input: vars
            path:  "age-key"
        }
    }

    // Secrets
    _secret: {
        registryPassword: core.#NewSecret & {
            input: secrets
            path:  "registry-password"
        }
        privateKey: core.#NewSecret & {
            input: secrets
            path:  "source-private-key"
        }
        kubeconfig: core.#NewSecret & {
            input: secrets
            path:  "kubeconfig"
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
    
    // Run static analysis.
    lint: eslint.#Run & {
        source: _source
    }

    // Run unit tests.
    test: react.#Test & {
        source: _source
    }

    // Run static application security testing.
    sast: shiftleft.#Scan & {
        source: _source
    }

    // Build the react app.
    build: react.#Build & {
        source: _source
    }

    // Build the container image.
    containerize: react.#Containerize & {
        tag:      _imageRef
        "assets": assets
        "build":  build.output
    }

    // Scan for container vulnerabilities.
    vulnerability: trivy.#Scan & {
        image: containerize.output
    }

    // Push the container imag.
    publish: react.#Publish & {
        image:    containerize.image
        ref:      _imageRef
        username: _var.registryUsername
        password: _secret.registryPassword.output
    }

    //  the source version.
    bump: commitizen.#Bump & {
        if deployType == "kubernetes" {
            source: target.k8s.output
        }
        amend:  [".trustacks"]
    }

    // Tag the source code.
    commit: react.#Commit & {
        source:    bump.output
        remote:    _var.remote
        "secrets": secrets
        "version": version.output
    }

    target: {
        // Build the kubernetes deployment.
        if deployType == "kubernetes" {
            k8s: kubernetes.#Build & {
                "assets":         assets
                source:           _source
                ageKey:           _var.ageKey
                registry:         _var.registry
                registryUsername: _var.registryUsername
                registryPassword: _secret.registryPassword.output
                ref:              _imageRef
            }
            flux: flux2.#Create & {
                project:    _var.project
                url:        commit.output
                tag:        "0.8.0"
                privateKey: _secret.privateKey.output
                kubeconfig: _secret.kubeconfig.output
            }
        }
    }
}
