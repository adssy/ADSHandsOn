# ADSHandsOn-SK
Azure Database Services handson

## Azure CLI 설치
[Azure CLI Download](https://aka.ms/installazurecliwindows)  
수동 설치 혹은 PowerShell을 사용하여 Azure CLI를 설치할 수도 있습니다.  
관리자 권한으로 PowerShell을 시작하고 다음 명령을 실행합니다.

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
az account set --subscription "{your subscription"
```

### Azure VM 생성
