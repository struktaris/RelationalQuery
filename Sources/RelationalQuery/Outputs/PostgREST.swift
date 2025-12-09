// cf. https://docs.postgrest.org/en/v13/references/api/tables_views.html

public protocol PostgRESTConvertible {
    var postgrest: String { get }
}

extension RelationalField: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
        case .field(let name):
            name.urlEscaped
        case .renamingField(name: let name, to: let newName):
            newName.urlEscaped + ":" + name.urlEscaped
        }
    }
    
}

extension RelationalQueryOrderDirection: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
            case .ascending:
            "asc"
            case .descending:
            "desc"
        }
    }
}

extension RelationalQueryResultOrder: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
        case .field(let name):
            name.urlEscaped
        case .fieldWithDirection(let name, let direction):
            "\(name.urlEscaped).\(direction.postgrest)"
        }
    }
    
}

extension RelationalQueryCondition: PostgRESTConvertible {
    
    public var postgrest: String {
        postgrest(topLevel: true)
    }
    
    public func postgrest(topLevel: Bool) -> String {
        switch self {
        case .equalText(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")eq.\(value.urlEscaped)"
        case .equalInteger(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")eq.\(value)"
        case .smallerInteger(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")lt.\(value)"
        case .smallerOrEqualInteger(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")lte.\(value)"
        case .greaterInteger(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")gt.\(value)"
        case .greaterOrEqualInteger(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")gte.\(value)"
        case .equalBoolean(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")eq.\(value)"
        case .similarText(field: let field, template: let value, wildcard: let wildcard):
            // TODO: escape * via %2A, but at the same time!
            "\(field.urlEscaped)\(topLevel ? "=" : ".")like.\(value.replacing(wildcard, with: "*").urlEscaped)"
        case .not(let condition):
            "not\(topLevel ? "=" : ".")\(condition.postgrest(topLevel: false))"
        case .and(let conditions):
            "and\(topLevel ? "=" : "")(\(conditions.map{ $0.postgrest(topLevel: false) }.joined(separator: ",")))"
        case .or(let conditions):
            "or\(topLevel ? "=" : "")(\(conditions.map{ $0.postgrest(topLevel: false) }.joined(separator: ",")))"
        }
    }
    
}

extension RelationalQuery: PostgRESTConvertible {
    
    public var postgrest: String {
        var result = "\(table.urlEscaped)?"
        var needsAmpersand = false
        if let fields {
            result += "select=" + fields.map{ $0.postgrest }.joined(separator: ",")
            needsAmpersand = true
        }
        if let condition {
            if needsAmpersand { result += "&" }
            result += condition.postgrest
            needsAmpersand = true
        }
        if let order {
            if needsAmpersand { result += "&"}
            result += order.map{ $0.postgrest }.joined(separator: ",").prepending("order=")
        }
        return result
    }
    
}
