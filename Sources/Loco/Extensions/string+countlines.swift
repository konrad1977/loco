//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-08-03.
//

import Foundation

extension String {
	func countLines(upTo: NSRange) -> Int {
		do {
			let regex = try NSRegularExpression(pattern: "\n", options: [])
			return regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, upTo.location)) + 1
		} catch {
			return 0
		}
	}
}
