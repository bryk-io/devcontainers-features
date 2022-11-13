# Development Container Features

'Features' are self-contained units of installation code and development
container configuration. Features are designed to install atop a wide-range
of base container images (**this repo focuses on `debian` based images**).

You may learn about Features at [containers.dev](https://containers.dev/implementors/features/), which is the website for the dev container specification.

## Usage

To reference a Feature from this repository, add the desired Features to
a `devcontainer.json`. The example below installs the `go` and `protobuf-tools`
declared in the [`./src`](./src) directory of this repository.

```jsonc
"name": "my-project-devcontainer",
"image": "mcr.microsoft.com/devcontainers/base:debian",
"features": {
  "ghcr.io/devcontainers/features/go:1": {
      "version": "1.19"
  },
  "ghcr.io/bryk-io/devcontainers-features/protobuf-tools:1": {
    "bufVersion": "1.9.0"
  }
}
```
