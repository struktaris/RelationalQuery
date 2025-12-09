import Foundation

public enum RelationalField: Sendable, Codable {
    case field(name: String)
    case renamingField(name: String, to: String)
}

public enum RelationalQueryOrderDirection: Sendable, Codable {
    case ascending
    case descending
}

public enum RelationalQueryResultOrder: Sendable, Codable {
    case field(name: String)
    case fieldWithDirection(name: String, direction: RelationalQueryOrderDirection)
}

public indirect enum RelationalQueryCondition: Sendable, Codable {
    case equalText(field: String, value: String)
    case equalInteger(field: String, value: Int)
    case smallerInteger(field: String, than: Int)
    case smallerOrEqualInteger(field: String, than: Int)
    case greaterInteger(field: String, than: Int)
    case greaterOrEqualInteger(field: String, than: Int)
    case equalBoolean(field: String, value: Bool)
    case similarText(field: String, template: String, wildcard: String)
    case not(condition: RelationalQueryCondition)
    case and(conditions: [RelationalQueryCondition])
    case or(conditions: [RelationalQueryCondition])
}

public func compare(textField field: String, withValue value: String) -> RelationalQueryCondition {
    .equalText(field: field, value: value)
}

public func compare(integerField field: String, withValue value: Int) -> RelationalQueryCondition {
    .equalInteger(field: field, value: value)
}

public func compare(booleanField field: String, withValue value: Bool) -> RelationalQueryCondition {
    .equalBoolean(field: field, value: value)
}

public func compare(textField: String, withTemplate template: String, usingWildcard wildcard: String) -> RelationalQueryCondition {
    .similarText(field: textField, template: template, wildcard: wildcard)
}

/// If the "possible template" contains at least one wildcard, it will be used for a "similarity" commparison, else th result is a equality comparison.
public func compare(textField: String, withPotentialTemplate potentialTemplate: String, usingWildcard wildcard: String) -> RelationalQueryCondition {
    if potentialTemplate.contains(wildcard) {
        .similarText(field: textField, template: potentialTemplate, wildcard: wildcard)
    } else {
        .equalText(field: textField, value: potentialTemplate)
    }
}

public struct RelationalQuery: Sendable, Codable {
    
    public let table: String
    public let fields: [RelationalField]? // if not set, get all fields
    public let condition: RelationalQueryCondition?
    public let order: [RelationalQueryResultOrder]?
    
    public init(
        table: String,
        fields: [RelationalField]? = nil, // if not set, get all fields
        condition: RelationalQueryCondition? = nil,
        orderBy order: [RelationalQueryResultOrder]? = nil,
    ) {
        self.table = table
        self.fields = fields
        self.order = order
        self.condition = condition
    }
    
}
