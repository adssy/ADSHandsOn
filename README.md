# ADSHandsOn-SK 사전 준비
Azure Database Services handson을 진행하기 위해서  
테스트용 VM 배포 및 DBMS Tool (Mysql Workbench / SQL Server Management Studio / Robo 3T) 다운로드 및 설치를 진행 합니다

### Azure CLI 설치
[Azure CLI Download](https://aka.ms/installazurecliwindows)  
수동 설치 혹은 PowerShell을 사용하여 Azure CLI를 설치할 수도 있습니다   
관리자 권한으로 PowerShell을 시작하고 다음 명령을 실행합니다  

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
rm .\AzureCLI.msi
 ```

### Azure CLI Login
먼저 자신의 계정으로 로그인 합니다  
만일 자신의 계정에 구독이 여러개 있다면 테스트에서 사용할 구독을 입력 합니다  
```powershell
az login 
az account set --subscription "{your subscription}"
```

### Azure VM 생성
```powershell
# Parameters 임의로 구성되었으며 수정 가능

$location="koreacentral"
$resourceGroupName="rg-aztest"
$vnetName="vnet-aztest"
$subnetName="subnet-azsn"
$publicIPName="pip-aztestvm"
$nsgName="nsg-aztest"
$nicName="nic-aztest"
$vmName="vm-aztest"

$AdminUserName="cloocus"
$AdminPassword="votmdnjem12#$"


# Create a resource group.
az group create --name $resourceGroupName --location $location

# Create a virtual network.
az network vnet create --resource-group $resourceGroupName --name $vnetName --subnet-name $subnetName

# Create a public IP address.
az network public-ip create --resource-group $resourceGroupName --name $publicIPName

# Create a network security group.
az network nsg create --resource-group $resourceGroupName --name $nsgName

# Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group $resourceGroupName --name $nicName `
--vnet-name $vnetName --subnet $subnetName --network-security-group $nsgName --public-ip-address $publicIPName

# Create a virtual machine. 
az vm create --resource-group $resourceGroupName --name $vmName --location $location --nics $nicName --image win2016datacenter `
--admin-username $AdminUserName --admin-password $AdminPassword

# Open port 3389 to allow RDP traffic to host.
az vm open-port --port 3389 --resource-group $resourceGroupName --name $vmName
```


### HandsOn 설치파일 다운로드 및 설치
수동 설치  
[SSMS](https://docs.microsoft.com/ko-kr/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15) [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) [Robo3t](https://robomongo.org/download)  

자동 설치  
생성된 VM 접속 후 아래 스크립트 실행
```powershell
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
```

### HandsOn 진행
[Azure Database for MySQL](../master/Azure Database for MySQL/README.md)
