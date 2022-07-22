//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-15.
//

import Foundation

public enum LocalizationError: Equatable {
    case duplicate(key: String, path: String, linenumber: Int)
    case missingKey(name: String, path: String)
    case unused(key: String, path: String, linenumber: Int)
    case missingFile(name: String)
    case missingTranslation(key: String, path: String, linenumber: Int)
}

extension LocalizationError: CustomStringConvertible {

    private func unquote(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "")
    }

    public var description: String {
        switch self {
        case let .duplicate(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " duplicate key found for: ".fontStyle(.italic) + "'\(unquote(key))'".textColor(.keyColor)
        case let .missingKey(name, path):
            return "\(path) " + "warning:".textColor(.warningColor) + " is missing the key ".fontStyle(.italic) + "'\(unquote(name))'".textColor(.keyColor)
        case let .unused(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " '\(unquote(key))'".textColor(.keyColor) + " is is unused".fontStyle(.italic)
        case let .missingFile(name):
            return "\(name) " + "warning:".textColor(.warningColor) + " file is missing. You should create a file".fontStyle(.italic)
        case let .missingTranslation(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " missing translation found for ".fontStyle(.italic) + "'\(unquote(key))'".textColor(.keyColor)
        }
    }
}
