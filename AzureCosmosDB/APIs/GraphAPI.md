# Graph APIs
Azure Cosmos DB의 Gremlin API는 그래프 컴퓨팅 프레임워크인 Apache TinkerPop를 기반으로 빌드되었습니다  
HandsOn은 다음과 같은 단계로 진행 됩니다  

- Azure Cosmos DB Gremlin API 배포  
- 테스트 데이터 삽입  
- 간단한 쿼리 예제 실행  
- 기존 RDB SQL과 쿼리 비교  

## 리소스 생성

```powershell
리소스그룹 : 영문약자-rg (sykim-rg)
계정이름 : 영문약자-sql (sykim-graph)
API : Gremlin (그래프)
Nobooks : 켜기
위치 : 동남아시아 (southeast asia)
용량모드 : 프로비저닝된 처리량
```

## Add groups (vertices)

```graph
g.addV('group').property('pk', 'pk').property('id', 'Microsoft').property('name', 'Microsoft')
g.addV('group').property('pk', 'pk').property('id', 'Azure').property('name', 'Azure')
g.addV('group').property('pk', 'pk').property('id', 'Sales').property('name', 'Sales')
g.addV('group').property('pk', 'pk').property('id', 'Engineering').property('name', 'Engineering')
```

## Add People (vertices)

```graph
g.addV('person').property('pk', 'pk').property('id', 'Rimma N.').property('name', 'Rimma N.')
g.addV('person').property('pk', 'pk').property('id', 'Andrew L.').property('name', 'Andrew L.')
g.addV('person').property('pk', 'pk').property('id', 'Luis B.').property('name', 'Luis B.')
g.addV('person').property('pk', 'pk').property('id', 'New Person.').property('name', 'New Person.')
```

## Add group memberships (edges)

```graph
//add group memberships (edges)
g.V('Microsoft').addE('subgroup').to(g.V('Azure'))
g.V('Azure').addE('subgroup').to(g.V('Sales'))
g.V('Azure').addE('subgroup').to(g.V('Engineering'))
g.V('Engineering').addE('member').to(g.V('Rimma N.'))
g.V('Engineering').addE('member').to(g.V('Andrew L.'))
g.V('Engineering').addE('member').to(g.V('New Person.'))
g.V('Sales').addE('member').to(g.V('Luis B.'))
g.V('Sales').addE('member').to(g.V('Andrew L.'))
```

## Add reporting hierarchies (edges)

```graph
g.V('Rimma N.').addE('directReports').to(g.V('Andrew L.'))
g.V('Rimma N.').addE('directReports').to(g.V('Luis B.'))
g.V('Rimma N.').addE('directReports').to(g.V('New Person.'))
```

## 쿼리 테스트
기존 RDB 환경에서의 쿼리와 Graph DB로 변환 했을때의 쿼리를 비교 합니다  
RDB는 mysql로 작성되었으며 schema는 [RDB 스키마](Data/rdb_schema.sql) 을 참고 합니다  

#### GetAllGroupsUnderAzure
``` sql
SELECT sqlgraph.group.ID, sqlgraph.group.Name FROM sqlgraph.group
INNER JOIN sqlgraph.groups
ON GroupID = sqlgraph.group.ID
WHERE NestedGroupID = 
(SELECT ID FROM sqlgraph.group WHERE Name='Azure')
```

``` graph
g.V('Azure').out('subgroup')
```

#### GetAllGroupsUnderAzure
``` sql
SELECT sqlgraph.group.ID, sqlgraph.group.Name FROM sqlgraph.group
INNER JOIN sqlgraph.groups
ON GroupID = sqlgraph.group.ID
WHERE NestedGroupID = 
(SELECT ID FROM sqlgraph.group WHERE Name='Azure')
```

``` graph
g.V('Azure').out('subgroup')
```

#### GetEmployeesFromSales
``` sql
ELECT * FROM sqlgraph.Employee
INNER JOIN sqlgraph.employee_group ON sqlgraph.employee_group.employeeID = sqlgraph.Employee.ID 
INNER JOIN sqlgraph.Group ON sqlgraph.Employee_Group.GroupID = sqlgraph.Group.ID
WHERE sqlgraph.group.Name = 'Sales'
```

``` graph
g.V('Sales').out('member')
```

#### GetEngineeringManagers
``` sql
SELECT sqlgraph.employee.name FROM sqlgraph.employee
INNER JOIN sqlgraph.employee_group ON sqlgraph.employee_group.employeeID = sqlgraph.Employee.ID
INNER JOIN sqlgraph.Group ON sqlgraph.Employee_Group.GroupID = sqlgraph.Group.ID
INNER JOIN 
	(
	SELECT DISTINCT EmployeeID FROM sqlgraph.employee_reportEmployee 
	) as T
	ON T.EmployeeID = sqlgraph.Employee.ID
WHERE sqlgraph.group.Name = 'Engineering';
```

``` graph
g.V().has('name','Engineering').out('member').in('directReports').dedup().values('name')
```
