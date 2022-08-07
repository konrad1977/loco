import Foundation

struct Parser {
    let keyword: String
    let args: [String]
}

extension Parser {

    func hasArgument() -> Bool {
        let (first, _) = findArgumentIndicies(for: keyword, in: args)
        return first != nil
    }

	func value() -> String? {
        let (first, _) = findArgumentIndicies(for: keyword, in: args)

        guard let first = first, first < args.endIndex else { return nil }

        return args[first + 1]
	}

    func parse() -> [String] {
        let (first, last) = findArgumentIndicies(for: keyword, in: args)

        guard let first = first else { return [] }

        guard let lastIndex = last else { return Array(args.dropFirst(first + 1)) }

        return Array(args[first + 1..<lastIndex])
    }

    private func findArgumentIndicies(for argv: String, in args: [String]) -> (first: Int?, last: Int?) {
        guard let firstArg = args.firstIndex(of: argv) else { return (nil, nil) }

        let nextArgs = args.dropFirst(firstArg).map { $0.lowercased() }

        guard let next = nextArgs.firstIndex(where: { $0 != argv && ($0.hasPrefix("--") || $0.hasPrefix("-")) }) else { return (firstArg, nil) }

        return (firstArg, next)
    }

}
