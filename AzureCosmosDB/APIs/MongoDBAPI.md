# MongoDB APIs
## MongoDB to Azure Cosmos DB Mongo API
Azure Cosmos DB Mongo API는 최소한의 변경으로 기존 사용하던 MongoDB 환경을 마이그레이션할 수 있습니다  
HandsOn은 다음과 같은 단계로 진행 됩니다  

- Azure Cosmos DB Mongo API 배포
- mongodump 파일을 Azure CosmosDB에 import
- mongodb의 gui tool인 robo 3t를 사용하여 접속 테스트
- 기존 mongodb 쿼리 테스트 수행
- 인덱스 추가


## 리소스 생성 

```powershell
리소스그룹 : 영문약자-rg (sykim-rg)
계정이름 : 영문약자-sql (sykim-mongo)
API : Azure Cosmos DB for MongoDB API
Nobooks : 켜기
위치 : 동남아시아 (southeast asia)
용량모드 : 프로비저닝된 처리량
```

robo 3t를 설치 합니다  
```powershell
# Robo 3T 설치
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://download-test.robomongo.org/windows/robo3t-1.3.1-windows-x86_64-7419c406.zip" -OutFile .\robo3t.zip; 
Expand-Archive .\robo3t.zip -DestinationPath "C:\Robo3t"
```

robo 3t를 실행 하여 mongodb query로 데이터베이스 및 컬렉션을 생성 합니다  

```c#
// azcosmostest 라는 데이터베이스를 생성 합니다  
use azcosmostest
db.runCommand({customAction: "CreateDatabase"});

// restaurants 라는 컬렉션을 10000 RU 로 생성 합니다  
use azcosmostest
db.runCommand({customAction: "CreateCollection", collection: "restaurants", offerThroughput: 10000});
// 생성된 컬렉션 확인
db.runCommand({customAction:'getCollection',collection:'restaurants'})
```

테스트 파일을 다운로드 및 cosmosdb에 삽입 합니다  
cosmoshost, password는 azure portal에서 연결 문자열에서 확인 가능 합니다  
관리자 권한으로 powershell 실행 후 아래 커맨드를 실행 합니다  
``` powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mongodb/docs-assets/primer-dataset/primer-dataset.json" -OutFile C:\restaurants.json; 

# mongoimport를 다운로드 합니다
Invoke-WebRequest -Uri "https://azmyhanson.blob.core.windows.net/azcon/mongoimport.exe" -OutFile c:\mongoimport.exe; 

c:\mongoimport.exe -h {cosmoshost}.mongo.cosmos.azure.com:10255 -d azcosmostest -c restaurants -u {user_name} -p {password} --ssl --file c:\restaurants.json
```


## MongoDB Query Test
이제 몇 가지의 쿼리를 테스트 해볼 수 있습니다 robo 3t에서 쿼리 합니다  

```c#
// name field가 존재하고 field값이 공백이 아닌 document를 조회
db.restaurants.find({name:{"$exists":true, $ne:""}})

// 특정 쿼리의 소비 RU를 확인하고 싶다면 쿼리 이후 아래의 커맨드로 소모한 RU를 확인할 수 있습니다
db.runCommand({'getLastRequestStatistics':1})

// cuisine field값이 'American' 인 document를 조회
db.restaurants.find({"cuisine":"American"})
db.runCommand({'getLastRequestStatistics':1})

// cuisine field값에 'Bagels' 문자열이 포함된 document를 조회
db.restaurants.find({cuisine:/Bagels/})
db.runCommand({'getLastRequestStatistics':1})

// borough field값에 대한 중복제거
db.restaurants.distinct("borough")
db.runCommand({'getLastRequestStatistics':1})

// address document field에 포함된 child document field 값이 일치하는 document를 조회
db.restaurants.find({"address.zipcode":"11224", "address.building":"2780"})
db.runCommand({'getLastRequestStatistics':1})

// grades document field에 포함된 child array에 포함된 document의 grade field값중 'A' 를 포함하는 document를 조회
db.restaurants.find({"grades.grade":"A"})
db.runCommand({'getLastRequestStatistics':1})

//위 쿼리 결과 (grades.grade = A) cuisine 별로 카운트, 많은 수대로 정렬
db.restaurants.aggregate([
    { $match: {"grades.grade":"A"}},
    { $group: { _id: "$cuisine", total: { $sum: 1 } } },
    { $sort: { total: -1 } }
])
db.runCommand({'getLastRequestStatistics':1})

db.restaurants.find({"cuisine":"American"}).sort({name:1})

```

마지막 쿼리는 sort에서 error가 발생 합니다  
원인은 index가 추가되지 않은 속성에 대해 sort 연산을 지원하지 않기에 발생하는 오류로 인덱스 추가 후 동일 쿼리를 실행해 봅니다  

``` c#
db.restaurants.createIndex({name:1})
db.restaurants.find({"cuisine":"American"}).sort({name:1})
```


다른 제약들은 아래 링크에서 참조 합니다  
https://docs.microsoft.com/ko-kr/azure/cosmos-db/mongodb-feature-support-36  