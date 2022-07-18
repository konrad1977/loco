//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-18.
//

import Foundation
import Funswift

struct LocoAnalyzer {

    func analyze(io: IO<([LocalizationGroup], [LocalizeableData])>) -> IO<Void> {
        io.flatMap(handleLocalizations)
    }
}

extension LocoAnalyzer {

    private func handleLocalizations(_ groups: [LocalizationGroup], _ inCode: [LocalizeableData]) -> IO<Void> {
        IO {
            let allLocalizations = allLocalizations(from: groups).unsafeRun()
            let unusedTranslationKeys = allLocalizations.filter {
                loc in inCode.flatMap { $0.data }.contains(loc) == false
            }

            let untranslated = inCode.filter {
                $0.data.filter { allLocalizations.contains($0) }.isEmpty
            }

            if unusedTranslationKeys.isEmpty == false {
                unusedTranslationKeys.forEach {
                    print($0)
                }
            }

            print("Found \(unusedTranslationKeys.count) translation key(s) that can be removed from project.")
            print("-------------------MISSING TRANSLATIONS------------------------")

            if untranslated.isEmpty == false {
                print("Warning found \(untranslated.count) untranslated file(s)")
                printLocaleData(untranslated)
            }

            print("-------------------DUPLICATE TRANSLATIONS------------------------")
            let files = groups.flatMap { $0.files }
            files.forEach { file in
                checkForDuplicateKeys(file).unsafeRun()
            }
        }
    }

    private func allLocalizations(from groups: [LocalizationGroup]) -> IO<[LocalizeEntry]> {
        IO { groups.flatMap { $0.files }.flatMap { $0.data } }
    }

    private func checkForDuplicateKeys(_ group: LocalizeableData) -> IO<Void> {
        IO {
            let duplicates = Dictionary(grouping: group.data, by: { $0 })
                .filter { $1.count > 1 }
            duplicates.forEach { item in
                print("Found duplicate key:")
                item.value.forEach { item in
                    print(item)
                }
            }
        }
    }

    private func printLocaleData(_ inCode: [LocalizeableData]) {
        inCode.forEach { locData in
            locData.data.forEach { locale in
                print("\(locData.path):\(locale.lineNumber) \(locale.data)")
            }
        }
    }
}
