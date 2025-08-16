#!/bin/bash
set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Ensure that login shells get the correct path if the user updated
# the PATH using ENV.
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

echo -e "Activating feature: 'gqlgenc'"
echo -e "Installing tools"
GQLGENC="0.31.0"
GO_TOOLS="\
  github.com/Yamashou/gqlgenc@v${GQLGENC}"
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
