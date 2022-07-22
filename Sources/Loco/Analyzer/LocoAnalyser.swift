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

            var errors: [LocalizationError] = []
            let (unused, missing, missingFiles) = zip(
                printUnusedTranslations(unusedTranslationKeys),
                printMissingTranslations(untranslated),
                detectMissingTranslationFiles(for: groups)
            ).unsafeRun()

            errors.append(contentsOf: unused)
            errors.append(contentsOf: missing)
            errors.append(contentsOf: missingFiles)

            let files = groups.flatMap { $0.files }
            files.forEach {
                errors.append(contentsOf: checkForDuplicateKeys($0).unsafeRun())
            }

            groups.forEach { group in
                errors.append(contentsOf: detectMissingKeysIn(group: group).unsafeRun())
            }

            errors.forEach { error in
                print(error)
            }
            print("Found " + "\(errors.count)".textColor(.warningColor) + " issues.")
        }
    }

    private func allLocalizations(from groups: [LocalizationGroup]) -> IO<[LocalizeEntry]> {
        IO { groups.flatMap { $0.files }.flatMap { $0.data } }
    }

    private func checkForDuplicateKeys(_ group: LocalizeableData) -> IO<[LocalizationError]> {
        IO {
            Dictionary(grouping: group.data, by: { $0 })
                .filter { $1.count > 1 }
                .flatMap { $0.value }
                .map { .duplicate(key: $0.data, path: $0.path, linenumber: $0.lineNumber) }
        }
    }

    private func detectMissingKeysIn(group: LocalizationGroup) -> IO<[LocalizationError]>{
        IO {
            let allUniqueKeys = Set(group.files.flatMap { $0.data })
            var errors: [LocalizationError] = []
            group.files.forEach { file in
                let missing = allUniqueKeys.filter { file.data.contains($0) == false }
                missing.forEach { translation in
                    errors.append(.missingKey(name: translation.data, path: file.path))
                }
            }
            return errors
        }
    }

    private func detectMissingTranslationFiles(for groups: [LocalizationGroup]) -> IO<[LocalizationError]> {
        IO {
            let languages = Set(groups.flatMap { $0.files }.compactMap { $0.locale }.filter { $0 != "" })
            var errors: [LocalizationError] = []

            groups.forEach { group in
                let languagesInGroup = group.files.compactMap { $0.locale }
                let missingLanguage = languages.filter { languagesInGroup.contains($0) == false }
                if missingLanguage.isEmpty == false {
                    missingLanguage.forEach { lang in
                        if let file = group.files.first?.replaceLanguage(with: lang).dropFirst() {
                            errors.append(.missingFile(name: String(file)))
                        }
                    }
                }
            }
            return errors
        }
    }

    private func printUnusedTranslations(_ data: [LocalizeEntry]) -> IO<[LocalizationError]>{
        IO { data.map { .unused(key: $0.data, path: $0.path, linenumber: $0.lineNumber) } }
    }

    private func printMissingTranslations(_ inCode: [LocalizeableData]) -> IO<[LocalizationError]> {
        IO {
            var errors: [LocalizationError] = []
            inCode.forEach { locData in
                locData.data.forEach { locale in
                    errors.append(.missingTranslation(key: locale.data, path: locData.path, linenumber: locale.lineNumber))
                }
            }
            return errors
        }
    }
}
