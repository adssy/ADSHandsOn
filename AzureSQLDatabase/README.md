## ADSHandsOn Azure SQL Database
기존 환경 마이그레이션 혹은 신규 서비스 구축 시 진행해야 할 기본 구축 가이드  

### 01. Azure SQL Database 생성 (General purpose - 1vCore)
```powershell
# 파라미터 앞에 *이 붙은 항목은 필수 변경

$resourceGroup="rg-adstest"
$location="koreacentral"
$serverName="*myservername"
$dbName="*myDbname"
$userName="*myUsername"
$password="*myPassword"
$collation="Korean_Wansung_CI_AS"


az sql server create -l $location -g $resourceGroup -n $serverName -u $userName -p $password
az sql db create -g $resourceGroup -s $serverName -n $dbName --collation $collation --sample-name AdventureWorksLT -e GeneralPurpose -f Gen4 -c 1
```

### 02. 방화벽 및 Service Endpoint 추가
```powershell
$vnetName="vnet-adstest"
$subnetName="subnet-adstest"
$ruleName="allow-adstest"

az sql server vnet-rule create --server $serverName --name $ruleName -g $resourceGroup --subnet $subnetName --vnet-name $vnetName


```

만일 회사나 집 등 외부에서 접속하기 위해서는 public ip를 접속 가능하도록 변경 합니다  
```powershell
$ruleName="allowmyip"
$ipAddress="*0.0.0.0"

az sql server firewall-rule create -g $resourceGroup -s $serverName -n $ruleName --start-ip-address $ipAddress --end-ip-address $ipAddress
```

### 03. Geo-Replication
Azure SQL에서는 손쉽게 전 세계적으로 Replication을 구성할 수 있습니다  
![sqlgeorep](https://docs.microsoft.com/ko-kr/azure/azure-sql/database/media/active-geo-replication-overview/geo-replication.png)  

아래와 같이 Japan east에 Azure CLI로 Replication을 구성 합니다  

```powershell
$repLocation="japaneast"
$repServerName="*myservername"

az sql server create --name $repServerName --resource-group $resourceGroup --location $repLocation --admin-user $userName --admin-password $password
az sql db replica create --name $dbName --partner-server $repServerName --resource-group $resourceGroup --server $serverName
```

### 04. Failover Group
Geo-Replication에서는 slave node를 master로 fail-over 하려면 수동으로 진행 가능 합니다  
지역간의 fail-over를 자동으로 관리하기 위해서는 Failover Group을 사용하여야 합니다  

![azsqlfog](https://docs.microsoft.com/ko-kr/azure/azure-sql/database/media/auto-failover-group-overview/auto-failover-group.png)

구성을 위해서 아래 Azure CLI로 Replication이 진행된 primary (master), seconday (slave) 서버를 Failover Group에 추가 합니다  

```powershell
$fogName="*myFogName"

# 신규 replica를 failover group으로 생성
az sql failover-group create --name $fogName --partner-server $repServerName  --resource-group $resourceGroup --server $serverName
```

FOG (Failover group)을 사용하면 각 SQL Server의 endpoint를 사용하지 않아도 리스너를 통하여 primary와 secondary의 endpoint를 사용할 수 있습니다  
![fogendpoint](https://azmyhanson.blob.core.windows.net/azcon/01_fogendpoint.jpg)


### 05. Azure SQL Database 생성 (Business critical - 2vCore)
Azure SQL Database Business critical 혹은 Premium tier 에서는 별도의 비용 없이 Zone Redundant (지원하는 지역에 한함) 및 Read-Only Replica를 사용할 수 있습니다

![sqlbc](https://docs.microsoft.com/en-us/azure/azure-sql/database/media/read-scale-out/business-critical-service-tier-read-scale-out.png)


```powershell
$location="japaneast"
# 기존 General purpose와 다른 변수 입력
$bcServerName="*myservername"
$bcDbName="*mydbname"

az sql server create -l $location -g $resourceGroup -n $bcServerName -u $userName -p $password
az sql db create -g $resourceGroup -s $bcServerName -n $bcDbName --collation $collation --sample-name AdventureWorksLT -e BusinessCritical  -f Gen5 -c 2 --zone-redundant true
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


### 06. Time zone 변경
Azure SQL은 Timezone을 선택할 수 없으며 UTC 0으로 제공 됩니다 (Managed Instance는 Time zone 선택 가능)  
CURRENT_TIMESTAMP, GETDATE() 등 날짜 관련 함수를 사용하면 시간값이 UTC 0로 반환 되는 것을 확인할 수 있습니다

```sql
SELECT CURRENT_TIMESTAMP, GETDATE()
```

만일 신규 서비스가 아닌 기존에 한국 시간 기준으로 GETDATE()등을 사용해왔던 서비스라면 마이그레이션 시 시간은 변환해야 합니다  
변환하는 방법은 DB에서 GETDATE()등을 사용하지 않고, DB에 쿼리하는 서버 시간 기준으로 변경하거나  
별도의 사용자 함수를 추가해서 쿼리들을 변경해야 합니다  

SSMS에서 아래 Function을 추가하고 사용하는 방법을 확인 합니다  

```sql
CREATE FUNCTION FN_GETDATE()
RETURNS DATETIME
AS
BEGIN
     DECLARE @D AS datetimeoffset
     SET @D = CONVERT(datetimeoffset, GETDATE()) AT TIME ZONE 'Korea Standard Time'
     RETURN CONVERT(datetime, @D);
END


SELECT dbo.FN_GETDATE()
```


### 07. Elastic Query 
Azure SQL에서는 데이터베이스 간 Join 혹은 조회 및 Linked Server를 사용할 수 없습니다  
대신 Elastic Query를 통하여 원격지의 데이터를 조회할 수 있습니다  

다음 HandsOn에서는 기존 데이터베이스 서버에서 새로운 데이터베이스를 연결 후 두 데이터베이스간 Join하여 쿼리 하는 방법을 알아 봅니다  

```powershell
$newDBName="*myNewDBName"
az sql db create -g $resourceGroup -s $serverName -n $dbName --collation $collation --sample-name AdventureWorksLT -e GeneralPurpose -f Gen4 -c 1

# Allow Azure service
## 시작과 끝 아이피를 0.0.0.0 으로 지정하면 Azure 서비스 및 리소스가 서버에 엑세스 할수 있도록 허용 됩니다
az sql server firewall-rule create -g $resourceGroup -s $serverName -n allowazs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

- 위에 생성한 new DB에 접속
- 데이터베이스 서버에서 Azure Service 방문 허용 True로 변경 (azure portal)
- master key 생성
- Database Scoped Credential 생성
- External Data Source 생성
- 외부 테이블과 동일한 스키마의 외부 테이블 생성


```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<password>' ;

CREATE DATABASE SCOPED CREDENTIAL SQL_Credential
WITH
  IDENTITY = '<username>' ,
  SECRET = '<password>' ;

CREATE EXTERNAL DATA SOURCE MyElasticDBQueryDataSrc
WITH
  ( TYPE = RDBMS ,
    LOCATION = '<server_name>.database.windows.net' ,
    DATABASE_NAME = 'Customers' ,
    CREDENTIAL = SQL_Credential
  ) ;

-- 외부 테이블과 동일한 스키마를 가진 테이블을 생성 합니다
CREATE EXTERNAL TABLE [dbo].[ExtCustomer](
	[CustomerID] [int]  NOT NULL,
	[NameStyle] [dbo].[NameStyle] NOT NULL,
	[Title] [nvarchar](8) NULL,
	[FirstName] [dbo].[Name] NOT NULL,
	[MiddleName] [dbo].[Name] NULL,
	[LastName] [dbo].[Name] NOT NULL,
	[Suffix] [nvarchar](10) NULL,
	[CompanyName] [nvarchar](128) NULL,
	[SalesPerson] [nvarchar](256) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Phone] [dbo].[Phone] NULL,
	[PasswordHash] [varchar](128) NOT NULL,
	[PasswordSalt] [varchar](10) NOT NULL,
	[rowguid] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL)
WITH
( 
	DATA_SOURCE = MyElasticDBQueryDataSrc,
	SCHEMA_NAME = 'SalesLT',
	OBJECT_NAME = 'Customer'
)

SELECT TOP 100 *
FROM [dbo].[ExtCustomer] a
	INNER JOIN SalesLT.CustomerAddress b
	ON a.CustomerID = b.CustomerID


```

