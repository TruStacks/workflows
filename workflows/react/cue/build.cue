package main

import (
    "dagger.io/dagger"

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

    // Variables.
    vars: [name=string]: string

    // Secrets.
    secrets: [name=string]: dagger.#Secret

    // Application deployment target.
    deployTarget: string | *"kubernetes"
    
    // Container image name and tag.
    _imageRef: "\(vars."registryHost")/\(vars."project"):\(version.output)"

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
        username: vars."registryUsername"
        password: secrets."registryPassword"
        requires: [
            lint.code,
            test.code,
            sast.code,
            vulnerability.code
        ]
    }

    //  the source version.
    bump: commitizen.#Bump & {
        if deployTarget == "kubernetes" {
            source: k8s.kustomize.output
        }
        amend:  [".trustacks"]
    }

    // Tag the source code.
    commit: react.#Commit & {
        source:     bump.output
        remote:     vars."gitRemote"
        privateKey: secrets."gitPrivateKey"
        "version":  version.output
    }

    k8s: {
        if deployTarget == "kubernetes" {
            // Create the kubernetes registry secret.
            _registrySecret: kubectl.#DockerRegistry & {
                name:      "registry-secret"
                namespace: vars."project"
                dryRun:    "client"
                server:    vars."registryHost"
                username:  vars."registryUsername"
                password:  secrets."registryPassword"
            }

            // Encrypt the registry secret.
            _sopsRegistrySecret: sops.#Encrypt & {
                source: _registrySecret.output
                path:   "secret.yaml"
                regex:  "^(data|stringData)$"
                key:    vars."agePublicKey"
            }

            // Configure the kustomize assets.
            kustomize: react.#Kustomize & {
                input:          publish.output
                "assets":       assets
                registrySecret: _sopsRegistrySecret.output
                
                values: {
                    name:  vars."project"
                    image: _imageRef
                }
            }

            // Create the argocd application.
            deploy: argocd.#Create & {
                project:    vars."project"
                server:     vars."argo-cd.server"
                username:   "trustacks"
                password:   secrets."argo-cd.password"
                repo:       commit.output
                revision:   version.output
                privateKey: secrets."gitPrivateKey"
                overlay:    "staging"
                insecure:   "true"
            }
        }
    }
}
