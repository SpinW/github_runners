# Create the work folder and change to it
#mkdir c:/github
cd c:/github
#Get-ChildItem -Recurse | ?{Remove-Item $_.fullname -Recurse -Force}

# Reads variables from a file
Get-Content c:/vagrant/bootstrap_vars | Foreach-Object{
   $var = $_.Split('=')
   New-Variable -Name $var[0] -Value $var[1]
}

# Gets the github runner
#$runnerzip = "https://github.com/actions/runner/releases/download/v$GITHUB_RUNNER_VERSION/actions-runner-win-x64-$GITHUB_RUNNER_VERSION.zip"
#Invoke-WebRequest -Uri $runnerzip -OutFile ghrunner.zip
#Expand-Archive ghrunner.zip -DestinationPath .

# Gets the registration token
$registration_url = "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPOSITORY/actions/runners/registration-token"
$headers = @{"Authorization" = "token $GITHUB_PAT"}
echo "Requesting registration URL at '$registration_url'"
$payload = Invoke-WebRequest -Method POST -Uri $registration_url -Headers $headers
$RUNNER_TOKEN = ($payload.Content | ConvertFrom-Json).token

# Write teardown script
echo 'cd c:/github' > teardown.ps1
echo 'Get-Content c:/vagrant/bootstrap_vars | Foreach-Object{ $var = $_.Split("="); New-Variable -Name $var[0] -Value $var[1] }' >> teardown.ps1
echo '$removal_url="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPOSITORY/actions/runners/remove-token"' >> teardown.ps1
echo '$headers = @{"Authorization" = "token $GITHUB_PAT"}' >> teardown.ps1
echo '$payload = Invoke-WebRequest -Method POST -Uri $removal_url -Headers $headers' >> teardown.ps1
echo '$RUNNER_TOKEN= ($payload.Content | ConvertFrom-Json).token' >> teardown.ps1
echo './config.cmd remove --unattended --token ${RUNNER_TOKEN}' >> teardown.ps1

# Register runner and run it
$gh_repo = "https://github.com/$GITHUB_OWNER/$GITHUB_REPOSITORY"
$name = (1..16 | %{ '{0:X}' -f (Get-Random -Max 16)}) -join ''
./config.cmd --token $RUNNER_TOKEN --url $gh_repo --name $name --labels windows_matlab --unattended --replace --runasservice
# Unlike in Linux, runner doesn't exit when it starts, so run it as a service in the config step, otherwise hangs
#cmd.exe /c run.cmd
