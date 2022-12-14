# Minimal webhookrelay sidecar

This is a minimal docker image for https://webhookrelay.com/

A minimal sidecar container meant to run a webhook relay for a networked docker
service.

# Credentials and setup

Create a file named `.env` at the root of this repo.  Populate it with the
following environment variables.

```bash
RELAY_KEY=your auth key
RELAY_SECRET=your auth secret
RELAY_BUCKET=forward relay bucket name
```

# Build the Docker image

    docker build -t relay .

# Run the docker image

Connect the relay with the following docker command.

    docker run --env-file .env relay

# Additional information

The relay container is under 25MB.  This is a proof of concept designed to be
run alongside another service with secrets provided in the environment.

This Docker image is designed to be built on the following architectures:

* `x86_64` or `amd64`
* `aarch64` or `arm64`
