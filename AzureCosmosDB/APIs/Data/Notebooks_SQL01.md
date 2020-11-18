My Notebooks에서 새로운 노트북을 추가 하고 아래 항목들을 복사하여 넣습니다 (C#)  


``` c#
#r "nuget: Bogus"
#r "nuget: System.Linq"
#r "nuget: System.Linq.Expressions"
```

``` c#
using System;
using Microsoft.Azure.Cosmos;
using System.Collections;
using Bogus;

// Initialize a new instance of CosmosClient using the built-in account endpoint and key parameters
CosmosClient cosmosClient = new CosmosClient(Cosmos.Endpoint, Cosmos.Key);

// Create a new database and a new container
Microsoft.Azure.Cosmos.Database database = await cosmosClient.CreateDatabaseIfNotExistsAsync("AzTestDB");
Container container = await database.CreateContainerIfNotExistsAsync("User", "/UserId");

Display.AsMarkdown(@"
Created database AzTestDB and container User. You can see these new resources by refreshing your resource pane under the Data section.
");

```

``` c#
using System;
using Bogus;


public class User
{
    public User(string userId, string ssn)
    {
        this.UserId = userId;
        this.SSN = ssn;
    }
    public Guid id { get; set; } = Guid.NewGuid();
    public string UserId { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string FullName { get; set; }
    public string Email { get; set; }
    public string Address { get; set; }
    public string PhoneNumber { get; set; }
    public string IPAddress { get; set; }
    public Guid CartId { get; set; }
    public string SSN { get; set; }
    public Gender Gender { get; set; }
}

public enum Gender
{
    Male,
    Female
}
```

``` c#
using Bogus;
using System;
using System.Collections.Generic;

static List<User> Generate(int num)
{
    var faker = new Faker();

    var userIds = 0;
    var testUsers = new Faker<User>()
        .CustomInstantiator(f => new User(userIds++.ToString(), f.Random.Replace("######-#######")))
        .RuleFor(u => u.FirstName, f => faker.Name.FirstName())
        .RuleFor(u => u.LastName, f => faker.Name.LastName())
        .RuleFor(u => u.IPAddress, f => faker.Internet.Ip())
        .RuleFor(u => u.Email, (f, u) => faker.Internet.Email())
        .RuleFor(u => u.Address, f => faker.Address.CountryCode().OrDefine(f,.8f))
        .RuleFor(u => u.PhoneNumber, f => faker.Phone.PhoneNumber())
        .RuleFor(u => u.Gender, f => f.PickRandom<Gender>())
        .RuleFor(u => u.CartId, f => Guid.NewGuid())
        .RuleFor(u => u.FullName, (f, u) => u.FirstName + " " + u.LastName);

    var result = testUsers.Generate(num);

    return result;
}
public static object OrDefine(this object value, Faker f, float nullWeight)
{
    return f.Random.Float() < nullWeight ? "KR" : value;
}

```

``` c#
foreach(var user in Generate(1000))
{
    await container.CreateItemAsync<User>(user);
}

Display.AsMarkdown(@"
Created 1000 items in User container. 
");

```


``` c#
QueryDefinition queryDefinition = new QueryDefinition("SELECT TOP 100 * FROM c");

FeedIterator<User> queryResultSetIterator = container.GetItemQueryIterator<User>(queryDefinition);

List<User> userEvents = new List<User>();

while (queryResultSetIterator.HasMoreResults)
{
    FeedResponse<User> currentResultSet = await queryResultSetIterator.ReadNextAsync();
    foreach (User userEvent in currentResultSet)
    {
        userEvents.Add(userEvent);
    }
}

userEvents
```