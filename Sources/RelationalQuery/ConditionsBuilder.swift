public func one(@RelationalQueryConditionsBuilder builder: () -> [RelationalQueryCondition]) -> RelationalQueryCondition {
    .or(conditions: builder())
}

public func all(@RelationalQueryConditionsBuilder builder: () -> [RelationalQueryCondition]) -> RelationalQueryCondition {
    .and(conditions: builder())
}

public func notOne(@RelationalQueryConditionsBuilder builder: () -> [RelationalQueryCondition]) -> RelationalQueryCondition {
    let conditions = builder()
    if conditions.count == 1 {
        return .not(condition: conditions.first!)
    } else {
        return .not(condition: .or(conditions: conditions))
    }
}

public func notAll(@RelationalQueryConditionsBuilder builder: () -> [RelationalQueryCondition]) -> RelationalQueryCondition {
    let conditions = builder()
    if conditions.count == 1 {
        return .not(condition: conditions.first!)
    } else {
        return .not(condition: .and(conditions: conditions))
    }
}

@resultBuilder
public struct RelationalQueryConditionsBuilder {
    
    public static func buildBlock(_ components: RelationalQueryCondition...) -> [RelationalQueryCondition] {
        return components
    }
    
    public static func buildBlock(_ components: RelationalQueryCondition?...) -> [RelationalQueryCondition] {
        components.compactMap { $0 }
    }
    
    public static func buildBlock(_ sequences: any Sequence<RelationalQueryCondition>...) -> [RelationalQueryCondition] {
        var result = [RelationalQueryCondition]()
        for sequence in sequences {
            result.append(contentsOf: sequence)
        }
        return result
        
    }
    
    public static func buildExpression(_ expression: RelationalQueryCondition) -> [RelationalQueryCondition] {
        [expression]
    }
    
    public static func buildExpression(_ expression: RelationalQueryCondition?) -> [RelationalQueryCondition] {
        [RelationalQueryCondition]()
    }
    
    public static func buildExpression(_ array: [RelationalQueryCondition]) -> [RelationalQueryCondition] {
        array
    }
    
    public static func buildExpression(_ array: [RelationalQueryCondition?]) -> [RelationalQueryCondition] {
        array.compactMap { $0 }
    }
    
    public static func buildEither(first component: [RelationalQueryCondition]) -> [RelationalQueryCondition] {
        component
    }
    
    public static func buildEither(second component: [RelationalQueryCondition]) -> [RelationalQueryCondition] {
        component
    }
    
    public static func buildOptional(_ component: [RelationalQueryCondition]?) -> [RelationalQueryCondition] {
        component ?? [RelationalQueryCondition]()
    }
    
}
