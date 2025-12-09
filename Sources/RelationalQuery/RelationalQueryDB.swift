import Foundation

public enum RelationalQueryDBDataType {
    case TEXT
    case INTEGER
    case BOOLEAN
}

public enum RelationalQueryDBValue: CustomStringConvertible, Decodable {
    case text(value: String)
    case integer(value: Int)
    case boolean(value: Bool)
    
    public var description: String {
        switch self {
        case .text(value: let value): value
        case .integer(value: let value): value.description
        case .boolean(value: let value): value.description
        }
    }
}

public typealias RelationalQueryDBFieldDefinitions = [(String,RelationalQueryDBDataType)]
public typealias RelationalQueryDBRow = [String:RelationalQueryDBValue]
public typealias RelationalQueryDBTable = (RelationalQueryDBFieldDefinitions,[RelationalQueryDBRow])
public typealias RelationalQueryDatabase = [String:RelationalQueryDBTable]
public typealias RelationalQueryDBResultRow = [String:RelationalQueryDBValue]

public struct RelationalQueryDBResult: CustomStringConvertible {
    public let fields: [String]
    public let rows: [RelationalQueryDBResultRow]
    public let displayedColumnWith: [String:Int]
    
    public init(fields: [String], withRows rows: [RelationalQueryDBResultRow] = [RelationalQueryDBResultRow]()) {
        self.fields = fields
        self.rows = rows
        var displayedColumnWith = [String:Int]()
        for field in fields {
            displayedColumnWith[field] = field.count
            for row in rows {
                if let length = row[field]?.description.count, length > displayedColumnWith[field] ?? 0 {
                    displayedColumnWith[field] = length
                }
            }
        }
        self.displayedColumnWith = displayedColumnWith
    }
    
    public var description: String {
        
        func extending(_ s: String, toLength length: Int) -> String {
            let diff = length - s.count
            if diff <= 0 {
                return s
            } else {
                return s + String(repeating: " ", count: diff)
            }
        }
        
        var lines = [String]()
        lines.append(fields.map{ extending($0, toLength: displayedColumnWith[$0] ?? 0) }.joined(separator: " | "))
        lines.append(fields.map{ String(repeating: "-", count: (displayedColumnWith[$0] ?? 0)) }.joined(separator: "-|-"))
        for row in rows {
            lines.append(fields.map{ extending(row[$0]?.description ?? "", toLength: displayedColumnWith[$0] ?? 0) }.joined(separator: " | "))
        }
        return lines.joined(separator: "\n")
    }
}

public extension RelationalQueryCondition {
    
    func check(row: RelationalQueryDBRow) -> Bool {
        switch self {
        case .equalText(field: let field, value: let value):
            guard case .text(let text) = row[field] else { return false}
            return text == value
        case .equalInteger(field: let field, value: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text == value
        case .smallerInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text < value
        case .smallerOrEqualInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text <= value
        case .greaterInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text > value
        case .greaterOrEqualInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text >= value
        case .equalBoolean(field: let field, value: let value):
            guard case .boolean(let text) = row[field] else { return false}
            return text == value
        case .similarText(field: let field, template: let template, wildcard: let wildcard):
            do {
                guard case .text(let text) = row[field] else { return false}
                let regex = try Regex("^\(template.replacing(wildcard, with: ".*"))$")
                return text.contains(regex)
            } catch {
                return false
            }
        case .not(let condition):
            return !condition.check(row: row)
        case .and(let conditions):
            for condition in conditions {
                if !condition.check(row: row) {
                    return false
                }
            }
            return true
        case .or(let conditions):
            for condition in conditions {
                if condition.check(row: row) {
                    return true
                }
            }
            return false
        }
    }
    
}

public extension RelationalQueryResultOrder {
    
    func compare(_ row1: RelationalQueryDBRow, with row2: RelationalQueryDBRow) -> Int {
        var value1: String? = nil
        var value2: String? = nil
        let orderFactor: Int
        switch self {
        case .field(let name):
            if case .text(let text) = row1[name] { value1 = text }
            if case .text(let text) = row2[name] { value2 = text }
            orderFactor = 1
        case .fieldWithDirection(let name, let direction):
            if case .text(let text) = row1[name] { value1 = text }
            if case .text(let text) = row2[name] { value2 = text }
            orderFactor = switch direction {
            case .ascending: 1
            case .descending: -1
            }
        }
        guard let value1, let value2 else { return 0 }
        if value1 == value2 {
            return 0
        } else if value1 < value2 {
            return -orderFactor
        } else {
            return orderFactor
        }
    }
    
}

public extension RelationalQuery {
    
    func execute(forRelationalQueryDatabase testDB: RelationalQueryDatabase) -> RelationalQueryDBResult {
        guard let (originalFieldNames,allRows) = testDB[self.table] else { return RelationalQueryDBResult(fields: [String]()) }
        var filteredAndSorted: [RelationalQueryDBRow]
        if let condition = self.condition {
            filteredAndSorted = allRows.filter { condition.check(row: $0) }
        } else {
            filteredAndSorted = allRows
        }
        if let order = self.order {
            filteredAndSorted.sort { row1, row2 in
                return order.lazy.map { $0.compare(row1, with: row2) }.filter{ $0 != 0 }.first != 1
            }
        }
        var result = [RelationalQueryDBResultRow]()
        let fieldNames: [String]
        if let fields {
            do {
                var newFieldNames = [String]()
                for field in fields {
                    switch field {
                    case .field(let name):
                        newFieldNames.append(name)
                    case .renamingField(_, to: let newName):
                        newFieldNames.append(newName)
                    }
                }
                fieldNames = newFieldNames
            }
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryDBResultRow()
                for field in fields {
                    switch field {
                    case .field(let name):
                        newRow[name] = originalRow[name]
                    case .renamingField(name: let name, to: let newName):
                        newRow[newName] = originalRow[name]
                    }
                }
                result.append(newRow)
            }
        } else {
            fieldNames = originalFieldNames.map { $0.0 }
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryDBResultRow()
                for fieldName in fieldNames {
                    if let value = originalRow[fieldName] {
                        newRow[fieldName] = value
                    }
                }
                result.append(newRow)
            } 
        }
        return RelationalQueryDBResult(fields: fieldNames, withRows: result)
    }
    
}

public func relationalQueryTable(
    withFields fieldsDefinitions: RelationalQueryDBFieldDefinitions,
    withContentFromValues genericRows: [[String:Any]]? = nil
) throws -> RelationalQueryDBTable {
    guard let genericRows else { return RelationalQueryDBTable(fieldsDefinitions: fieldsDefinitions, rows: []) }
    let booleanFields = fieldsDefinitions.filter{ $0.1 == .BOOLEAN }.map{ $0.0 }
    var rows = [RelationalQueryDBRow]()
    for genericRow in genericRows {
        var row = RelationalQueryDBRow()
        for (key,value) in genericRow {
            if let text = value as? String { row[key] = .text(value: text) }
            else if let int = value as? Int {
                if booleanFields.contains(key) {
                    row[key] = .boolean(value: int != 0)
                } else {
                    row[key] = .integer(value: int)
                }
            }
            else if let bool = value as? Bool { row[key] = .boolean(value: bool) }
            else { throw RelationalQueryError("invalid value: \(value)") }
        }
        rows.append(row)
    }
    return (fieldsDefinitions, rows)
}

public func relationalQueryTable(
    withFields fieldsDefinitions: RelationalQueryDBFieldDefinitions,
    withContentFromJSONText jsonText: String? = nil
) throws -> RelationalQueryDBTable {
    guard let jsonText else { return RelationalQueryDBTable(fieldsDefinitions: fieldsDefinitions, rows: []) }
    guard let jsonData = jsonText.data(using: .utf8) else { throw RelationalQueryError("could not convert JSON string to Data") }
    let json = try JSONSerialization.jsonObject(with: jsonData)
    return try relationalQueryTable(withFields: fieldsDefinitions, withContentFromParsedJSON: json)
}

public func relationalQueryTable(
    withFields fieldsDefinitions: RelationalQueryDBFieldDefinitions,
    withContentFromParsedJSON json: Any? = nil
) throws -> RelationalQueryDBTable {
    guard let genericRows = json as? [[String: Any]] else { throw RelationalQueryError("JSON has wrong structure") }
    return try relationalQueryTable(withFields: fieldsDefinitions,     withContentFromValues: genericRows)
}
