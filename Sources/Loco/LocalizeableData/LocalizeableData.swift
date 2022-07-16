//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-15.
//

import Foundation

public struct LocalizeEntry {
    let path: String
    let data: String
    let lineNumber: Int
}

extension LocalizeEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}

extension LocalizeEntry: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.data == rhs.data
    }
}

extension LocalizeEntry: CustomStringConvertible {
    public var description: String {
        "\(path):\(lineNumber) \(data)"
    }
}


public struct LocalizeableData {
    public let path: String
    public let filename: String
    public let filetype: Filetype
    public let data: [LocalizeEntry]
}

extension LocalizeableData {
    var pathComponents: [String] {
        return URL(fileURLWithPath: path).pathComponents
    }
}
