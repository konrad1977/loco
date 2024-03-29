import Foundation
import Funswift

struct LocoDataBuilder {

    // swiftlint:disable large_tuple
    func sourceFiles(
        from startPath: String,
        filter: PathFilter = .custom(["Build"])
    ) -> IO<([LocalizationGroup], [LocalizableData], [LocalizationError])> {
        zip(
            IO.pure(startPath)
                .flatMap(
                    supportedFiletypes(.localizable, filter: filter)
                        >=> buildLocalizablePaths
                        >=> fetchLocalizationLanguage
                        >=> buildLocalizationGroups
                ),
            IO.pure(startPath)
                .flatMap(
                    supportedFiletypes([.swift], filter: filter)
                        >=> buildSourcePaths
                        >=> flattenSourceData
                ),
            IO.pure(startPath)
                .flatMap(
                    supportedFiletypes(.localizable, filter: filter)
                        >=> buildMissingSemicolonErrors
                        >=> flattenErrors
                )
        )
    }

    // swiftlint:disable large_tuple
    func buildData(for file: String,
                   filter: PathFilter = .custom(["Build"])
    ) -> IO<([LocalizationGroup], [LocalizableData], [LocalizationError])> {
        zip(
            IO.pure(findProjectRoot(filePath: file).unsafeRun())
                .flatMap(
                    supportedFiletypes(.localizable, filter: filter)
                        >=> buildLocalizablePaths
                        >=> fetchLocalizationLanguage
                        >=> buildLocalizationGroups
                ),
            IO { [file] }
                .flatMap(buildSourcePaths >=> flattenSourceData),
            IO.pure([])
        )
    }
}

// MARK: - Privates
extension LocoDataBuilder {

    private static func run<T>(io: IO<T>) -> T {
        io.unsafeRun()
    }

    private func findProjectRoot(filePath: String) -> IO<String> {
        IO {
            var path = filePath
            repeat {
                path = goUpADirectory(from: path).unsafeRun()
            } while isRoot(path: path) == false
            return path
        }
    }

    private func isRoot(path: String) -> Bool {
        (try? FileManager.default.contentsOfDirectory(atPath: path).contains(".git")) ?? false
    }

    private func goUpADirectory(from path: String) -> IO<String> {
        IO { URL(fileURLWithPath: path).pathComponents.dropLast().joined(separator: "/") }
    }

    private func buildMissingSemicolonErrors(_ paths: [String]) -> IO<[[LocalizationError]]> {
        IO { paths.map(createFileInfo >=> gatherLocalizedErrors(.missingSemicolon) >>> LocoDataBuilder.run) }
    }

    private func buildLocalizablePaths(_ paths: [String]) -> IO<[LocalizableData]> {
        IO { paths.map(createFileInfo >=> gatherLocalizedData(.extractKeyAndValue) >>> LocoDataBuilder.run) }
    }

    private func buildSourcePaths(_ paths: [String]) -> IO<[LocalizableData]> {
        IO { paths.map(
            createFileInfo >=>
                gatherSourceFileData(
                    [
                        .querySourceCode(regex: RegexPattern.sourceRegex),
                        RegexPattern.swiftgen
                    ],
                    allStringsRegex: RegexPattern.allStrings
                ) >>> LocoDataBuilder.run)
        }
    }

    private func flattenSourceData(_ files: [LocalizableData]) -> IO<[LocalizableData]> {
        IO { files.compactMap(identity).filter { $0.data.isEmpty == false || $0.restData.isEmpty == false } }
    }

    private func flattenErrors(_ errors: [[LocalizationError]]) -> IO<[LocalizationError]> {
        IO { errors.flatMap(identity) }
    }

    private func fetchLocalizationLanguage(_ localeData: [LocalizableData]) -> IO<[LocalizableData]> {
        IO {
            localeData.map {
                LocalizableData(
                    path: $0.path,
                    filename: $0.filename,
                    filetype: $0.filetype,
                    data: $0.data,
                    locale: fetchLocaleData($0.path)
                )
            }
        }
    }

    private func buildLocalizationGroups(_ files: [LocalizableData]) -> IO<[LocalizationGroup]> {
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
            .filter { $0.filename.contains("InfoPlist") == false }

            return Dictionary(grouping: sorted) { item in
                item.filename + item.pathComponents
                    .dropLast(2)
                    .joined() // Drop the language to group them togheter
            }.map { (_, value: [LocalizableData]) in
                LocalizationGroup(files: value)
            }
        }
    }

    private func gatherLocalizedData(_ pattern: RegexPattern) -> (SourceFile) -> IO<LocalizableData> {
        { sourceFile in
            IO {
                let entries = exctractUsing(regex: pattern, sourceFile: sourceFile)
                    .map { values in values.map { LocalizeEntry(path: sourceFile.path, key: $0.keys.first ?? "", data: $0.keys.last ?? "", lineNumber: $0.lineNumber) } }
                    .unsafeRun()
                return LocalizableData(path: sourceFile.path, filename: sourceFile.name, filetype: sourceFile.filetype, data: entries)
            }
        }
    }

    private func gatherSourceFileData(_ patterns: [RegexPattern], allStringsRegex: RegexPattern) -> (SourceFile) -> IO<LocalizableData> {
        { sourceFile in
            IO {
                var keyEntries = [LocalizeEntry]()
                for pattern in patterns {
                    let result = exctractUsing(regex: pattern, sourceFile: sourceFile)
                        .map { values in values.map {
                                LocalizeEntry(path: sourceFile.path, key: $0.keys.last ?? "", lineNumber: $0.lineNumber)
                            }
                        }
                        .unsafeRun()
                    keyEntries += result
                }

                let restKeys = exctractUsing(regex: allStringsRegex, sourceFile: sourceFile)
                    .map { values in values.map { LocalizeEntry(path: sourceFile.path, key: $0.keys.last ?? "", lineNumber: $0.lineNumber) } }
                    .unsafeRun()
                    .filter { keyEntries.contains($0) == false }

                return LocalizableData(path: sourceFile.path, filename: sourceFile.name, filetype: sourceFile.filetype, data: keyEntries, restData: restKeys)
            }
        }
    }

    private func gatherLocalizedErrors(_ pattern: RegexPattern) -> (SourceFile) -> IO<[LocalizationError]> {
        { sourceFile in
            exctractUsing(regex: pattern, sourceFile: sourceFile)
                .map { values in values.map { .missingSemicolon(path: sourceFile.path, lineNumber: $0.lineNumber) } }
        }
    }

    private func supportedFiletypes(_ supportedFiletypes: FileType, filter: PathFilter) -> (String) -> IO<[String]> {
        { path in
            guard let paths = try? FileManager.default
                .subpathsOfDirectory(atPath: path)
                .filter(
                    noneOf(filter.query)
                        .intersect(
                            other: anyOf(
                                supportedFiletypes
                                    .elements()
                                    .map(\.predicate)
                            )
                        ).contains
                )
            else { return IO { [] } }
            return IO { paths }
        }
    }

    private func fileData(from path: String) -> IO<String> {
        IO {
            guard let file = try? String(contentsOfFile: path, encoding: .utf8)
            else { return "" }
            return file
        }
    }

    private func createFileInfo(_ path: String) -> IO<SourceFile> {
        fileData(from: path).map { data in
            let fileUrl = URL(fileURLWithPath: path)
            let filetype = FileType(fileExtension: fileUrl.pathExtension)
            return SourceFile(path: fileUrl.standardizedFileURL.path, name: fileUrl.lastPathComponent, data: data, filetype: filetype)
        }
    }
}

extension LocoDataBuilder {

    func fetchLocaleData(_ path: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: RegexPattern.extractLocaleFromPath.regex, options: [])
        else { return "" }

        return regex.matches(
            in: path,
            options: [],
            range: NSRange(location: 0, length: path.count)
        )
        .compactMap { match in
            guard let range = Range(match.range(at: 1), in: path)
            else { return nil }
            return String(path[range])
        }.first ?? ""
    }

    func exctractUsing(regex pattern: RegexPattern, sourceFile: SourceFile) -> IO<[SourceValues]> {
        IO {
            guard let regex = try? NSRegularExpression(
                pattern: pattern.regex,
                options: [
                    .anchorsMatchLines,
                    .allowCommentsAndWhitespace
                ]
            )
            else { return [] }

            let data = sourceFile.data
            let matches: [SourceValues] = regex.matches(
                in: data,
                options: [],
                range: NSRange(location: 0, length: data.count)
            )
            .map { match in
                let matches: [String] = (1 ..< match.numberOfRanges).compactMap { rangeIndex in
                    guard let range = Range(match.range(at: rangeIndex), in: data)
                    else { return nil }
                    return String(data[range])
                }
                let lineNumber = data.countLines(upTo: match.range(at: 0))
                return SourceValues(lineNumber: lineNumber, keys: matches)
            }
            return matches
        }
    }
}
