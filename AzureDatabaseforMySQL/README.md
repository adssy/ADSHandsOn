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
Azure Database for MySQL은 PaaS 서비스이기 때문에 로컬 서버의 시간을 변경할 수 없습니다  
대신 timezone 변경으로 그와 동일하게 작업할 수 있습니다  
VM에 설치된 MySQL Workbench를 통하여 하단 sql 스크립트를 실행 합니다  

[Time Zone 추가 스크립트](/AzureDatabaseforMySQL/change_time_zone.sql) 

초기 Now() 실행 시 서버 시간이 UTC로 제공됨을 알 수 있습니다  
우리는 Asia/Seoul로 진행할 예정이며 세션 수준에서 timezone은 쿼리로 변경할 수 있습니다  

```sql
SET time_zone = 'Asia/Seoul';
```


### 환경 변수 변경
위에서 작업된 timezone 변경은 세션 수준이며 만일 MySQL Server가 재시작 된다면 다시 원래의 UTC로 돌아가게 됩니다  
이를 방지하기 위해서는 기존 On-prem 환경에서는 my.cnf에서 time_zone parameter 추가로 해결할 수 있지만 PaaS에서는 서버 매개 변수를 변경해야 합니다  

변경 불가능한 환경 변수도 있으며 이는 고정된 값으로 구성되어 있습니다  
- 버퍼풀 관련 (서버의 SKU에 의해 결정 됩니다) [가격책정계층](https://docs.microsoft.com/ko-kr/azure/mysql/concepts-pricing-tiers) 
- innodb_flush_log_at_trx_commit : 1
- sync_binlog : 1
- innodb_log_file_size : 256MB
- innodb_log_files_in_group : 2

일반적인 환경에서 필수로 변경해야 하는 환경 변수는 다음과 같습니다  
- timezone 
- character_set_server
- collation_server

아래 Azure CLI 코드를 사용하여 서버 레벨의 환경 변수를 변경 합니다

```powershell
$resourceGroup= "rg-aztest"
$mySQLName= "mysqlname"

# 타임존 변경
az mysql server configuration set --name time_zone --resource-group $resourceGroup --server $mySQLName --value "Asia/Seoul"
# character_set_server 변경
az mysql server configuration set --name character_set_server --resource-group $resourceGroup --server $mySQLName --value "UTF8MB4"
# collation_server 변경
az mysql server configuration set --name collation_server --resource-group $resourceGroup --server $mySQLName --value "utf8mb4_unicode_ci"

```

### 방화벽 설정 및 기존 네트워크와 Public Endpoint 연결
Azure Database for MySQL은 기본적으로는 DNS 통신을 하며 방화벽으로 핸들링 됩니다  
기존 서비스와는 public endpoint를 통하여 서브넷간의 통신을 할 수 있고, Public ip로 통신도 가능 합니다  


또한 public endpoint외에 사설 통신만 사용할 수 있는 private link로 운영할 수도 있습니다  
![private link](https://docs.microsoft.com/ko-kr/azure/mysql/media/concepts-data-access-and-security-private-link/show-private-link-overview.png)