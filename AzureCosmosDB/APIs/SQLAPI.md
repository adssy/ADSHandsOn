# SQL APIs
Azure CosmosDB는 SQL API가 Core 엔진으로 구동 됩니다  
HandsOn은 다음과 같은 단계로 진행 됩니다  

- Azure Cosmos DB SQL API 배포
- dt 를 사용하여 데이터 마이그레이션 (json 및 mongodump) 테스트
- SQL 쿼리 테스트
- 인덱스 추가
- Notebook을 사용하여 대화형 코드 적용
- Change feed를 통한 데이터 흐름 확인

## 01. Azure CosmosDB Account 생성
아래 정보를 참고하여 Azure Cosmosdb Account를 생성 합니다
```powershell
리소스그룹 : 영문약자-rg (sykim-rg)
계정이름 : 영문약자-sql (sykim-sql)
API : 코어(SQL)
Nobooks : 켜기
위치 : 동남아시아 (southeast asia)
용량모드 : 프로비저닝된 처리량

```

## 02. 데이터 마이그레이션
생성된 cosmosdb account에 샘플 데이터를 삽입 합니다  
이때 CosmosDB Migration 도구를 사용하며 [관련 링크를 참고](https://docs.microsoft.com/ko-kr/azure/cosmos-db/import-data) 해주세요  
Handson에서는 VolcanoData라는 Sample data를 다운로드 dt 라는 도구를 다운받고 설치하여 json 파일을 cosmosdb로 업로드 합니다  

```powershell
# 샘플 데이터 다운로드
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://sampledatasa.blob.core.windows.net/sampledata/sample3.json" -OutFile C:\VolcanoData.json; 

# 마이그레이션 도구 다운로드 및 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://aka.ms/csdmtool" -OutFile .\dt.zip; 
Expand-Archive .\dt.zip -DestinationPath "C:\dt"

# 마이그레이션 실행
C:\dt\drop\dt.exe /s:JsonFile /s.Files:C:\VolcanoData.json /t:DocumentDBBulk /t.ConnectionString:"AccountEndpoint=<CosmosDB Endpoint>;AccountKey=<CosmosDB Key>;Database=<CosmosDB Database>;" /t.Collection:VolcanoData /t.CollectionThroughput:2500
```

## 03. 기본 쿼리 확인
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

## 04. 인덱스
SQL API는 기본으로 자동 인덱스가 적용되어 있습니다  
Scale & Settings -> Indexing Policy를 확인하면 아래와 같은 경로가 기본 정책입니다  
``` json
{
    "indexingMode": "consistent",  
    "automatic": true,
    "includedPaths": [
        {
            "path": "/*"
        }
    ],
    "excludedPaths": [
        {
            "path": "/\"_etag\"/?"
        }
    ]
}
```
- indexingMode : {consistent , none, lazy}  
consistent : 생성/업데이트/삭제 등 변경 작업 발생 시 동기적으로 인덱스가 업데이트 됩니다  
none : 인덱스를 사용하지 않습니다 보조 인덱스가 없이 Partition key로만 조회 하는 Key-value store Collection의 경우 사용 됩니다  
lazy : 지연된 인덱스 모드이며 동기적으로 업데이트 되지 않고 낮은 우선 순위로 인덱스 업데이트가 수행 됩니다 이로 인해 불일치 또는 불완전 쿼리가 발생할 수 있습니다  
일반적인 OLTP 환경에서는 consistent, 추가적인 인덱스가 필요 없다면 none, 추가 인덱스가 필요하지만 즉각적인 데이터가 필요하지 않은 환경이라면 lazy로 선택 합니다  
- automatic : {true, false}  
Azure Cosmos DB의 자동 인덱스 기능 사용 여부  
- includedPaths , excludedPaths: {/? , /[], /*}  
인덱스를 추가하거나 제외할 내용을 명시 합니다  
```json
{
        "locations": [
            { "country": "Germany", "city": "Berlin" },
            { "country": "France", "city": "Paris" }
        ],
        "headquarters": { "country": "Belgium", "employees": 250 }
        "exports": [
            { "city": "Moscow" },
            { "city": "Athens" }
        ]
    }
```
위 예제 json에서 정책을 살펴 봅니다  
headquarters의 employees 경로 : /headquarters/employees/?  
? 경로는 해당 속성만 인덱스 추가 합니다

locations' country 경로 : /locations/[]/country/?  
[] 경로는 배열 경로 내의 속성을 추가할 때 사용 됩니다  

headquarters의 하위 모든 항목에 대한 경로 : /headquarters/*  
* 경로는 하위 항목에 대해 모든 속성을 인덱스로 추가할 때 사용 됩니다  

## 05. Notebook 사용
[Notebook sample (Random Generate)](Data/Notebooks_SQL01.md) 를 사용하여 Notebook을 생성하여 테스트를 진행 합니다  
[Notebook Upload ](Data/Notebooks_SQL02.md) 를 사용하여 json 파일을 업로드 하는 방법을 알아 봅니다  

## 06. Azure Functions와 연동 (Change feed)
[Azure Functions Trigger HandsOn](FunctionsTrigger.md)