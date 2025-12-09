import Foundation

extension String {
    
    var asSQLName: String {
        if self.contains(/^[a-zA-Z_][a-zA-Z0-9_]*$/) {
            self
        } else {
            "\"" + self.replacing("\"", with: "\"\"") + "\""
        }
    }
    
    // TODO: option to differentiate bteween databases, for MS Access escape "[" and "]" via "\[" and "\]"
    var asSQLText: String {
        "'" + self.replacing("'", with: "''") + "'"
    }
    
    var urlEscaped: String {
        // TODO: should neither throw exception nor suppress one!
        // TODO: also percent-encode umlauts etc.!
        var allowedQueryParamAndKey = CharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$,")
        return self.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey) ?? self
    }
    
    func appending(_ other: String?) -> String {
        if let other {
            self + other
        } else {
            self
        }
    }
    
    func prepending(_ other: String?) -> String {
        if let other {
            other + self
        } else {
            self
        }
    }
    
}

public struct RelationalQueryError: LocalizedError, CustomStringConvertible {

    private let message: String

    public init(_ message: String) {
        self.message = message
    }
    
    public var description: String { message }
    
    public var errorDescription: String? { message }
}
