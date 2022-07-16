import Foundation
import Funswift

public struct LocoAnalyzer {

    let pattern = #"("[^\"]+")\s+=\s+\"[^\"]+\""#
    let sourcePattern = #"NSLocalizedString\((\".*?\")"#
    public init() {}
}

let testPath = "/Users/mikaelkonradsson/Documents/git/bontouch/seco-tools-ios"

extension LocoAnalyzer {

    public func sourceFiles(
        from startPath: String,
        filter: PathFilter = .custom(["Build"])
    ) -> IO<Void> {
        IO {
                let result = zip(
                    localizedFiles(from:startPath, filter: filter),
                    IO.pure(testPath)
                        .flatMap(
                            supportedFiletypes([.swift], filter: filter)
                            >=> buildSourcePaths
                            >=> flattenSourceData
                    )
                ).unsafeRun()

            let allLocalized = Set(result.0.flatMap { $1 })
            let notUsedTranslations = allLocalized.filter { result.1.contains($0) == false }
            let untranslated = result.1.filter { allLocalized.contains($0) == false }
            print("(Might be) missing translations \(untranslated)")
            print("Not used: \(notUsedTranslations) \n")
//            result.0.compactMap { error, _ in
//                error.errors
//            }.filter { $0 != .none }
//            
//            result.0.forEach { error, _ in
//                error.errors.filter { $0 != .none })
//            }
//            print("Duplicates \(result.0.filter {)")
        }
    }

    private func localizedFiles(
        from startPath: String,
        filter: PathFilter = .custom(["Build"])
    ) -> IO<[(LocalizationError, [String])]> {
        IO.pure(testPath)
            .flatMap(
                supportedFiletypes(.localizeable, filter: filter)
                >=> buildLocalizeablePaths
                >=> buildLocalizationGroups
                >=> checkLocalizationGroups
            )
    }

    private func checkLocalizationGroups(_ groups: [LocalizationGroup]) -> IO<[(LocalizationError, [String])]> {
        IO { groups.compactMap(checkLocalizationGroup >>> LocoAnalyzer.run) }
    }

    private func checkLocalizationGroup(_ group: LocalizationGroup) -> IO<(LocalizationError, [String])> {
        IO {
            let groupErrors = group
                .files
                .map(checkForDuplicates >>> LocoAnalyzer.run)
                .filter { $0 != .none }
            return (LocalizationError(errors: groupErrors), group.files.flatMap { $0.data })
        }
    }

    private func buildLocalizeablePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherLocalizeableData >>> LocoAnalyzer.run) }
    }

    private func buildSourcePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherSourceData >>> LocoAnalyzer.run) }
    }

    private func flattenSourceData(_ files: [LocalizeableData]) -> IO<[String]> {
        IO {
            files.flatMap { $0.data }
        }
    }

    private func buildLocalizationGroups(_ files: [LocalizeableData]) -> IO<[LocalizationGroup]> {
        IO {

            let sorted = files.sorted { f1, f2 in
                if
                    let firstLast = f1.pathComponents.last,
                    let secondLast = f2.pathComponents.last {
                    return firstLast < secondLast && f1.filename < f2.filename
                } else {
                    return f1.filename < f2.filename
                }
            }

            return Dictionary(grouping: sorted) { item in
                "\(item.filename)" + (item.pathComponents.dropLast(2).last ?? "")
            }.map { (_, value: [LocalizeableData]) in
                LocalizationGroup(files: value)
            }
        }
    }

    private func checkForDuplicates(_ file: LocalizeableData) -> IO<LocalizationErrorType> {
        IO {
            let filtered = Dictionary(grouping: file.data, by: { $0 })
                .filter { $1.count > 1 }
            if filtered.isEmpty == false {
                return .duplicate(key: filtered.keys.first ?? "", file: file.path)
            }
            return .none
        }
    }

    private func gatherSourceData(_ sourcefile: Sourcefile) -> IO<LocalizeableData> {
        IO {
            do {
                let data = String(sourcefile.data)
                let range = NSRange(data.startIndex..<data.endIndex,
                                      in: data)

                let regex = try NSRegularExpression(pattern: sourcePattern, options: [])
                var entries: [String] = []
                regex.enumerateMatches(in: data, range: range) { (match, _, _) in

                    guard let match = match, let range = Range(match.range(at: 1), in: data)
                    else { return }

                    entries.append(String(data[range]))
                }
                return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
            } catch {
                return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: [])
            }
        }
    }

    private func gatherLocalizeableData(_ sourcefile: Sourcefile) -> IO<LocalizeableData> {
        IO {
            do {
                let data = String(sourcefile.data)
                let range = NSRange(data.startIndex..<data.endIndex,
                                      in: data)

                let regex = try NSRegularExpression(pattern: pattern, options: [])
                var entries: [String] = []
                regex.enumerateMatches(in: data, range: range) { (match, _, _) in

                    guard let match = match, let range = Range(match.range(at: 1), in: data)
                    else { return }

                    entries.append(String(data[range]))
                }
                return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
            } catch {
                return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: [])
            }
        }
    }
}

// MARK: - Privates
extension LocoAnalyzer {
    private static func run<T>(io: IO<T>) -> T {
        io.unsafeRun()
    }

    private func supportedFiletypes(_ supportedFiletypes: Filetype, filter: PathFilter) -> (String) -> IO<[String]> {
        return { path in
            guard let paths = try? FileManager.default
                .subpathsOfDirectory(atPath: path)
                .filter(
                  noneOf(filter.query)
                    .intersect(
                      other: anyOf(
                        supportedFiletypes
                          .elements()
                          .map { $0.predicate }
                      )
                    ).contains
                )
            else { return IO { [] } }
            return IO { paths }
        }
    }

    private func fileData(from path: String) -> IO<String.SubSequence> {
        guard let file = try? String(contentsOfFile: testPath + "/" + path, encoding: .ascii)[...]
        else { return IO { "" } }
        return IO { file }
    }

    private func createFileInfo(_ path: String) -> IO<Sourcefile> {
        fileData(from: path).map { data in
            let fileUrl = URL(fileURLWithPath: path)
            let filetype = Filetype(extension: fileUrl.pathExtension)
            let filename = fileUrl.lastPathComponent
            return Sourcefile(path: fileUrl.relativePath, name: filename, data: data, filetype: filetype)
        }
    }
}
