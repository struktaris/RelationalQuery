public protocol SQLConvertible {
    var sql: String { get }
}

extension RelationalField: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .field(name: let name):
            name.asSQLName
        case .renamingField(name: let name, to: let newName):
            name.asSQLName + " AS " + newName.asSQLName
        }
    }
    
}

extension RelationalQueryOrderDirection: SQLConvertible {

    public var sql: String {
        switch self {
            case .ascending:
            "ASC"
            case .descending:
            "DESC"
        }
    }
    
}

extension RelationalQueryResultOrder: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .field(let name):
            name.asSQLName
        case .fieldWithDirection(let name, let direction):
            "\(name.asSQLName) \(direction.sql)"
        }
    }
    
}

extension RelationalQueryCondition: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .equalText(field: let field, value: let value):
            "\(field.asSQLName)=\(value.asSQLText)"
        case .equalInteger(field: let field, value: let value):
            "\(field.asSQLName)=\(value)"
        case .smallerInteger(field: let field, than: let value):
            "\(field.asSQLName)<\(value)"
        case .smallerOrEqualInteger(field: let field, than: let value):
            "\(field.asSQLName)<=\(value)"
        case .greaterInteger(field: let field, than: let value):
            "\(field.asSQLName)>\(value)"
        case .greaterOrEqualInteger(field: let field, than: let value):
            "\(field.asSQLName)>=\(value)"
        case .equalBoolean(field: let field, value: let value):
            "\(field.asSQLName)=\(value)"
        case .similarText(field: let field, template: let template, wildcard: let wildcard):
            field.asSQLName + " LIKE " + template.replacing(wildcard, with: "%").asSQLText
        case .not(let condition):
            "NOT \(condition.sql)"
        case .and(let conditions):
            "(" + conditions.map{ $0.sql }.joined(separator: " AND ") + ")"
        case .or(let conditions):
            "(" + conditions.map{ $0.sql }.joined(separator: " OR ") + ")"
        }
    }
    
}

extension RelationalQuery: SQLConvertible {
    
    public var sql: String {
        var result = "SELECT \(fields?.map{ $0.sql }.joined(separator: ",") ?? "*") FROM \(table.asSQLName)"
        if let condition {
            result += " WHERE " + condition.sql
        }
        if let order {
            result += " ORDER BY " + order.map{ $0.sql }.joined(separator: ",")
        }
        return result
    }
    
}
