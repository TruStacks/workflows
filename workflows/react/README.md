# Inputs

This workflow requires the following inputs to be mounted to the workflow container filesystem.

## Variables 
**mount path**: /mnt/vars

| name | description |
| - | - |
| remote | remote git repository ssh url *(ex: ssh://git@gitlab.com/trustacks/console/frontend.git)*
| registry | container registry host *(ex: quay.io)* |
| project | project name |
| registry-username | container registry username |
| age-key | [age](https://github.com/FiloSottile/age) public key for [sops](https://github.com/mozilla/sops) secrets encryption |


## Secrets 
**mount path**: /mnt/secrets

| name | description |
| - | - |
| registry-password | container registry password |
| source-private-key | git source private key |
| kubeconfig |  |