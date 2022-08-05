package main

#Config: {
    // Variables and secrets.
    inputs: {
        vars: [
            {
                // Project name.
                name: "project"
            },
            {
                // Remote repository url (must begin with: 'ssh://').
                name: "gitRemote"
            },
            {
                // Container registry host.
                name: "registryHost"
            },
            {
                // Container registry auth username.
                name: "registryUsername"
            },
            {
                // Age public key for sops encryption.
                name: "agePublicKey"
            },
            {
                // Argo CD server (<host>:<port>)
                name: "argo-cd.server"
            }
        ]
        secrets: [
            {
                // Remote repository ssh private key.
                name: "gitPrivateKey"
            },
            {
                // Container registry auth password.
                name: "registryPassword"
            },
            {
                // Argo CD auth password.
                name: "argo-cd.password"
            },
        ]
    }
}
