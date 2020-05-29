# Set file and folder path for SSMS installer .exe
$folderpath="C:\AzHansOn\Files"

$filepath="$folderpath\robo3t-1.3.1-windows-x86_64-7419c406.zip"
$dest_path = "C:\Robo3t"

# start the Robo 3t installer
write-host "Beginning Robo 3t install..." -nonewline

Expand-Archive $filepath -DestinationPath $dest_path

Write-Host "Robo 3t installation complete" -ForegroundColor Green

