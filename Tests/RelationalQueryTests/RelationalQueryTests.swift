import Foundation
import Foundation
import XCTest
@testable import RelationalQuery

final class RelationalQueryTests: XCTestCase {
    
    func testQueryConstructionAndJSON() throws {
        
        let checkSurnameEndForD = true
        
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
        
        let asJSON = try JSONEncoder().encode(query)
        
        if let json = try? JSONSerialization.jsonObject(with: asJSON, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
            XCTAssertEqual(String(data: jsonData, encoding: .utf8)!, """
                {
                  "condition" : {
                    "or" : {
                      "conditions" : [
                        {
                          "equalText" : {
                            "field" : "prename",
                            "value" : "Bert"
                          }
                        },
                        {
                          "similarText" : {
                            "field" : "prename",
                            "template" : "C*",
                            "wildcard" : "*"
                          }
                        },
                        {
                          "and" : {
                            "conditions" : [
                              {
                                "not" : {
                                  "condition" : {
                                    "similarText" : {
                                      "field" : "name",
                                      "template" : "D*",
                                      "wildcard" : "*"
                                    }
                                  }
                                }
                              },
                              {
                                "similarText" : {
                                  "field" : "name",
                                  "template" : "*n",
                                  "wildcard" : "*"
                                }
                              },
                              {
                                "equalText" : {
                                  "field" : "prename",
                                  "value" : "Ernie"
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  "fields" : [
                    {
                      "renamingField" : {
                        "name" : "name",
                        "to" : "surname"
                      }
                    },
                    {
                      "field" : {
                        "name" : "prename"
                      }
                    }
                  ],
                  "order" : [
                    {
                      "field" : {
                        "name" : "name"
                      }
                    },
                    {
                      "fieldWithDirection" : {
                        "direction" : {
                          "descending" : {

                          }
                        },
                        "name" : "prename"
                      }
                    }
                  ],
                  "table" : "person"
                }
                """)
        }
        
        XCTAssertEqual(
            query.sql,
            #"SELECT name AS surname,prename FROM person WHERE (prename='Bert' OR prename LIKE 'C%' OR (NOT name LIKE 'D%' AND name LIKE '%n' AND prename='Ernie')) ORDER BY name,prename DESC"#
        )
        
        XCTAssertEqual(
            query.postgrest,
            #"person?select=surname:name,prename&or=(prename.eq.Bert,prename.like.C*,and(not.name.like.D*,name.like.*n,prename.eq.Ernie))&order=name,prename.desc"#
        )
    }
    
    func testQueryTestRowCompare() throws {
        
        let row1: RelationalQueryDBRow = ["prename": .text(value: "Wallace"), "name": .text(value: "Portillo")]
        let row2: RelationalQueryDBRow = ["prename": .text(value: "Gwen"), "name": .text(value: "Todd")]
        
        // sorting along "name":
        XCTAssertEqual(RelationalQueryResultOrder.field(name: "prename").compare(row1, with: row2), 1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection(name: "prename", direction: .ascending).compare(row1, with: row2), 1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection(name: "prename", direction: .descending).compare(row1, with: row2), -1)
        
        // sorting along "prename":
        XCTAssertEqual(RelationalQueryResultOrder.field(name: "name").compare(row1, with: row2), -1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection(name: "name", direction: .ascending).compare(row1, with: row2), -1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection(name: "name", direction: .descending).compare(row1, with: row2), 1)
    }
    
    func testQueryTest() throws {
        
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
        
        do {
            let query = RelationalQuery(
                table: "person",
                fields: [
                    .renamingField(name: "name", to: "surname"),
                    .field(name: "prename"),
                    .field(name: "age"),
                    .field(name: "member")
                ],
                condition: one {
                    compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
                    compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
                },
                orderBy: [.field(name: "name"), .fieldWithDirection(name: "prename", direction: .descending)]
            )
            
            XCTAssertEqual(query.sql, """
                SELECT name AS surname,prename,age,member FROM person WHERE (prename LIKE '%o%' OR name LIKE '%o%') ORDER BY name,prename DESC
                """)
            
            let result = query.execute(forRelationalQueryDatabase: testDB)
            
            XCTAssertEqual(
                result.description,
            """
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
            """
            )
        }
        
        do {
            let query = RelationalQuery(
                table: "person",
                fields: [
                    .renamingField(name: "name", to: "surname"),
                    .field(name: "prename"),
                    .field(name: "age"),
                    .field(name: "member")
                ],
                condition: all {
                    compare(textField: "name", withValue: "Portillo")
                    compare(textField: "prename", withTemplate: "%", usingWildcard: "%")
                },
                orderBy: [.field(name: "name"), .fieldWithDirection(name: "prename", direction: .descending)]
            )
            
            XCTAssertEqual(query.sql, """
                SELECT name AS surname,prename,age,member FROM person WHERE (name='Portillo' AND prename LIKE '%') ORDER BY name,prename DESC
                """)
            
            let result = query.execute(forRelationalQueryDatabase: testDB)
            
            XCTAssertEqual(
                result.description,
            """
            surname  | prename  | age | member
            ---------|----------|-----|-------
            Portillo | Kaydence | 30  | false 
            Portillo | Gwen     | 45  | false 
            """
            )
        }
        
    }
    
    func testQueryTestWithJSON() throws {
        
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
        
        let query = RelationalQuery(
            table: "person",
            fields: [
                .renamingField(name: "name", to: "surname"),
                .field(name: "prename"),
                .field(name: "age"),
                .field(name: "member")
            ],
            condition: one {
                compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
                compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
            },
            orderBy: [.field(name: "name"), .fieldWithDirection(name: "prename", direction: .descending)]
        )
        
        let result = query.execute(forRelationalQueryDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
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
            """
        )
    }
    
    
    func testQueryWithoutFieldList() throws {
        
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
        
        // no fields are listed -> take all fields in the order from the table definition:
        let query = RelationalQuery(
            table: "person",
            condition: one {
                compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
                compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
            },
            orderBy: [.field(name: "name"), .fieldWithDirection(name: "prename", direction: .descending)]
        )
        
        let result = query.execute(forRelationalQueryDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
            prename  | name      | age | member
            ---------|-----------|-----|-------
            Atticus  | Allison   | 47  | true  
            Atticus  | Allison   | 50  | true  
            Edison   | Beltran   | 49  | false 
            Taylor   | Hodges    | 21  | false 
            Emma     | Hodges    | 55  | false 
            Marleigh | Holland   | 40  | true  
            Ahmad    | Johnson   | 26  | true  
            Loretta  | Mejia     | 51  | false 
            Kaydence | Portillo  | 30  | false 
            Gwen     | Portillo  | 45  | false 
            Loretta  | Schneider | 23  | false 
            Wallace  | Todd      | 27  | false 
            """
        )
    }
    
}
