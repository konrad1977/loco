import Funswift

struct FileType: OptionSet {

    let rawValue: Int

    static let swift = FileType(rawValue: 1 << 0)
    static let localizable = FileType(rawValue: 1 << 1)
    static let objectiveC = FileType(rawValue: 1 << 2)

    static let all: FileType = [.swift, .objectiveC, .localizable]
    static let empty: FileType = []

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension FileType {
    public init(fileExtension: String) {
        switch fileExtension {
        case "m", "h":
            self = .objectiveC
        case "swift":
            self = .swift
        case "strings":
            self = .localizable
        default:
            self = .empty
        }
    }
}

extension FileType {

    func elements() -> AnySequence<Self> {

		var remainingBits = rawValue
		var bitMask: RawValue = 1

		return AnySequence {
			return AnyIterator {
				while remainingBits != 0 {
					defer { bitMask = bitMask &* 2 }
					if remainingBits & bitMask != 0 {
						remainingBits = remainingBits & ~bitMask
						return Self(rawValue: bitMask)
					}
				}
				return nil
			}
		}
	}
}

extension FileType {
    public var predicate: Predicate<String> {
        switch self {
        case .all:
            return anyOf(
                FileType.swift.predicate,
                FileType.localizable.predicate,
                FileType.objectiveC.predicate
            )
        case .localizable:
            return Predicate { $0.hasSuffix(".strings") }
        case .swift:
            return Predicate { $0.hasSuffix(".swift") }
        case .objectiveC:
            return Predicate { $0.hasSuffix(".m") || $0.hasSuffix(".h") }
        case .empty:
            return Predicate { _ in false }
        default:
            return Predicate { _ in false }
        }
    }
}
