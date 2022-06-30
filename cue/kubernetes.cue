package main

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/kubectl"
    "trustacks.io/react"
    "trustacks.io/sops"
)

kubernetes: {
    #Build: {
        // React source code.
        source: dagger.#FS

        // Secret and config mounts.
        mounts: dagger.#FS
        
        // Container registry credentials.
        registryCredentials: _
        
        // Container registry name.
        registry: string
        
        // Container image name and tag.
        ref: string
        
        // Kustomize assets.
        output: kustomize.output

        // Age key for sops.
        _ageKey: core.#NewSecret & {
            input: mounts
            path:  "/secrets/age-key"
        }

        // Create the kubernetes docker registry secret.
        registrySecret: kubectl.#DockerRegistry & {
            name:     "registry-secret"
            dryRun:   "client"
            server:   registry
            username: registryCredentials.username.contents
            password: registryCredentials.password.output
        }

        // Encrypt the registry secret.
        sopsRegistrySecret: sops.#Encrypt & {
            source: registrySecret.output
            path:   "secret.yaml"
            regex:  "^(data|stringData)$"
            ageKey: _ageKey.output
        }

        // Configure the kustomize assets.
        kustomize: react.#Kustomize & {
            "source":       source
            depsDir:        ".trustacks/assets"
            imageRef:       ref
            registrySecret: sopsRegistrySecret.output
        }
    }
}