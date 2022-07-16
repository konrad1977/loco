//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-15.
//

import Foundation

public enum LocalizationErrorType: Equatable {
    case duplicate(key: String, file: String)
    case none
}

public struct LocalizationError {
    var errors: [LocalizationErrorType]
}
