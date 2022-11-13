#!/usr/bin/env bash

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace")
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

USERHOME="/home/$USERNAME"
if [ "$USERNAME" = "root" ]; then
  USERHOME="/root"
fi

echo "Activating feature: 'live-share'"

# install requirements
wget -O ~/vsls-reqs https://aka.ms/vsls-linux-prereq-script && \
chmod +x ~/vsls-reqs && \
~/vsls-reqs && \
rm ~/vsls-reqs

echo -e "\n(*) Success!\n"
