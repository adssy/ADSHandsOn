## ADSHandsOn Azure Database for MySQL
기존 환경 마이그레이션 혹은 신규 서비스 구축 시 진행해야 할 기본 구축 가이드  

### Azure Database for MySQL 생성
기존 생성해둔 VM과 동일한 리소스 그룹에 신규로 생성 합니다  
Azure CLI로 아래와 같이 실행 합니다  

```powershell
# 기존 vm과 동일한 리소스 그룹 (만일 없다면 신규 생성 필요 az group create --name "resourceGroupName" --location "koreacentral")
$resourceGroup= "rg-aztest"
$location= "koreacentral"
$skuName= "GP_Gen5_2"
$version= "5.7"

# 계정 정보 입력 및 MySQL 서버명 입력
$mySQLName= "mysqlname"
$userName= "username"
$passWord= "password"


az mysql server create --resource-group $resourceGroup --name $mySQLName  --location $location --admin-user $userName --admin-password $passWord --sku-name $skuName --version $version
```

### Time zone 변경

[Time Zone 추가 스크립트](/AzureDatabaseforMySQL/change_time_zone.sql) 




### 환경 변수 변경


### 방화벽 설정 및 기존 네트워크와 Public Endpoint 연결


