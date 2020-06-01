## ADSHandsOn Azure SQL Database
기존 환경 마이그레이션 혹은 신규 서비스 구축 시 진행해야 할 기본 구축 가이드  

### Azure SQL Database 생성 (General purpose - 1vCore)
```powershell
$resourceGroup="rg-aztest"
$location="koreacentral"
$serverName="myservername"
$dbName="myDbname"
$userName="myUsername"
$password="myPassword"
$collation="Korean_Wansung_CI_AS"


az sql server create -l $location -g $resourceGroup -n $serverName -u $userName -p $password
az sql db create -g $resourceGroup -s $serverName -n $dbName --collation $collation --sample-name AdventureWorksLT -e GeneralPurpose -f Gen4 -c 1
```

### 방화벽 및 Service Endpoint 추가
```powershell
$vnetName="vnet-aztest"
$subnetName="subnet-azsn"
$ruleName="allow-azsn"

az sql server vnet-rule create --server $serverName --name $ruleName -g $resourceGroup --subnet $subnetName --vnet-name $vnetName


```

만일 회사나 집 등 외부에서 접속하기 위해서는 public ip를 접속 가능하도록 변경 합니다  
```powershell
$ruleName="allowmyip"
$ipAddress="0.0.0.0"

az sql server firewall-rule create -g $resourceGroup -s $serverName -n $ruleName --start-ip-address $ipAddress --end-ip-address $ipAddress
```

### Geo-Replication

```powershell
$repLocation="japaneast"
$repServerName="myservername"

az sql server create --name $repServerName --resource-group $resourceGroup --location $repLocation --admin-user $userName --admin-password $password
az sql db replica create --name $dbName --partner-server $repServerName --resource-group $resourceGroup --server $serverName
```

### Failover Group
https://docs.microsoft.com/ko-kr/azure/azure-sql/database/auto-failover-group-overview?tabs=azure-powershell

```powershell
$fogName="myFogName"

# 신규 replica를 failover group으로 생성
az sql failover-group create --name $fogName --partner-server $repServerName  --resource-group $resourceGroup --server $serverName
```

### Azure SQL Database 생성 (Business critical - 1vCore)
Azure SQL Database Business critical 혹은 Premium tier 에서는 별도의 비용 없이 Zone Redundant (지원하는 지역에 한함) 및 Read-Only Replica를 사용할 수 있습니다

![sqlbc](https://docs.microsoft.com/en-us/azure/azure-sql/database/media/read-scale-out/business-critical-service-tier-read-scale-out.png)


```powershell
$location="japaneast"
# 기존 General purpose와 다른 변수 입력
$serverName="myservername"


az sql server create -l $location -g $resourceGroup -n $serverName -u $userName -p $password
az sql db create -g $resourceGroup -s $serverName -n $bcDbName --collation $collation --sample-name AdventureWorksLT -e BusinessCritical  -f Gen5 -c 2 --zone-redundant true
```


Business Critical의 경우 별도의 비용 없이 Read-Only Replica를 사용할 수 있습니다

먼저 SSMS를 통하여 기본 endpoint로 접속하여 아래 쿼리를 확인 합니다

```sql
-- 현재 접속이 읽기 전용 복제본인지 확인
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Updateability')
```

Read-Only로 접속하기 위해 Connection String에 ApplicationIntent=ReadOnly; 추가합니다  
SSMS에서 Connection String을 추가하기 위해서는 옵션을 클릭 후 추가 연결 매개변수에 추가합니다

![ssms00](https://azmyhanson.blob.core.windows.net/azcon/00_ssms_connection.jpg)


### Elastic Query 
https://docs.microsoft.com/ko-kr/azure/azure-sql/database/elastic-query-overview

### Elastic Job 
https://docs.microsoft.com/ko-kr/azure/azure-sql/database/elastic-jobs-overview

### Extend Event 


