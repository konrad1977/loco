import Foundation

struct SourceValues {
	let lineNumber: Int
	let keys: [String]
}

extension SourceValues {
	static var empty = SourceValues(lineNumber: 0, keys: [])
}
