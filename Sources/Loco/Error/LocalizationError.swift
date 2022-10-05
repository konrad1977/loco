import Foundation

public enum LocalizationError: Equatable {
    case emptyValue(key: String, path: String, lineNumber: Int)
    case duplicate(key: String, path: String, lineNumber: Int)
    case missingKey(name: String, path: String)
    case unused(key: String, path: String, lineNumber: Int)
    case missingFile(name: String)
    case missingTranslation(key: String, path: String, lineNumber: Int)
    case missingSemicolon(path: String, lineNumber: Int)
}

extension LocalizationError: CustomStringConvertible {

    private func unquote(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "")
    }

    var coloredDescription: String {
        switch self {
        case let .emptyValue(key, path, lineNumber):
            return "\(path):\(lineNumber) " + "warning:".textColor(.warningColor) + " empty key found for: ".fontStyle(.italic) + "'\(unquote(key))'".textColor(.keyColor)

        case let .duplicate(key, path, lineNumber):
            return "\(path):\(lineNumber) " + "warning:".textColor(.warningColor) + " duplicate key found for: ".fontStyle(.italic) + "'\(unquote(key))'".textColor(.keyColor)

        case let .missingKey(name, path):
            return "\(path) " + "warning:".textColor(.warningColor) + " is missing the key ".fontStyle(.italic) + "'\(unquote(name))'".textColor(.keyColor)

        case let .unused(key, path, lineNumber):
            return "\(path):\(lineNumber) " + "info:".textColor(.infoColor) + " '\(unquote(key))'".textColor(.keyColor) + " is unused".fontStyle(.italic)

        case let .missingFile(name):
            return "\(name) " + "warning:".textColor(.warningColor) + " file is missing. You should create a file".fontStyle(.italic)

        case let .missingTranslation(key, path, lineNumber):
            return "\(path):\(lineNumber) " + "warning:".textColor(.warningColor) + " missing translation found for ".fontStyle(.italic) + "'\(unquote(key))'".textColor(.keyColor)

        case let .missingSemicolon(path, lineNumber):
            return "\(path):\(lineNumber) " + "error:".textColor(.errorColor) + " missing semicolon ".fontStyle(.italic)
        }
    }

    public var description: String {
        switch self {
        case let .emptyValue(key, path, lineNumber):
            return "\(path):\(lineNumber): warning: empty key found for: '\(unquote(key))'"

        case let .duplicate(key, path, lineNumber):
            return "\(path):\(lineNumber): warning: duplicate key found for: '\(unquote(key))'"

        case let .missingKey(name, path):
            return "\(path):0: warning: is missing the key '\(unquote(name))'"

        case let .unused(key, path, lineNumber):
            return "\(path):\(lineNumber): warning: key '\(unquote(key))' is unused"

        case let .missingFile(name):
            return "\(name) info: file is missing. You should create a file"

        case let .missingTranslation(key, path, lineNumber):
            return "\(path):\(lineNumber): warning: missing translation found for '\(unquote(key))'"

        case let .missingSemicolon(path, lineNumber):
            return "\(path):\(lineNumber): error: missing semicolon found"
        }
    }
}
