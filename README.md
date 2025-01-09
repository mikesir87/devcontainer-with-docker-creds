# Devcontainers with Docker auth

This is a sample project that will open in a devcontainer, use the Docker socket from the host (not DinD), and be configured with a Docker `config.json` file to access private registries.

## Why is this needed? What's it do?

Before making a request to the Docker engine, the Docker CLI fetches and attachs the appropriate credentials to the request. 

When using Docker Desktop, those credentials are stored in the Mac OSX keychain. When using the CLI on the host, it can access those credentials. But, when attempting to access those credentials from inside a container, no luck.

This project is configured to use the `.devcontainer/cred-setup.sh` file as an `initializeCommand` lifecycle hook, which runs on the host _before_ the devcontainer starts. This script extracts the credentials and creates a `config.json` file, from which the CLI _inside_ the container can use.