import Funswift

public enum PathFilter {
    case custom([String])
    case pods
    case empty
}

extension PathFilter {

    var query: Predicate<String> {
        switch self {
        case let .custom(filter):
            var predicate = Predicate<String> { _ in false }
            filter.forEach { filter in
                predicate = predicate.union(
                    other: Predicate<String> { $0.lowercased().contains(filter.lowercased()) }
                )
            }
            return predicate
        case .pods:
            return PathFilter.custom(["pods"]).query
        case .empty:
            return PathFilter.custom([""]).query
        }
    }
}
