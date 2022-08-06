//
//  LocoAnalyzer.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-18.
//

import Foundation
import Funswift

struct LocoAnalyzer {
    let args: [String]
    func analyze(io: IO<([LocalizationGroup], [LocalizeableData], [LocalizationError])>) -> IO<Void> {
        io.flatMap(handleLocalizations)
    }

    init(args: [String]) {
        self.args = args
    }
}

extension LocoAnalyzer {

	private func handleLocalizations(_ groups: [LocalizationGroup], _ inCode: [LocalizeableData], _ compileErrors: [LocalizationError]) -> IO<Void> {
        IO {
			let disableColoredOutput = Parser(keyword: "--no-color", args: args).hasArgument()

			compileErrors.forEach { error in
				print(disableColoredOutput ? error : error.coloredDescription)
			}
			
            let allLocalizations = allLocalizations(from: groups).unsafeRun()
            let unusedTranslationKeys = allLocalizations.filter { loc in inCode.flatMap { $0.data }.contains(loc) == false }
            let untranslated = inCode.filter { $0.data.filter { allLocalizations.contains($0) }.isEmpty }

            var warnings: [LocalizationError] = []
            let (empty, unused, missing, missingFiles) = zip(
				checkEmptyValues(from: allLocalizations),
                checkUnusedTranslations(unusedTranslationKeys),
                checkMissingTranslations(untranslated),
                checkMissingTranslationFiles(for: groups)
            ).unsafeRun()

			warnings.append(contentsOf: empty)
			warnings.append(contentsOf: unused)
			warnings.append(contentsOf: missing)
			warnings.append(contentsOf: missingFiles)

            let files = groups.flatMap { $0.files }
            files.forEach {
				warnings.append(contentsOf: checkForDuplicateKeys($0).unsafeRun())
            }

            groups.forEach { group in
				warnings.append(contentsOf: detectMissingKeysIn(group: group).unsafeRun())
            }

			warnings.forEach { error in
                print(disableColoredOutput ? error : error.coloredDescription)
            }
			if compileErrors.isEmpty == false {
				print("Found " + "\(compileErrors.count)".textColor(.errorColor) + " errors.")
			}
            print("Found " + "\(warnings.count)".textColor(.warningColor) + " issues.")
        }
    }

    private func allLocalizations(from groups: [LocalizationGroup]) -> IO<[LocalizeEntry]> {
        IO { groups.flatMap { $0.files }.flatMap { $0.data } }
    }

	private func checkEmptyValues(from entries: [LocalizeEntry]) -> IO<[LocalizationError]> {
		IO {
            entries
                .filter { $0.data?.isEmpty == true || $0.data == "\"\"" }
                .map { .emptyValue(key: $0.key, path: $0.path, linenumber: $0.lineNumber) }
		}
	}

    private func checkForDuplicateKeys(_ group: LocalizeableData) -> IO<[LocalizationError]> {
        IO {
            Dictionary(grouping: group.data, by: { $0 })
                .filter { $1.count > 1 }
                .flatMap { $0.value }
                .map { .duplicate(key: $0.key, path: $0.path, linenumber: $0.lineNumber) }
        }
    }

    private func detectMissingKeysIn(group: LocalizationGroup) -> IO<[LocalizationError]>{
        IO {
            let allUniqueKeys = Set(group.files.flatMap { $0.data })
            var errors: [LocalizationError] = []
            group.files.forEach { file in
                let missing = allUniqueKeys.filter { file.data.contains($0) == false }
                missing.forEach { translation in
                    errors.append(.missingKey(name: translation.key, path: file.path))
                }
            }
            return errors
        }
    }

    private func checkMissingTranslationFiles(for groups: [LocalizationGroup]) -> IO<[LocalizationError]> {
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

    private func checkUnusedTranslations(_ data: [LocalizeEntry]) -> IO<[LocalizationError]> {
        IO { data.map { .unused(key: $0.key, path: $0.path, linenumber: $0.lineNumber) } }
    }

    private func checkMissingTranslations(_ inCode: [LocalizeableData]) -> IO<[LocalizationError]> {
        IO {
            var errors: [LocalizationError] = []
            inCode.forEach { locData in
                locData.data.forEach { locale in
                    errors.append(.missingTranslation(key: locale.key, path: locData.path, linenumber: locale.lineNumber))
                }
            }
            return errors
        }
    }
}

extension LocoAnalyzer {
    private func showOutputWithColors(args: [String]) -> Bool {
        Parser(keyword: "--color", args: args).hasArgument()
    }
}
