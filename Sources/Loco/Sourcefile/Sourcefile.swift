import Foundation

public struct Sourcefile {
    public let path: String
    public let name: String
    public let data: String.SubSequence
    public let filetype: Filetype
}
