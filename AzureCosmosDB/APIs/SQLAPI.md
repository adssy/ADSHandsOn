### 01. Azure CosmosDB Account 생성
아래 정보를 참고하여 Azure Cosmosdb Account를 생성 합니다
```powershell
$resourceGroup="rg-adstest"
$location="koreacentral"
$accountName="*myAccountName"

# 생성시 koreacentral을 master로, south를 slave로 생성 합니다
az cosmosdb create -n $accountName -g $resourceGroup --default-consistency-level Eventual `
--locations regionName=koreacentral failoverpriority=0 `
--locations regionName=koreasouth failoverpriority=1
```

### 02. 데이터 마이그레이션
생성된 cosmosdb account에 샘플 데이터를 삽입 합니다  
이때 CosmosDB Migration 도구를 사용하며 [관련 링크를 참고](https://docs.microsoft.com/ko-kr/azure/cosmos-db/import-data) 해주세요  
Handson에서는 VolcanoData라는 Sample data를 다운로드 dt 라는 도구를 다운받고 설치하여 json 파일을 cosmosdb로 업로드 합니다  

```powershell
# 샘플 데이터 다운로드
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-cosmos-db-sample-data/blob/master/SampleData/VolcanoData.json" -OutFile C:\VolcanoData.json; 

# 마이그레이션 도구 다운로드 및 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://aka.ms/csdmtool" -OutFile .\dt.zip; 
Expand-Archive .\dt.zip -DestinationPath "C:\dt"

# 마이그레이션 실행
C:\dt\drop\dt.exe /s:JsonFile /s.Files:C:\VolcanoData.json /t:DocumentDBBulk /t.ConnectionString:"AccountEndpoint=<CosmosDB Endpoint>;AccountKey=<CosmosDB Key>;Database=<CosmosDB Database>;" /t.Collection:VolcanoData /t.CollectionThroughput:2500
```

### 03. 기본 쿼리 확인
이제 Azure portal에서 생성된 CosmosDB에 접속하여 데이터 탐색기를 클릭 합니다  
portal에서 아래와 같은 쿼리들을 실행해 볼 수 있습니다  

```sql
SELECT *
FROM c 
WHERE c.Country = 'Russia'

SELECT c.Country, c.Region
FROM c 
WHERE c.Country = 'Russia'

SELECT {"Name":c.Country, "Region":c.Region} as loc
FROM c 
WHERE c.Country = 'Russia'



SELECT c.Country,COUNT(1) as cnt 
FROM c 
GROUP BY c.Country

SELECT c.Type,AVG(c.Elevation),MIN(c.Elevation),MAX(c.Elevation)
FROM c 
GROUP BY c.Type
```

#### 04. Notebook 사용
[Notebook download (Random Generate)](NoteBooks/Notebooks_SQL01.ipynb)

위 링크를 우클릭 후 로컬에 다운로드 합니다  
CosmosDB -> 데이터탐색기 -> My Notebooks -> Upload File을 차례로 클릭 후 업로드를 진행 합니다  

혹은 [Notebook sample (Random Generate)](NoteBooks/Notebooks_SQL01.md) 를 사용하여 Notebook을 새로 생성하여 테스트를 진행 합니다  


#### 05. Azure Functions와 연동 (Change feed)
[Azure Functions Trigger HandsOn](APIs/FunctionsTrigger.md)