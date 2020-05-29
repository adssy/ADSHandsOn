
# Set file and folder path for SSMS installer .exe
$folderpath="C:\AzHansOn\Files"

$filepath="$folderpath\SSMS-Setup-KOR.exe"

# start the SSMS installer
write-host "Beginning SSMS install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null

Write-Host "SSMS installation complete" -ForegroundColor Green