## ADSHandsOn Azure Database for MySQL
기존 환경 마이그레이션 혹은 신규 서비스 구축 시 진행해야 할 기본 구축 가이드  

### 01. Azure Database for MySQL 생성
기존 생성해둔 VM과 동일한 리소스 그룹에 신규로 생성 합니다  
Azure CLI로 아래와 같이 실행 합니다  

```powershell
# 기존 vm과 동일한 리소스 그룹 (만일 없다면 신규 생성 필요 az group create --name "resourceGroupName" --location "koreacentral")
$resourceGroup="rg-adstest"
$location="koreacentral"
$skuName="GP_Gen5_2"
$version="5.7"

# 계정 정보 입력 및 MySQL 서버명 입력
$mySQLName="mysqlname"
$userName="username"
$passWord="password"


az mysql server create --resource-group $resourceGroup --name $mySQLName  --location $location --admin-user $userName --admin-password $passWord --sku-name $skuName --version $version
```

### 02. 방화벽 설정 및 기존 네트워크와 Service Endpoint 연결
Azure Database for MySQL은 기본적으로는 DNS 통신을 하며 방화벽으로 핸들링 됩니다  
기존 서비스와는 service endpoint를 통하여 서브넷간의 통신을 할 수 있고, Public ip로 통신도 가능 합니다  

기존 생성된 Vnet에서 MySQL 서버에 접속할 수 있도록 Service endpoint를 추가 합니다  
```powershell
# 생성된 VM의 vnet과 subnet을 입력 합니다
$resourceGroup="rg-adstest"
$vnetName="vnet-adstest"
$subnetName="subnet-adstest"
$ruleName="allow-azsn"
$mySQLName="mysqlname"

# 서브넷에 service endpoint 추가
az network vnet subnet update -g $resourceGroup -n $subnetName --vnet-name $vnetName --service-endpoints Microsoft.SQL
# mysql rule 추가
az mysql server vnet-rule create -n $ruleName -g $resourceGroup -s $mySQLName --vnet-name $vnetName --subnet $subnetName
```

만일 회사나 집 등 외부에서 접속하기 위해서는 public ip를 접속 가능하도록 변경 합니다  
```powershell
$resourceGroup="rg-adstest"
$mySQLName="mysqlname"
$ruleName="allowmyip"
$ipAddress="0.0.0.0"

az mysql server firewall-rule create -g $resourceGroup -s $mySQLName -n $ruleName --start-ip-address $ipAddress --end-ip-address $ipAddress
```

또한 service endpoint외에 사설 통신만 사용할 수 있는 private link로 운영할 수도 있습니다  
![private link](https://docs.microsoft.com/ko-kr/azure/mysql/media/concepts-data-access-and-security-private-link/show-private-link-overview.png)  
[참고링크](https://docs.microsoft.com/ko-kr/azure/mysql/concepts-data-access-security-private-link)

### 03. MySQL 접속 확인
VM에 설치된 MySQL Workbench를 통하여 생성된 MySQL Server에 접속 합니다  
Hostname : {mySQLName}.mysql.database.azure.com  
Port : 3306  
Username : {userName@mySQLName}  



### 04. Time zone 변경
Azure Database for MySQL은 PaaS 서비스이기 때문에 로컬 서버의 시간을 변경할 수 없습니다  
대신 timezone 변경으로 그와 동일하게 작업할 수 있습니다  
VM에 설치된 MySQL Workbench를 통하여 하단 sql 스크립트를 실행 합니다  

[Time Zone 추가 스크립트](/AzureDatabaseforMySQL/change_time_zone.sql) 

초기 Now() 실행 시 서버 시간이 UTC로 제공됨을 알 수 있습니다  
우리는 Asia/Seoul로 진행할 예정이며 세션 수준에서 timezone은 쿼리로 변경할 수 있습니다  

```sql
SET time_zone = 'Asia/Seoul';
```


### 05. 환경 변수 변경
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
$resourceGroup="rg-adstest"
$mySQLName="mysqlname"

# 타임존 변경
az mysql server configuration set --name time_zone --resource-group $resourceGroup --server $mySQLName --value "Asia/Seoul"
# character_set_server 변경
az mysql server configuration set --name character_set_server --resource-group $resourceGroup --server $mySQLName --value "UTF8MB4"
# collation_server 변경
az mysql server configuration set --name collation_server --resource-group $resourceGroup --server $mySQLName --value "utf8mb4_unicode_ci"

```

### 06. 특정 시점 복원
Azure Database for MySQL에서는 다양한 방식 (Azure Portal, Azure CLI, Azure Powershell 등)으로 손쉽게 특정 시점으로 복원할 수 있습니다  
샘플 데이터베이스를 생성 후 특정 테이블을 실수로 삭제 한 뒤 삭제 이전 시점으로 복원하는 테스트를 진행 합니다  

MySQL Workbench를 실행한 후 [샘플 데이터베이스](/AzureDatabaseforMySQL/mysqlsampledatabase.sql) 를 전체 실행합니다  

이후 테이블을 삭제하고 삭제된 시간을 따로 기록해 둡니다

```sql
SELECT UTC_TIMESTAMP();

DROP TABLE classicmodels.customers;
```

#### Portal에서 실행
생성된 Azure Database for MySQL에서 개요에서 복원을 선택 합니다
![mysql00](https://azmyhanson.blob.core.windows.net/azcon/00_mysql_portal.jpg)

복원 시점 항목에서 DROP TABLE 작업한 시점을 입력 합니다  
새 서버명을 입력 후 확인 버튼을 클릭 합니다  
![mysql01](https://azmyhanson.blob.core.windows.net/azcon/01_mysql_portal.jpg)

#### CLI 로 실행

```powershell
$resourceGroup="rg-adstest"
$newServerName="newservername"
$mySQLName="mysqlname"
$restorePoint="2020-05-13T13:59:00Z"

az mysql server restore --resource-group $resourceGroup --name $newServerName --restore-point-in-time $restorePoint --source-server $mySQLName
```


#### 07. 복원된 서버로 접속
새로 복원된 서버는 방화벽의 정보는 가져오지만 설정한 Vnet 규칙은 가져오지 않습니다  
기존과 동일하게 신규 서버에 대한 Vnet Rule을 추가 합니다  

```powershell
# 생성된 VM의 vnet과 subnet을 입력 합니다
$resourceGroup="rg-adstest"
$vnetName="vnet-adstest"
$subnetName="subnet-azsn"
$ruleName="allow-azsn"
$mySQLName="restoremysqlname"

# mysql rule 추가
az mysql server vnet-rule create -n $ruleName -g $resourceGroup -s $mySQLName --vnet-name $vnetName --subnet $subnetName
```

접속 후 삭제 된 classicmodels.customers 테이블이 존재 하는지 확인 합니다  

이렇게 복원된 DB로 각 Application이 접속할 수 있도록 Application에서 MySQL Endpoint들을 모두 변경해주거나  
mysqldump 등 도구를 통해서 Restore된 신규 MySQL에서 Data를 Export, 기존 MySQL에 Import할 수 있습니다  

cmd console에서 MySQL 설치 경로로 이동 후 다음과 같은 명령어로 복구할 수 있습니다  

```console
.\mysqldump.exe -p{password} --user={user} --host={restore mysql host} --protocol=tcp --port=3306 --skip-column-statistics "classicmodels" "customers" > {output path.sql}

.\mysql.exe -p{password} --user={user} --host={main mysql host} --port=3306 --protocol=tcp --default-character-set=utf8 --comments --database=classicmodels  < {output path.sql}
```

### 08. Slow Query 모니터링
Azure Portal에서 생성된 MySQL을 찾아 왼쪽 항목에서 서버로그 탭을 선택 합니다  
상단에 매개 변수 편집을 클릭 합니다  

![serverlog](https://azmyhanson.blob.core.windows.net/azcon/02_mysql_serverlog.jpg)

아래 항목 수정 후 저장 버튼을 클릭 합니다  
- log_output : file
- long_query_time : 3
- slw_query_log : ON


이제 MySQL Workbench에서 3초 이상 걸리는 쿼리를 사용 합니다  

```sql
SELECT /*+ MAX_EXECUTION_TIME(5000) */ 1 
FROM classicmodels.customers WHERE SLEEP(1);
```

Azure Portal에서 생성된 서버 로그를 확인 합니다  


### Geo-Replication