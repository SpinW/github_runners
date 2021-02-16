#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    curl \
    sudo \
    git \
    jq
# For Ubuntu 18.04
apt-get install libicu60

apt-get clean
rm -rf /var/lib/apt/lists/*
useradd -m github

echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

cd /home/github/ || exit
mkdir work

curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

#!/bin/sh
registration_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"

payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

echo '#!/usr/bin/env bash' > /root/teardown.sh
echo "cd /home/github" >> /root/teardown.sh
echo "./svc.sh uninstall" >> /root/teardown.sh
echo 'removal_url="https://api.github.com/repos/'${GITHUB_OWNER}'/'${GITHUB_REPOSITORY}'/actions/runners/remove-token"' >> /root/teardown.sh
echo 'payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${removal_url})' >> /root/teardown.sh
echo 'export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)' >> /root/teardown.sh
echo 'sudo -u github /home/github/config.sh remove --unattended --token ${RUNNER_TOKEN}' >> /root/teardown.sh
chmod 700 /root/teardown.sh

su github -c "./config.sh \
    --name $( cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16 ) \
    --token ${RUNNER_TOKEN} \
    --url https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY} \
    --work ${RUNNER_WORKDIR} \
    --labels linux_matlab \
    --unattended \
    --replace"

chown -R github:github /home/github/

./svc.sh install github
./svc.sh start