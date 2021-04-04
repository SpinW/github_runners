# Custom setup for spinw_ci

# Setup IExplorer
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

Write-Host -----------------------------
Write-Host Update system time
Write-Host -----------------------------
Set-Service w32time -StartupType Automatic
Start-Service w32time
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update
w32tm /resync

Write-Host -----------------------------
Write-Host Installing Chocolatey
Write-Host -----------------------------
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host -----------------------------
Write-Host Installing Github Runners
Write-Host -----------------------------
mkdir c:/github
cd c:/github
$runnerzip = "https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-win-x64-2.277.1.zip"
Invoke-WebRequest -Uri $runnerzip -OutFile ghrunner.zip
Expand-Archive ghrunner.zip -DestinationPath .
