//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-08-03.
//

import Foundation

extension String {
	func countLines(upTo: NSRange) -> Int {
		guard let regex = try? NSRegularExpression(pattern: "\n", options: [])
        else { return 0 }
		return regex.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: upTo.location)) + 1
	}
}
