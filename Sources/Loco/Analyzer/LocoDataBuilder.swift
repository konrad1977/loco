import Foundation
import Funswift

extension RangeExpression where Bound == String.Index  {
    func nsRange<S: StringProtocol>(in string: S) -> NSRange { .init(self, in: string) }
}

public struct LocoDataBuilder {

    let pattern = #"("[^\"]+")\s+=\s+\"[^\"]+\""#
    let sourcePattern = #"(Text\(|NSLocalizedString\(\s*?|String\(localized:\s?)(\".*?\")"#
    public init() {}
}

extension LocoDataBuilder {

    public func sourceFiles(
        from startPath: String,
        filter: PathFilter = .custom(["Build"])
    ) -> IO<([LocalizationGroup], [LocalizeableData])> {
        zip(
            IO.pure(startPath)
                .flatMap(
                    supportedFiletypes(.localizeable, filter: filter)
                    >=> buildLocalizeablePaths
                    >=> buildLocalizationGroups
            ),
            IO.pure(startPath)
                .flatMap(
                    supportedFiletypes([.swift], filter: filter)
                    >=> buildSourcePaths
                    >=> flattenSourceData
            )
        )
    }

//    private func checkLocalizationGroups(_ groups: [LocalizationGroup]) -> IO<[(LocalizationError, [String])]> {
//        IO { groups.compactMap(checkLocalizationGroup >>> LocoAnalyzer.run) }
//    }

//    private func checkLocalizationGroup(_ group: LocalizationGroup) -> IO<(LocalizationError, [String])> {
//        IO {
//            let groupErrors = group
//                .files
//                .map(checkForDuplicates >>> LocoAnalyzer.run)
//                .filter { $0 != .none }
//            return (LocalizationError(errors: groupErrors), group.files.flatMap { $0.data })
//        }
//    }

    private func buildLocalizeablePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherRegexData(pattern, groupIndex: 1) >>> LocoDataBuilder.run) }
    }

    private func buildSourcePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherRegexData(sourcePattern, groupIndex: 2) >>> LocoDataBuilder.run) }
    }

    private func flattenSourceData(_ files: [LocalizeableData]) -> IO<[LocalizeableData]> {
        IO { files.compactMap { $0 }.filter { $0.data.isEmpty == false } }
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



    private func gatherRegexData(_ pattern: String, groupIndex: Int) -> (Sourcefile) -> IO<LocalizeableData> {
        return { sourcefile in
            IO {
                do {
                    let data = String(sourcefile.data)
                    let range = NSRange(data.startIndex..<data.endIndex,
                                          in: data)

                    let regex = try NSRegularExpression(pattern: pattern, options: [])
                    var entries: [LocalizeEntry] = []
                    regex.enumerateMatches(in: data, range: range) { (match, _, _) in

                        guard let match = match, let range = Range(match.range(at: groupIndex), in: data)
                        else { return }
                        let subStrmatch = String(data[range])

                        do {
                            let regex = try NSRegularExpression(pattern: "\n", options: [])
                            let subRange = range.nsRange(in: subStrmatch)
                            let lineNumber = regex.numberOfMatches(in: data, range: NSMakeRange(0, subRange.location)) + 1
                            entries.append(LocalizeEntry(path: sourcefile.path, data: subStrmatch, lineNumber: lineNumber))
                        } catch {
                            entries.append(LocalizeEntry(path: sourcefile.path, data: subStrmatch, lineNumber: 0))
                        }
                    }
                    return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
                } catch {
                    return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: [])
                }
            }
        }
    }
}

// MARK: - Privates
extension LocoDataBuilder {
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
        guard let file = try? String(contentsOfFile: path, encoding: .ascii)[...]
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
