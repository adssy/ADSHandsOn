# Set file and folder path for SSMS installer .exe
$folderpath="C:\AzHansOn\Files"

$filepath="$folderpath\mysql-workbench-community-8.0.20-winx64.msi"
$vc_redist_path = "$folderpath\VC_redist.x64.exe"

 
# start the MySQL Workbench installer
write-host "Beginning VC_redist install..." -nonewline

Start-Process -FilePath $vc_redist_path -ArgumentList "/passive" -Wait -Passthru;
Write-Host "VC_redist installation complete" -ForegroundColor Green


write-host "Beginning MySQL Workbench install..." -nonewline
Start-Process $filepath -ArgumentList '/quiet' -Wait

Write-Host "MySQL Workbench installation complete" -ForegroundColor Green

