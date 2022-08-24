package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "trustacks.io/commitizen"
    "trustacks.io/react"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "/src":               read:  contents: dagger.#FS
            "/mnt":               read:  contents: dagger.#FS
            "/assets":            read:  contents: dagger.#FS
            "/artifacts":         read:  contents: dagger.#FS
            "/artifacts/version": write: contents: actions.setup.version
            "/artifacts/remote":  write: contents: actions.publish.outputs.remote
        }
        env: {
            PACKAGE: string | *"container"
            TARGET:  string | *"kubernetes"
        }
    }
    actions: {
        _artifacts: client.filesystem."/artifacts".read.contents
        _assets:    client.filesystem."/assets".read.contents
        _config:    #Config
        
        // Load the input variables and secrets.
        _inputs: #Inputs & {
            mounts: client.filesystem."/mnt".read.contents
            inputs: _config.inputs
        }

        // Configure the source.
        _configure: react.#Configure & {
            "source":   client.filesystem."/src".read.contents
            remote:     _inputs.vars."gitRemote"
            privateKey: _inputs.secrets."gitPrivateKey"
        }
        _source: _configure.output
 
        // Generate the build version.
        setup: {
            // Fetch the next semantic version.
            _version: commitizen.#Version & {
                source: _source
            }
            version: _version.output
        }
        
        // Nop.
        build: core.#Nop & {
            _noop: core.#Source & {
                path: "./"
            }
            input: _noop.output
        }

        // Run unit tests and lint.
        test: #Test & {
            source: _source
        }

        // Build the react bundle.
        "package": #Package & {
            _version: #Artifact & {
                input: _artifacts
                path:  "version"
            }

            source:    _source
            assets:    _assets
            vars:      _inputs.vars
            secrets:   _inputs.secrets
            version:   _version.output.contents
            packageAs: client.env.PACKAGE
        }

        // Publish the application.
        publish: #Publish & {
            _version: #Artifact & {
                input: _artifacts
                path:  "version"
            }

            source:       _source
            assets:       _assets
            vars:         _inputs.vars
            secrets:      _inputs.secrets
            version:      _version.output.contents
            deployTarget: client.env.TARGET
            packageAs:    client.env.PACKAGE
        }

        stage: #Deploy & {
            _version: #Artifact & {
                input: _artifacts
                path:  "version"
            }

            _remote:  #Artifact & {
                input: _artifacts
                path: "remote"
            }

            vars:         _inputs.vars
            secrets:      _inputs.secrets
            remote:       _remote.output.contents
            version:      _version.output.contents
            deployTarget: client.env.TARGET
        }
    }
}

#Artifact: {
    input: dagger.#FS

    kind: string | *"file"

    path: string

    if kind == "fs" {
        _fs: core.#Subdir & {
            "input": input
            "path":  path
        }
        output: _fs.output
    }

    if kind == "file" {
        _file: core.#ReadFile & {
            "input": input
            "path":  path
        }
        output: _file
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
