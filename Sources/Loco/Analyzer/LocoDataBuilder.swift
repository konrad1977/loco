import Foundation
import Funswift

public struct LocoDataBuilder {
    let localizePattern = #"("[^\"]+")\s+=\s+\"([^\"]?)\""#
    let sourcePattern = #"([^\w?]Text\(|[^\w?]NSLocalizedString\(\s*?|String\(localized:\s?)(\".*?\")"#
    let localePathData = #"(\w{2}-\w{2})\.lproj"#
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
                    >=> fetchLocalizationLanguage
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

	public func buildData(for file: String,
						 filter: PathFilter = .custom(["Build"])
	) -> IO<([LocalizationGroup], [LocalizeableData])> {
		zip(
			IO.pure(findProjectRoot(filePath: file).unsafeRun())
				.flatMap(
					supportedFiletypes(.localizeable, filter: filter)
					>=> buildLocalizeablePaths
					>=> fetchLocalizationLanguage
					>=> buildLocalizationGroups
				),
			IO { [file] }
				.flatMap(buildSourcePaths >=> flattenSourceData)
		)
	}
}

// MARK: - Privates
extension LocoDataBuilder {
    private static func run<T>(io: IO<T>) -> T {
        io.unsafeRun()
    }

	public func findProjectRoot(filePath: String) -> IO<String> {
		IO {
			var path = filePath
			repeat {
				path = goUpADirectory(from: path).unsafeRun()
			} while isRoot(path: path) == false
			return path
		}
	}

	private func isRoot(path: String) -> Bool {
		do {
			return try FileManager.default.contentsOfDirectory(atPath: path).contains(".git")
		} catch {
			return false
		}
	}

	private func goUpADirectory(from path: String) -> IO<String> {
		IO {
			URL(fileURLWithPath: path).pathComponents.dropLast().joined(separator: "/")
		}
	}

    private func buildLocalizeablePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherLocalizedData(localizePattern) >>> LocoDataBuilder.run) }
    }

    private func buildSourcePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherRegexData(sourcePattern, groupIndex: 2) >>> LocoDataBuilder.run) }
    }

    private func flattenSourceData(_ files: [LocalizeableData]) -> IO<[LocalizeableData]> {
        IO { files.compactMap { $0 }.filter { $0.data.isEmpty == false } }
    }

    private func fetchLocalizationLanguage(_ localeData: [LocalizeableData]) -> IO<[LocalizeableData]> {
        IO {
            localeData.map { LocalizeableData(
                path: $0.path,
                filename: $0.filename,
                filetype: $0.filetype,
                data: $0.data,
                locale: fetchLocaleData($0.path))
            }
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
            }.filter { $0.filename.contains("InfoPlist") == false }

            return Dictionary(grouping: sorted) { item in
                "\(item.filename)" + (item.pathComponents.dropLast(2).last ?? "")
            }.map { (_, value: [LocalizeableData]) in
                LocalizationGroup(files: value)
            }
        }
    }

	private func fetchLocaleData(_ path: String) -> String {
		guard let regex = try? NSRegularExpression(pattern: localePathData, options: [])
        else { return "" }

		let range = NSRange(path.startIndex..<path.endIndex, in: path)
    	return regex.matches(in: path, options: [], range: range).map { match in
			guard let range = Range(match.range(at: 1), in: path)
            else { return "" }

            return String(path[range])
		}.first ?? ""
	}

	private func gatherLocalizedData(_ pattern: String) -> (Sourcefile) -> IO<LocalizeableData> {
		return { sourcefile in
			IO {
				do {
					let data = String(sourcefile.data)
					let dataNS = data as NSString
					let regex = try NSRegularExpression(pattern: pattern, options: [])

					let entries: [LocalizeEntry] = regex.matches(
						in: data,
						options: [],
						range: NSRange(location: 0, length: dataNS.length)
					).map { match in

						guard
							let keyRange = Range(match.range(at: 1), in: data),
							let wordRange = Range(match.range(at: 2), in: data)
						else { return LocalizeEntry(path: sourcefile.path, key: "", lineNumber: 0) }

						let key = String(data[keyRange])
						let extendedData = String(data[wordRange])
						let lineNumber = data.countLines(upTo: match.range(at: 1))
						return LocalizeEntry(path: sourcefile.path, key: key, data: extendedData, lineNumber: lineNumber)
					}
					return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
				} catch {
					return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: [])
				}
			}
		}
	}

    private func gatherRegexData(_ pattern: String, groupIndex: Int) -> (Sourcefile) -> IO<LocalizeableData> {
        return { sourcefile in
            IO {
                do {
                    let data = String(sourcefile.data)
					let dataNS = data as NSString

                    let regex = try NSRegularExpression(pattern: pattern, options: [])
					let entries: [LocalizeEntry] = regex.matches(
						in: data,
						options: [],
						range: NSRange(location: 0, length: dataNS.length)
					)
					.map { match in

                        guard let range = Range(match.range(at: groupIndex), in: data)
						else { return LocalizeEntry(path: sourcefile.path, key: "", lineNumber: 0) }

                        let subStrmatch = String(data[range])
						let lineNumber = data.countLines(upTo: match.range(at: groupIndex))
						return LocalizeEntry(path: sourcefile.path, key: subStrmatch, lineNumber: lineNumber)
                    }
                    return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
                } catch {
                    return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: [])
                }
            }
        }
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
            return Sourcefile(path: fileUrl.standardizedFileURL.path, name: fileUrl.lastPathComponent, data: data, filetype: filetype)
        }
    }
}
