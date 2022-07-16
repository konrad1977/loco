import Foundation
import Funswift

let result = LocoAnalyzer()
    .sourceFiles(
        from: FileManager.default.currentDirectoryPath,
        filter: .custom(["build"])
    )
    .unsafeRun()

handleLocalizations(result.0, result.1)

func handleLocalizations(_ groups: [LocalizationGroup], _ inCode: [LocalizeableData]) {

    let allLocalizations = groups.flatMap { $0.files }.flatMap { $0.data }
    let unusedTranslationKeys = allLocalizations.filter {
        loc in inCode.flatMap { $0.data }.contains(loc) == false
    }

    let untranslated = inCode.filter {
        $0.data.filter { allLocalizations.contains($0) }.isEmpty
    }

    if untranslated.isEmpty == false {
        print("Warning found \(untranslated.count) untranslated file(s)")
        printLocaleData(untranslated)
        print("-----")
    }

    if unusedTranslationKeys.isEmpty == false {
        print("Found \(unusedTranslationKeys.count) translation key(s) that can be removed from project.")
        unusedTranslationKeys.forEach {
            print($0)
        }
    }
}

func printLocaleData(_ inCode: [LocalizeableData]) {
    inCode.forEach { locData in
        locData.data.forEach { locale in
            print("\(locData.path):\(locale.lineNumber) \(locale.data)")
        }
    }
}


