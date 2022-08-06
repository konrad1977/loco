//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-08-05.
//

import Foundation

struct SourceValues {
	let lineNumber: Int
	let keys: [String]
}

extension SourceValues {
	static var empty = SourceValues(lineNumber: 0, keys: [])
}
