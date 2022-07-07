package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/argocd"
    "trustacks.io/commitizen"
    "trustacks.io/eslint"
    "trustacks.io/kubectl"
    "trustacks.io/react"
    "trustacks.io/shiftleft"
    "trustacks.io/sops"
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
        project:          strings.TrimSpace(_project.contents)
        registry:         strings.TrimSpace(_registry.contents)
        registryUsername: strings.TrimSpace(_registryUsername.contents)
        ageKey:           strings.TrimSpace(_ageKey.contents)

        _remote: core.#ReadFile & {
            input: vars
            path:  "remote"
        }
        _project: core.#ReadFile & {
            input: vars
            path:  "project"
        }
        _registry: core.#ReadFile & {
            input: vars
            path:  "registry"
        }
        _registryUsername: core.#ReadFile & {
            input: vars
            path:  "registry-username"
        }
        _ageKey: core.#ReadFile & {
            input: vars
            path:  "age-key"
        }
        if deployType == "kubernetes" {
            argocdServer: strings.TrimSpace(_argocdServer.contents)

            _argocdServer: core.#ReadFile & {
                input: vars
                path:  "argocd-server"   
            }
        }
    }

    // Secrets
    _secret: {
        registryPassword: _registryPassword.output
        privateKey:       _privateKey.output

        _registryPassword: core.#NewSecret & {
            input: secrets
            path:  "registry-password"
        }
        _privateKey: core.#NewSecret & {
            input: secrets
            path:  "source-private-key"
        }
        if deployType == "kubernetes" {
            argocdPassword: _argocdPassword.output

            _argocdPassword: core.#NewSecret & {
                input: secrets
                path:  "argocd-password"   
            }
        }
    }

    // Configure source.
    configure: react.#Configure & {
        "source": source
    }
    _source: configure.output

    // Fetch the next semantic version.
    version: commitizen.#Version & {
        source: _source
    }
    
    // Static analysis.
    lint: eslint.#Run & {
        source: _source
    }

    // Unit tests.
    test: react.#Test & {
        source: _source
    }

    // Static application security testing.
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

    // Scan container.
    vulnerability: trivy.#Scan & {
        image: containerize.output
    }

    // Push the container imag.
    publish: react.#Publish & {
        input:    _source
        image:    containerize.image
        ref:      _imageRef
        username: _var.registryUsername
        password: _secret.registryPassword
        requires: [
            lint.code,
            test.code,
            sast.code,
            vulnerability.code,
        ]
    }

    //  the source version.
    bump: commitizen.#Bump & {
        if deployType == "kubernetes" {
            source: k8s.kustomize.output
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

    k8s: {
        if deployType == "kubernetes" {
            // Create the kubernetes registry secret.
            _registrySecret: kubectl.#DockerRegistry & {
                name:      "registry-secret"
                namespace:  _var.project
                dryRun:    "client"
                server:    _var.registry
                username:  _var.registryUsername
                password:  _secret.registryPassword
            }

            // Encrypt the registry secret.
            _sopsRegistrySecret: sops.#Encrypt & {
                source: _registrySecret.output
                path:   "secret.yaml"
                regex:  "^(data|stringData)$"
                key:    _var.ageKey
            }

            // Configure the kustomize assets.
            kustomize: react.#Kustomize & {
                input:          publish.output
                "assets":       assets
                imageRef:       _imageRef
                registrySecret: _sopsRegistrySecret.output
                
                values: {
                    name:  _var.project
                    image: _imageRef
                }
            }

            // Create the argocd application.
            argo: argocd.#Create & {
                project:  _var.project
                server:     _var.argocdServer
                username:   "admin"
                password:   _secret.argocdPassword
                repo:       commit.output
                revision:   version.output
                privateKey: _secret.privateKey
                overlay:    "staging"
                insecure:   "true"
            }
        }
    }
}
