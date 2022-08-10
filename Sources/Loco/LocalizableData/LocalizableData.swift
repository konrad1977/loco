import Foundation

struct LocalizeEntry {
    let path: String
	let key: String
	var data: String?
    let lineNumber: Int
}

extension LocalizeEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension LocalizeEntry: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.key == rhs.key
    }
}

extension LocalizeEntry: CustomStringConvertible {
    public var description: String {
        "./\(path):\(lineNumber) \(key)"
    }
}

struct LocalizableData {
    let path: String
    let filename: String
    let filetype: FileType
    let data: [LocalizeEntry]
    var restData: [LocalizeEntry] = []
    var locale: String?
}

extension LocalizableData {
    var pathComponents: [String] {
        URL(fileURLWithPath: path).pathComponents
    }

    func replaceLanguage(with lang: String) -> String? {
        guard let cpy = pathComponents.last 
        else { return nil }
        return pathComponents.dropLast(2).joined(separator: "/") + "/" + lang + ".lproj/" + cpy
    }
}
