Azure CosmosDB에서 Container를 추가 합니다  
- Database id : 기존 데이터베이스 선택 (현 문서 기준 AzTestDB)
- Container id : VolcanoData
- Partition Key : /id
- Throughput : 400 

My Notebooks에서 새로운 노트북을 추가하고 아래 쿼리를 수행 합니다 (C#)
``` c#
%%upload --databaseName "AzTestDB" --containerName "VolcanoData" --url "https://sampledatasa.blob.core.windows.net/sampledata/sample3.json"
```