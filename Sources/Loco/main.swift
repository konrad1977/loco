import Foundation
import Funswift

let result = LocoAnalyzer()
    .sourceFiles(
        from: FileManager.default.currentDirectoryPath,
        filter: .custom(["build"])
    )
    .unsafeRun()

handleLocalizations(result.0.flatMap { $1 }, result.1)

func handleLocalizations(_ allLocalizations: [String], _ inCode: [LocalizeableData]) {
    let allLocalized = Set(allLocalizations)
    let unusedTranslationKeys = allLocalized.filter {
        loc in inCode.flatMap { $0.data }.contains(loc) == false
    }
    //print(unusedTranslationKeys)

    let untranslated = inCode.filter {
        $0.data.filter { allLocalized.contains($0) }.isEmpty
    }
    printLocaleData(untranslated)

    let untranslatedStrings = inCode.flatMap { $0.data }.filter { allLocalized.contains($0) == false }
    print(untranslatedStrings)
//    print(untranslatedStrings)
   // let untranslatedFiles = inCode.filter { $0.data. }
//    var result: [LocalizeableData] = []
//    inCode.forEach { code in
//        let filtered = code.data.filter { allLocalized.contains($0) == false }
//        result += filtered
//    }
//
//    printLocaleData(result)

}

func printLocaleData(_ inCode: [LocalizeableData]) {
    inCode.forEach { locData in
        print("\(locData.path):")
        locData.data.forEach { locale in
            print("\t\(locale)")
        }
    }
}

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
