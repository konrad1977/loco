import Foundation
import Funswift

LocoAnalyzer().sourceFiles(from: FileManager.default.currentDirectoryPath, filter: .custom(["build"]))
    .unsafeRun()

//print(errors:
//        LocoAnalyzer()
//            .localizedFiles(
//                from: FileManager.default.currentDirectoryPath
//            )
//            .unsafeRun()
//            .filter { $0.errors.isEmpty == false }
//)
//
//func print(errors: [LocalizationError]) {
//    errors.forEach { error in
//        error.errors.forEach { type in
//            switch type {
//            case let .duplicate(key: key, file: file):
//                print("Key: \(key) is duplicated in \(file)")
//            case .none:
//                break
//            }
//        }
//    }
//}
