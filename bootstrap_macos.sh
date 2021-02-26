#!/usr/bin/env zsh

source ~/.zshrc
#cat ~.zshrc >> /Users/vagrant/.zshrc

echo $(pwd)

cd /Users/github/ || exit
mkdir -p work
chown github:staff /Users/github/work

sudo su github -c "curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-osx-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz"

#!/bin/sh
registration_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"

payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

echo '#!/usr/bin/env zsh' > /Users/vagrant/teardown.sh
echo 'source /var/root/.zshrc' >> /Users/vagrant/teardown.sh
echo 'rm /Users/github/.service' >> /Users/vagrant/teardown.sh
echo 'removal_url="https://api.github.com/repos/'${GITHUB_OWNER}'/'${GITHUB_REPOSITORY}'/actions/runners/remove-token"' >> /Users/vagrant/teardown.sh
echo 'payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${removal_url})' >> /Users/vagrant/teardown.sh
echo 'export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)' >> /Users/vagrant/teardown.sh
echo 'sudo -u github /Users/github/config.sh remove --unattended --token ${RUNNER_TOKEN}' >> /Users/vagrant/teardown.sh
chmod 700 /Users/vagrant/teardown.sh

sudo su github -c "/Users/github/config.sh \
    --name $( cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 16 ) \
    --token ${RUNNER_TOKEN} \
    --url https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY} \
    --work ${RUNNER_WORKDIR} \
    --labels macos_matlab \
    --unattended \
    --replace"

sudo chmod -R +a "vagrant allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity" /Users/github

sudo su github -c "/Users/github/svc.sh install"
sudo mv  /Users/github/Library/LaunchAgents/* /Library/LaunchDaemons/

reboot