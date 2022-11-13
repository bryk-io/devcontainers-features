#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
  for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
    if id -u ${CURRENT_USER} > /dev/null 2>&1; then
      USERNAME=${CURRENT_USER}
      break
    fi
  done
  if [ "${USERNAME}" = "" ]; then
    USERNAME=root
  fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
  USERNAME=root
fi

echo -e "Activating feature: 'protobuf-tools'"

# buf
BUF_VERSION=${BUFVERSION:-1.9.0}
echo -e "Installnig buf: $BUF_VERSION"
curl -sSL \
    "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-$(uname -s)-$(uname -m).tar.gz" | sudo tar -xvzf - -C "/usr/local" --strip-components 1

# protoc-plugins
echo -e "Installing protoc plugins"
PROTOC_GRPC_GATEWAY="2.12.0"
PROTOC_GEN_GO_GRPC="1.2.0"
PROTOC_GEN_VALIDATE="0.6.13"
PROTOC_GEN_GO="1.28.1"
PROTOC_GEN_DRPC="0.0.32"
PROTOC_GEN_ENT="0.3.3"
GO_TOOLS="\
  golang.org/x/tools/cmd/goimports@latest \
  github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${PROTOC_GRPC_GATEWAY} \
  github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v${PROTOC_GRPC_GATEWAY} \
  google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC} \
  github.com/envoyproxy/protoc-gen-validate@v${PROTOC_GEN_VALIDATE} \
  google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO} \
  storj.io/drpc/cmd/protoc-gen-go-drpc@v${PROTOC_GEN_DRPC} \
  entgo.io/contrib/entproto/cmd/protoc-gen-ent@v${PROTOC_GEN_ENT}"
export PATH=/go/bin:${PATH}
mkdir -p /tmp/gotools /usr/local/etc/vscode-dev-containers /go/bin
cd /tmp/gotools
export GOPATH=/tmp/gotools
export GOCACHE=/tmp/gotools/cache

# Use go get for versions of go under 1.16
go_install_command=install
if [[ "1.16" > "$(go version | grep -oP 'go\K[0-9]+\.[0-9]+(\.[0-9]+)?')" ]]; then
  export GO111MODULE=on
  go_install_command=get
  echo "Go version < 1.16, using go get."
fi

(echo "${GO_TOOLS}" | xargs -n 1 go ${go_install_command} -v )2>&1 | tee -a /usr/local/etc/vscode-dev-containers/go.log

# Move Go tools into path and clean up
mv /tmp/gotools/bin/* /go/bin/
rm -rf /tmp/gotools

# Clean up
rm -rf /var/lib/apt/lists/*

echo -e "\n(*) Success!\n"
