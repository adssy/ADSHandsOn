# ADSHandsOn 사전 준비
Azure Database Services handson을 진행하기 위해서  
테스트용 VM 배포 및 DBMS Tool (Mysql Workbench / SQL Server Management Studio / Robo 3T) 다운로드 및 설치를 진행 합니다

### 01. Azure CLI 설치
[Azure CLI Download](https://aka.ms/installazurecliwindows)  
수동 설치 혹은 PowerShell을 사용하여 Azure CLI를 설치할 수도 있습니다   
관리자 권한으로 PowerShell을 시작하고 다음 명령을 실행합니다  

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
rm .\AzureCLI.msi
 ```

### 02. Azure CLI Login
먼저 자신의 계정으로 로그인 합니다  
만일 자신의 계정에 구독이 여러개 있다면 테스트에서 사용할 구독을 입력 합니다  
```powershell
az login 
az account set --subscription "{your subscription}"
```

### 03. Azure VM 생성
```powershell
# Parameters 임의로 구성되었으며 수정 가능
# 파라미터 앞에 *이 붙은 항목은 필수 변경
$location="koreacentral"
$resourceGroup="rg-adstest"
$vnetName="vnet-adstest"
$subnetName="subnet-adstest"


$publicIPName="pip-adstestvm"
$nsgName="nsg-adstest"
$nicName="nic-adstest"
$vmName="vm-adstest"
$vmSize="Standard_D4s_v3"

# 계정 정보 입력
$AdminUserName="*username"
$AdminPassword="*password"


# Create a resource group.
az group create --name $resourceGroup --location $location

# Create a virtual network.
az network vnet create --resource-group $resourceGroup --name $vnetName --subnet-name $subnetName

# Create a public IP address.
az network public-ip create --resource-group $resourceGroup --name $publicIPName

# Create a network security group.
az network nsg create --resource-group $resourceGroup --name $nsgName

# Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group $resourceGroup --name $nicName `
--vnet-name $vnetName --subnet $subnetName --network-security-group $nsgName --public-ip-address $publicIPName

# Create a virtual machine. 
az vm create --resource-group $resourceGroup --name $vmName --location $location --nics $nicName --image win2016datacenter `
--admin-username $AdminUserName --admin-password $AdminPassword --size $vmSize

# Open port 3389 to allow RDP traffic to host.
az vm open-port --port 3389 --resource-group $resourceGroup --name $vmName
```


### 04. HandsOn 진행을 위한 Tools 설치파일 다운로드 및 설치
자동 설치  
생성된 VM 접속 후 Powershell 

```powershell
# vs 재배포 도구 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile .\vc_redist.x64.exe; 

$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& .\vc_redist.x64.exe $Prms | Out-Null

# mysql workbench 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.20-winx64.msi" -OutFile .\mysql-workbench-community-8.0.20-winx64.msi; 
Start-Process msiexec.exe -Wait -ArgumentList '/I mysql-workbench-community-8.0.20-winx64.msi /quiet'; 

# SQL Server Management Studio 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://aka.ms/ssmsfullsetup" -OutFile .\SSMS-Setup-KOR.exe; 

$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& .\SSMS-Setup-KOR.exe $Prms | Out-Null

# Robo 3T 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://download-test.robomongo.org/windows/robo3t-1.3.1-windows-x86_64-7419c406.zip" -OutFile .\robo3t.zip; 
Expand-Archive .\robo3t.zip -DestinationPath "C:\Robo3t"
```

자동 설치 실패 시 수동 설치  
[SSMS](https://docs.microsoft.com/ko-kr/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15)  
[MySQL Workbench](https://dev.mysql.com/downloads/workbench/)  
[Robo3t](https://robomongo.org/download)  

### HandsOn 진행
[Azure Database for MySQL](/AzureDatabaseforMySQL/README.md)  
[Azure SQL Database](/AzureSQLDatabase/README.md)  
[Azure CosmosDB](/AzureCosmosDB/README.md)  
