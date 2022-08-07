import Foundation

extension RangeExpression where Bound == String.Index  {
	func nsRange<S: StringProtocol>(in string: S) -> NSRange { .init(self, in: string) }
}
