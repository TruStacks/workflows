package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "/src":    read: contents: dagger.#FS
            "/mnt":    read: contents: dagger.#FS
            "/assets": read: contents: dagger.#FS
        }
        env: {
            DEPLOY_TARGET: string | *null
        }
    }
    actions: {
        _assets: client.filesystem."/assets".read.contents
        _source: client.filesystem."/src".read.contents
        _config: #Config

        // Build the react project.
        build: #Build & {
            _inputs: #Inputs & {
                mounts: client.filesystem."/mnt".read.contents
                inputs: _config.inputs
            }
            source:       _source
            assets:       _assets 
            vars:         _inputs.vars
            secrets:      _inputs.secrets
            deployTarget: client.env.DEPLOY_TARGET
        }
    }
}

// Variable and secret inputs.
#Inputs: {
    // Variable and secrets filesystem mount.
    mounts: dagger.#FS

    // Variables and secrets.
    inputs: {
        vars:    [...{name: string, trim: bool | *true}]
        secrets: [...{name: string, trim: bool | *false}]
    }
    
    // Rendered variables and secrets.
    vars: [name=string]: string
    _vars: {
        for var in inputs.vars {
            "\(var.name)": {
                if var.trim == true {
                    value: strings.TrimSpace(_var.contents)
                }
                if var.trim == false {
                    value: _var.contents
                }
                _var: core.#ReadFile & {
                    input: mounts
                    path:  "vars/\(var.name)"
                }
            }
        }
    }
    for name, var in _vars {
        vars: "\(name)": var.value
    }

    secrets: [name=string]: dagger.#Secret
    _secrets: {
        for secret in inputs.secrets {
            "\(secret.name)": {
                value: _secret.output
                _secret: core.#NewSecret & {
                    input: mounts
                    path:  "secrets/\(secret.name)"
                    if secret.trim == true {
                        trimSpace: true
                    }
                }
            }
        }
    }
    for name, secret in _secrets {
        secrets: "\(name)": secret.value
    }
}