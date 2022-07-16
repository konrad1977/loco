import Foundation

public struct Fileinfo {
    public let path: String
    public let filename: String
    public let filetype: Filetype
}

extension Fileinfo {
    static var empty = Fileinfo(path: "", filename: "", filetype: .empty)
}
