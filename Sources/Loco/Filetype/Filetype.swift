import Foundation
import Funswift

public struct Filetype: OptionSet {

    public let rawValue: Int

    public static let swift = Filetype(rawValue: 1 << 0)
    public static let localizeable = Filetype(rawValue: 1 << 1)
    public static let objectiveC = Filetype(rawValue: 1 << 2)

    public static let all: Filetype = [.swift, .objectiveC, .localizeable]
    public static let empty: Filetype = []

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension Filetype {
    public init(extension: String) {
        switch `extension` {
        case "m", "h":
            self = .objectiveC
        case "swift":
            self = .swift
        case "strings":
            self = .localizeable
        default:
            self = .empty
        }
    }
}

extension Filetype {

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

extension Filetype {
    public var predicate: Predicate<String> {
        switch self {
        case .all:
            return anyOf(
                Filetype.swift.predicate,
                Filetype.localizeable.predicate,
                Filetype.objectiveC.predicate
            )
        case .localizeable:
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
