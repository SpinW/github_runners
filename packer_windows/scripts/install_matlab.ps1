E:
#$proc = Invoke-WmiMethod -Class win32_process -Name create -ArgumentList ".\setup.exe 
#$proc = Start-Process .\setup.exe -ArgumentList "-inputFile A:\installer_input.txt" -PassThru
.\setup.exe -inputFile A:\installer_input.txt
Start-Sleep -Seconds 30
$proc = Get-Process -Name setup | where { $_.MainModule.FileName -eq "e:\bin\win64\setup.exe" }
Wait-Process -Id $proc.Id -Timeout 1200
