import Foundation

enum RegexPattern {
    case extractKeyAndValue
    case querySourceCode(regex: String)
    case extractLocaleFromPath
	case missingSemicolon
    case allStrings
    case swiftgen
}

extension RegexPattern {
    var regex: String {
        switch self {
        case .extractKeyAndValue:
           return #"^(\"[^\"]+\")\s?=\s?(\"[^\"]*?\")"#
        case let .querySourceCode(regex: pattern):
            return pattern
        case .extractLocaleFromPath:
            return #"(\w{2}-\w{2}|\w{2})\.lproj"#
        case .missingSemicolon:
            return #"(^\"(?:.(?!;|\\))*$)"#
        case .allStrings:
            return #"(\".+\")"#
        case .swiftgen:
            return #"\.tr\(\"\w+\"\,\W?(\"\S+\")"#
        }
    }
}

extension RegexPattern {
    
    static func buildSourceRegex(_ list: [String]) -> String {
        #"[^\w?]("# + list.joined(separator: "\\(|") + #")\s*?(\".*?\")"#
    }

    static var sourceRegex: String {
        buildSourceRegex(
          [
            "\\.navigationTitle",
            "Label",
            "Text",
            "Picker",
            "Button",
            "Toggle",
            "LocalizedStringKey",
            "NSLocalizedString",
            "String\\(localized:",
          ]
        )
    }
}
