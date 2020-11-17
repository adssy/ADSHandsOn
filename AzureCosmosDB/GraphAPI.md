## 제품 추가
```graph
g.addV('Product').property('id', 'p1').property('name', 'Phone Charger').property('price', 12.99)
g.addV('Product').property('id', 'p2').property('name', 'USB C Cable Charger').property('price', 8.99)
g.addV('Product').property('id', 'p3').property('name', 'Gardening Gloves').property('price', 2.99)
```

## 버텍스 추가
```graph
g.addV('Category').property('id', 'c1').property('name', 'Mobile Phones')
g.addV('Category').property('id', 'c2').property('name', 'Gardening')
```

## 엣지 추가
```graph
g.V('p1').addE('belongsto').to(g.V('c1'))
g.V('p2').addE('belongsto').to(g.V('c1'))
g.V('p3').addE('belongsto').to(g.V('c2'))
```


g.V().count()
g.E().count()

g.V().hasLabel('Category')
g.V().hasLabel('Product').has('id','p1')
g.V().hasLabel('Category').values('name')
g.V().hasLabel('Product').values('name','price')
g.V().hasLabel('Product').order().by('name', incr).values('name','price')
g.V().hasLabel('Product').order().by('price', decr).values('name','price')


//update
g.V('p1').property('price', 15.99)

//Add groups (vertices)
g.addV('group').property('pk', 'pk').property('id', 'Microsoft').property('name', 'Microsoft')
g.addV('group').property('pk', 'pk').property('id', 'Azure').property('name', 'Azure')
g.addV('group').property('pk', 'pk').property('id', 'Sales').property('name', 'Sales')
g.addV('group').property('pk', 'pk').property('id', 'Engineering').property('name', 'Engineering')

//Add People (vertices)
g.addV('person').property('pk', 'pk').property('id', 'Rimma N.').property('name', 'Rimma N.')
g.addV('person').property('pk', 'pk').property('id', 'Andrew L.').property('name', 'Andrew L.')
g.addV('person').property('pk', 'pk').property('id', 'Luis B.').property('name', 'Luis B.')
g.addV('person').property('pk', 'pk').property('id', 'New Person.').property('name', 'New Person.')

//add group memberships (edges)
g.V('Microsoft').addE('subgroup').to(g.V('Azure'))
g.V('Azure').addE('subgroup').to(g.V('Sales'))
g.V('Azure').addE('subgroup').to(g.V('Engineering'))
g.V('Engineering').addE('member').to(g.V('Rimma N.'))
g.V('Engineering').addE('member').to(g.V('Andrew L.'))
g.V('Engineering').addE('member').to(g.V('New Person.'))
g.V('Sales').addE('member').to(g.V('Luis B.'))
g.V('Sales').addE('member').to(g.V('Andrew L.'))

//add reporting hierarchies (edges)
g.V('Rimma N.').addE('directReports').to(g.V('Andrew L.'))
g.V('Rimma N.').addE('directReports').to(g.V('Luis B.'))
g.V('Rimma N.').addE('directReports').to(g.V('New Person.'))