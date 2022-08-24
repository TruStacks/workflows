package main

import (
    "dagger.io/dagger"

    "trustacks.io/commitizen"
    "trustacks.io/kubectl"
    "trustacks.io/sops"
    "trustacks.io/react"
)

#Publish: {
    // React source code.
    source: dagger.#FS
    
    // Build assets.
    assets: dagger.#FS

    // Input variables.
    vars: [name=string]: string

    // Input secrets.
    secrets: [name=string]: dagger.#Secret

    // Application deployment target.
    deployTarget: string | *null

    // How to package the application.
    packageAs: string | *null
    
    // Meta version tag.
    version: string

    outputs: remote: _commit.output

    // Build the react app.
    build: react.#Build & {
        "source": source
    } 

    // Tag the source.
    _tag: commitizen.#Bump & {
        if deployTarget == "kubernetes" {
            source: _k8s.kustomize.output
        }
        amend: [".trustacks"]
    }

    // Commit the source tag.
    _commit: react.#Commit & {
        source:     _tag.output
        remote:     vars."gitRemote"
        privateKey: secrets."gitPrivateKey"
        "version":  version
    }

    _k8s: {
        if deployTarget == "kubernetes" {
            // Container image ref.
            _imageRef: "\(vars."registryHost")/\(vars."project"):\(version)"

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
                input:          source
                "assets":       assets
                registrySecret: _sopsRegistrySecret.output
                
                values: {
                    name:  vars."project"
                    image: _imageRef
                }
            }
        }
    }
}
