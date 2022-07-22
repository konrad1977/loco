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
    public var description: String {
        switch self {
        case let .duplicate(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " duplicate key found for: " + "'\(key)'".textColor(.keyColor)
        case let .missingKey(name, path):
            return "\(path) " + "warning:".textColor(.warningColor) + " is missing the key " + "'\(name)'".textColor(.keyColor)
        case let .unused(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " '\(key)'".textColor(.keyColor) + " is is unused"
        case let .missingFile(name):
            return "\(name) " + "warning:".textColor(.warningColor) + " file is missing. You should create a file"
        case let .missingTranslation(key, path, linenumber):
            return "\(path):\(linenumber) " + "warning:".textColor(.warningColor) + " missing translation found for " + "'\(key))'".textColor(.keyColor)
        }
    }
}
