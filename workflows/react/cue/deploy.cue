package main

import (
    "dagger.io/dagger"

    "trustacks.io/argocd"
)

// Deploy the application.
#Deploy: {
    // Input variables.
    vars: [name=string]: string

    // Input secrets.
    secrets: [name=string]: dagger.#Secret

    // Remote git url.
    remote: string

    // The build version.
    version: string

    // Application deployment target.
    deployTarget: string

    k8s: {
        if deployTarget == "kubernetes" {
            argocd.#Create & {
                project:    vars."project"
                server:     vars."argo-cd.server"
                username:   "trustacks"
                password:   secrets."argo-cd.password"
                repo:       remote
                revision:   version
                privateKey: secrets."gitPrivateKey"
                overlay:    "staging"
                insecure:   "true"
            }
        }
    }
}