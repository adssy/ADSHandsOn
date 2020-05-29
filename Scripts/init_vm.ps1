function WriteLog
{
    Param ([string]$LogString)
    $LogFile = "C:\$(gc env:computername).log"
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}

try {
    WriteLog "Start PSDrive"
    $connectTestResult = Test-NetConnection -ComputerName azmyhanson.file.core.windows.net -Port 445
    if ($connectTestResult.TcpTestSucceeded) {
        cmd.exe /C "cmdkey /add:`"azmyhanson.file.core.windows.net`" /user:`"Azure\azmyhanson`" /pass:`"CIW22TOO9R/b+A18f0xUP2GU01mMv1tYnSHCPEdf+9exD+WQyUqpoSvc9aJxcYE9S/2CFyIjHhOff3mMEkW22w==`""
        New-PSDrive -Name Z -PSProvider FileSystem -Root "\\azmyhanson.file.core.windows.net\skhandson" -Persist -ErrorAction Stop
    } else {
        Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
    }
    WriteLog "Complete PSDrive"

    WriteLog "Start Drive Copy"
    Copy-Item -Path "Z:\*" -Destination "C:\" -Recurse -ErrorAction Stop
    WriteLog "Copy Complete"

    WriteLog "Start Install Azure CLI"
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
    rm .\AzureCLI.msi
    WriteLog "Complete Install Azure CLI"

    $path = "C:\AzHansOn\Scripts"

    $pslist = Get-ChildItem -Path $path

    foreach($ps in $pslist)
    {
        WriteLog ("Execute ps " + $ps.Name)
        & ($path + "\" + $ps.Name) -ErrorAction Stop

        WriteLog ("Complete ps " + $ps.Name)
    }

    Remove-PSDrive -Name Z
    Write-Host "install complete" -ForegroundColor Green
}
catch
{
    Write-Host ("Error" + $_.Exception.Message) -ForegroundColor Red
    WriteLog "Error"
}