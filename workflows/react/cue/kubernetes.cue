package main

import (
    "dagger.io/dagger"

    "trustacks.io/kubectl"
    "trustacks.io/react"
    "trustacks.io/sops"
)

kubernetes: {
    #Build: {
        // Build assets.
        assets: dagger.#FS

        // Project source.
        source: dagger.#FS

        // age encryption key.
        ageKey: string
        
        // Container registry name.
        registry: string
        
        // Container registry username.
        registryUsername: string

        // Container registry password.
        registryPassword: dagger.#Secret
        
        // Container image name and tag.
        ref: string
        
        // Kustomize assets.
        output: kustomize.output

        // Create the kubernetes docker registry secret.
        _registrySecret: kubectl.#DockerRegistry & {
            name:     "registry-secret"
            dryRun:   "client"
            server:   registry
            username: registryUsername
            password: registryPassword
        }

        // Encrypt the registry secret.
        _sopsRegistrySecret: sops.#Encrypt & {
            source: _registrySecret.output
            path:   "secret.yaml"
            regex:  "^(data|stringData)$"
            key:    ageKey
        }

        // Configure the kustomize assets.
        kustomize: react.#Kustomize & {
            "source":       source
            "assets":       assets
            imageRef:       ref
            registrySecret: _sopsRegistrySecret.output
        }
    }
}