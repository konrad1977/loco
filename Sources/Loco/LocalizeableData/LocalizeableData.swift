//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-15.
//

import Foundation

struct LocalizeableData {
    public let path: String
    public let filename: String
    public let filetype: Filetype
    public let data: [String]
}

extension LocalizeableData {
    var pathComponents: [String] {
        return URL(fileURLWithPath: path).pathComponents
    }
}
