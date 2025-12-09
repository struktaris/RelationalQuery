# RelationalQuery

This library allows to construct relational database queries of a simple form in an abstract way with output to various formats, and for the same abstractly defined queries to formulate tests in a simple way without using a "real" database.

This library is published under the Apache License v2.0 with Runtime Library Exception.

## Abstract queries

Example:

```swift
let query = RelationalQuery(
    table: "person",
    fields: [.renamingField(name: "name", to: "surname"), .field(name: "prename")],
    condition: one {
        compare(textField: "prename", withValue: "Bert")
        compare(textField: "prename", withTemplate: "C*", usingWildcard: "*")
        all {
            notOne {
                compare(textField: "name", withPotentialTemplate: "D*", usingWildcard: "*")
            }
            if checkSurnameEndForD {
                compare(textField: "name", withPotentialTemplate: "*n", usingWildcard: "*")
            }
            compare(textField: "prename", withPotentialTemplate: "Ernie", usingWildcard: "*")
        }
    },
    orderBy: [.field(name: "name"), .fieldWithDirection(name: "prename", direction: .descending)]
)

print("SQL:\n")
print(query.sql)

print("\nPostgREST:\n")
print(query.postgrest)
```

Do not use the “fields:” argument if you want the fields in the result to be just as they are defined for the database table. In the condition, `one` means “at least _one_ of the contained conditions must be true”, `all` means “_all_ of the contained conditions must be true”.

Result:

```text
SQL:
SELECT "name" AS "surname","prename" FROM "person" WHERE ("prename"='Bert' OR "prename" LIKE 'C%' OR ("name" LIKE 'D%' AND "name" LIKE '%n' AND "prename"='Ernie')) ORDER BY "name","prename" DESC

PostgREST:
person?select=surname:name,prename&or=(prename.eq.Bert,prename.like.C*,and(name.like.D*,name.like.*n,prename.eq.Ernie))&order=name,prename.desc"
```

New output formats can easily be added, see the extensions for `SQLConvertible` and `PostgRESTConvertible`.

## Testing a query

For testing a query, a simple database can be formulated as follows (for using JSON input see further below):

```swift
let testDB: RelationalQueryDatabase = [
    "person": try relationalQueryTable(
        withFields: [
            ("prename", .TEXT),
            ("name", .TEXT),
            ("age", .INTEGER),
            ("member", .BOOLEAN),
        ],
        withContentFromValues:
        [
            ["prename": "Gwen", "name": "Portillo", "age": 45, "member": false],
            ["prename": "Wallace", "name": "Todd", "age": 27, "member": false],
            ["prename": "Zariah", "name": "Curtis", "age": 63, "member": false],
            ["prename": "Muhammad", "name": "Avery", "age": 33, "member": true],
            ["prename": "Ahmad", "name": "Johnson", "age": 26, "member": true],
            ["prename": "Taylor", "name": "Hodges", "age": 21, "member": false],
            ["prename": "Emma", "name": "Hodges", "age": 55, "member": false],
            ["prename": "Kaydence", "name": "McClain", "age": 37, "member": false],
            ["prename": "Marleigh", "name": "Holland", "age": 40, "member": true],
            ["prename": "Brady", "name": "Brandt", "age": 34, "member": false],
            ["prename": "Loretta", "name": "Mejia", "age": 51, "member": false],
            ["prename": "Alayah", "name": "McGee", "age": 66, "member": false],
            ["prename": "Wallace", "name": "Weber", "age": 44, "member": true],
            ["prename": "Loretta", "name": "Schneider", "age": 23, "member": false],
            ["prename": "Alayah", "name": "McGee", "age": 23, "member": false],
            ["prename": "Atticus", "name": "Allison", "age": 50, "member": true],
            ["prename": "Edison", "name": "Beltran", "age": 49, "member": false],
            ["prename": "Atticus", "name": "Allison", "age": 47, "member": true],
            ["prename": "Kaydence", "name": "Portillo", "age": 30, "member": false],
        ]
    )
]
```

With e.g. the following abstract query:

```swift
let query = RelationalQuery(
    table: "person",
    fields: [
        .renaming("name", to: "surname"),
        .field("prename"),
        .field("age"),
        .field("member")
    ],
    condition: one {
        compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
        compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
    },
    orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
)
```

We can apply the query to our test database and print the result as follows:

```swift
let result = query.execute(forRelationalQueryDatabase: testDB)
print(result)
```

(In a unit test, compare `result.description` to the expected text.)

The following is printed:

```text
surname   | prename  | age | member
----------|----------|-----|-------
Allison   | Atticus  | 47  | true  
Allison   | Atticus  | 50  | true  
Beltran   | Edison   | 49  | false 
Hodges    | Taylor   | 21  | false 
Hodges    | Emma     | 55  | false 
Holland   | Marleigh | 40  | true  
Johnson   | Ahmad    | 26  | true  
Mejia     | Loretta  | 51  | false 
Portillo  | Kaydence | 30  | false 
Portillo  | Gwen     | 45  | false 
Schneider | Loretta  | 23  | false 
Todd      | Wallace  | 27  | false 
```

It might be convenient to use JSON for the rows, so you can write:

```swift
let testDB: RelationalQueryDatabase = [
    "person": try relationalQueryTable(
        withFields: [
            ("prename", .TEXT),
            ("name", .TEXT),
            ("age", .INTEGER),
            ("member", .BOOLEAN),
        ],
        withContentFromJSONText: #"""
        [
            {"prename": "Gwen", "name": "Portillo", "age": 45, "member": false},
            {"prename": "Wallace", "name": "Todd", "age": 27, "member": false}, 
            {"prename": "Zariah", "name": "Curtis", "age": 63, "member": false}, 
            {"prename": "Muhammad", "name": "Avery", "age": 33, "member": true}, 
            {"prename": "Ahmad", "name": "Johnson", "age": 26, "member": true}, 
            {"prename": "Taylor", "name": "Hodges", "age": 21, "member": false},
            {"prename": "Emma", "name": "Hodges", "age": 55, "member": false}, 
            {"prename": "Kaydence", "name": "McClain", "age": 37, "member": false}, 
            {"prename": "Marleigh", "name": "Holland", "age": 40, "member": true}, 
            {"prename": "Brady", "name": "Brandt", "age": 34, "member": false}, 
            {"prename": "Loretta", "name": "Mejia", "age": 51, "member": false}, 
            {"prename": "Alayah", "name": "McGee", "age": 66, "member": false}, 
            {"prename": "Wallace", "name": "Weber", "age": 44, "member": true}, 
            {"prename": "Loretta", "name": "Schneider", "age": 23, "member": false}, 
            {"prename": "Alayah", "name": "McGee", "age": 23, "member": false}, 
            {"prename": "Atticus", "name": "Allison", "age": 50, "member": true}, 
            {"prename": "Edison", "name": "Beltran", "age": 49, "member": false}, 
            {"prename": "Atticus", "name": "Allison", "age": 47, "member": true}, 
            {"prename": "Kaydence", "name": "Portillo", "age": 30, "member": false}
        ]
        """#
    )
]
```

You can use `relationalQueryTable(withFields:withContentFromParsedJSON:)` if the JSON has already been parsed or built by some other method.

---

**NOTE:**

If you mistakenly call `relationalQueryTable(withFields:withContentFromParsedJSON:)` with the JSON text to parse in the second argument, you will get the error “JSON has wrong structure”, then use `relationalQueryTable(withFields:withContentFromJSONText:)` instead.

---
