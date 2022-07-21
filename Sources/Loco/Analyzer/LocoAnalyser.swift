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
                printUnusedTranslations(unusedTranslationKeys)
            }

            let files = groups.flatMap { $0.files }
            files.forEach { checkForDuplicateKeys($0).unsafeRun() }

            if untranslated.isEmpty == false {
                printMissingTranslations(untranslated)
            }
            detectUntranslatedString(for: groups)
        }
    }

    private func allLocalizations(from groups: [LocalizationGroup]) -> IO<[LocalizeEntry]> {
        IO { groups.flatMap { $0.files }.flatMap { $0.data } }
    }

    private func checkForDuplicateKeys(_ group: LocalizeableData) -> IO<Void> {
        IO {
            let duplicates = Dictionary(grouping: group.data, by: { $0 })
                .filter { $1.count > 1 }
            duplicates.forEach { item in
                item.value.forEach { item in
                    print("\(item.path):\(item.lineNumber) Warning duplicate key found for: '\(item.data)'")
                }
            }
        }
    }

    private func detectUntranslatedString(for groups: [LocalizationGroup]) {

        let languages = Set(groups.flatMap { $0.files }.compactMap { $0.locale }.filter { $0 != "" })

        groups.forEach { group in
            let languagesInGroup = group.files.compactMap { $0.locale }
            let missingLanguage = languages.filter { languagesInGroup.contains($0) == false }
            if missingLanguage.isEmpty == false {
                missingLanguage.forEach { lang in
                    if let file = group.files.first?.replaceLanguage(with: lang).dropFirst() {
                        print("\(file) Warning file is missing. You should create it.")
                    }
                }
            }
        }
    }

    private func printUnusedTranslations(_ data: [LocalizeEntry]) {
        data.forEach {
            print("\($0.path):\($0.lineNumber) Warning unused key '\($0.data)'")
        }
    }

    private func printMissingTranslations(_ inCode: [LocalizeableData]) {
        inCode.forEach { locData in
            locData.data.forEach { locale in
                print("\(locData.path):\(locale.lineNumber) Warning missing translation found for: '\(locale.data) \(locData.locale)'")
            }
        }
    }
}
