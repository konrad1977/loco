//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-15.
//

import Foundation

public struct LocalizeEntry {
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

public struct LocalizeableData {
    public let path: String
    public let filename: String
    public let filetype: Filetype
    public let data: [LocalizeEntry]
    public var locale: String?
}

extension LocalizeableData {
    var pathComponents: [String] {
        return URL(fileURLWithPath: path).pathComponents
    }

    func replaceLanguage(with lang: String) -> String {
        let cpy = pathComponents
        return pathComponents.dropLast(2).joined(separator: "/") + "/" + lang + ".lproj/" + cpy.last!
    }
}
