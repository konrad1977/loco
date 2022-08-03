//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-08-03.
//

import Foundation

extension RangeExpression where Bound == String.Index  {
	func nsRange<S: StringProtocol>(in string: S) -> NSRange { .init(self, in: string) }
}
