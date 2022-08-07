import Foundation

struct SourceFile {
    let path: String
    let name: String
    let data: String.SubSequence
    let filetype: FileType
}
