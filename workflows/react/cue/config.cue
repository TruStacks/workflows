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
                name: "git-remote"
            },
            {
                // Container registry host.
                name: "registry-host"
            },
            {
                // Container registry auth username.
                name: "registry-username"
            },
            {
                // Age public key for sops encryption.
                name: "age-key"
            },
            {
                // Argo CD server (<host>:<port>)
                name: "argocd-server"
            }
        ]
        secrets: [
            {
                // Remote repository ssh private key.
                name: "git-private-key"
            },
            {
                // Container registry auth password.
                name: "registry-password"
            },
            {
                // Argo CD auth password.
                name: "argocd-password"
            },
        ]
    }
}
