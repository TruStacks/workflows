# React Workflow

The workflow for [Create React App](https://create-react-app.dev/) (CRA) applications.

# Actions

## Build

- **Configure**: Prepare the source code for downstream actions. 
- **Version**: Generate the semantic build version using conventional commit syntax.
- **Lint**: Lint the source with eslint.
- **Test**: Run jest unit tests.
- **Static Application Security Test**: Scan for static vulnerabilities with shiftleft.
- **Build**: Build the production react application.
- **Containerize**: Build the application container image.
- **Vulnerability**: Scan for container vulnerabilties with trivy.
- **Publish**: Push the container image to the container registry.
- **Kustomize**: Generate the kustomize deploy resources. *(kubernetes only)*
- **Bump**: Bump the semantic version and tag the source.
- **Commit**: Push the tagged source to the remote repository.
- **Deploy**: Create and sync the argo application. *(kubernetes only)*

# Deployment Targets

## Kubernetes

The kubernetes deployment target deploys the react application into a kubernetes cluster as a static application in an nginx container image.

The container registry credentials provided via the `registryUsername` and `registryPassword` are encrypted and committed with the kustomize deployment assets to the provided git remote repository.

# Environment

**DEPLOY_TARGET** (default: *kubernetes*)  
The application deployment target

# Inputs

This workflow requires the following inputs to be mounted to the workflow container filesystem.

## Variables 
**mount path**: /mnt/vars

| Name | Description | Required | Deployment Target | Provider |
| - | - | - | - | - |
| project | Project name | yes | all | user |
| gitRemote | Remote git repository ssh url *(ex: ssh://git@gitlab.com/trustacks/console/frontend.git)* | yes | all | user |
| registryHost | Container registry host *(ex: quay.io)* | yes | all | user |
| registryUsername | Container registry username | yes | all | user |
| agePublicKey | [Age](https://github.com/FiloSottile/age) public key for [sops](https://github.com/mozilla/sops) secrets encryption | no | k8s | system |
| argo-cd.server | Argo CD server host and *optional* port *(\<host\>:\<port> \)* | no | k8s | system |

## Secrets 
**mount path**: /mnt/secrets

| Name | Description | Required | Deployment Target | Provider |
| - | - | - | - | - |
| gitPrivateKey | Git remote ssh private key | yes | all | user |
| registryPassword | Container registry password | yes | all | user |
| argo-cd.password | Argo CD auth password | no | k8s | system |
