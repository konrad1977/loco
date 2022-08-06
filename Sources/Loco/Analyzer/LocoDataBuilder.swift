import Foundation
import Funswift

public struct LocoDataBuilder {
    let localizePatternRegex = #"("[^\"]+")\s+=\s+\"([^\"]+)\"\s?;"#
    let sourcePatternRegex = #"([^\w?]Text\(|[^\w?]NSLocalizedString\(\s*?|String\(localized:\s?)(\".*?\")"#
    let localePathDataRegex = #"(\w{2}-\w{2})\.lproj"#
	let missingSemicolonRegex = #"(^\"(?:(?!;).)*$)"#
    public init() {}
}

extension LocoDataBuilder {

    public func sourceFiles(
        from startPath: String,
        filter: PathFilter = .custom(["Build"])
	) -> IO<([LocalizationGroup], [LocalizeableData], [LocalizationError])> {
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
            ),
			IO.pure(startPath)
				.flatMap(
					supportedFiletypes(.localizeable, filter: filter)
					>=> buildMissingSemicolonErrors
					>=> flattenErrors
			)
        )
    }

	public func buildData(for file: String,
						 filter: PathFilter = .custom(["Build"])
	) -> IO<([LocalizationGroup], [LocalizeableData], [LocalizationError])> {
		zip(
			IO.pure(findProjectRoot(filePath: file).unsafeRun())
				.flatMap(
					supportedFiletypes(.localizeable, filter: filter)
					>=> buildLocalizeablePaths
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
		IO { paths.map(createFileInfo >=> gatherLocalizedErrors(missingSemicolonRegex) >>> LocoDataBuilder.run) }
	}

    private func buildLocalizeablePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherLocalizedData(localizePatternRegex) >>> LocoDataBuilder.run) }
    }

    private func buildSourcePaths(_ paths: [String]) -> IO<[LocalizeableData]> {
        IO { paths.map(createFileInfo >=> gatherSourceFileData(sourcePatternRegex) >>> LocoDataBuilder.run) }
    }

    private func flattenSourceData(_ files: [LocalizeableData]) -> IO<[LocalizeableData]> {
        IO { files.compactMap(identity).filter { $0.data.isEmpty == false } }
    }

	private func flattenErrors(_ errors: [[LocalizationError]]) -> IO<[LocalizationError]> {
		IO { errors.flatMap(identity) }
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
		guard let regex = try? NSRegularExpression(pattern: localePathDataRegex, options: [])
        else { return "" }

		let range = NSRange(path.startIndex..<path.endIndex, in: path)
    	return regex.matches(in: path, options: [], range: range).map { match in
			guard let range = Range(match.range(at: 1), in: path)
            else { return "" }

            return String(path[range])
		}.first ?? ""
	}

	private func gatherFrom(regex pattern: String, sourcefile: Sourcefile) -> IO<[SourceValues]> {
		IO {
			guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
			else { return [] }

			let data = String(sourcefile.data)
			let dataNS = data as NSString

			let result: [SourceValues] = regex.matches(
				in: data,
				options: [],
				range: NSRange(location: 0, length: dataNS.length)
			)
			.map { match in
				let lineNumber = data.countLines(upTo: match.range(at: 0))
				var matches: [String] = []
				for rangeIndex in 1..<match.numberOfRanges {
					if let range = Range(match.range(at: rangeIndex), in: data) {
						matches.append(String(data[range]))
					}
				}
				return SourceValues(lineNumber: lineNumber, keys: matches)
			}
			return result
		}
	}

	private func gatherLocalizedData(_ pattern: String) -> (Sourcefile) -> IO<LocalizeableData> {
		return { sourcefile in
			IO {
				let entries = gatherFrom(regex: pattern, sourcefile: sourcefile)
					.map { values in values.map {
                        LocalizeEntry(path: sourcefile.path, key: $0.keys.first ?? "" , data: $0.keys.last ?? "", lineNumber: $0.lineNumber)
					}
				}.unsafeRun()
				return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
			}
		}
	}

    private func gatherSourceFileData(_ pattern: String) -> (Sourcefile) -> IO<LocalizeableData> {
        return { sourcefile in
            IO {
				let entries = gatherFrom(regex: pattern, sourcefile: sourcefile)
					.map { values in values.map {
							LocalizeEntry(path: sourcefile.path, key: $0.keys.last ?? "", lineNumber: $0.lineNumber)
						}
					}.unsafeRun()

				return LocalizeableData(path: sourcefile.path, filename: sourcefile.name, filetype: sourcefile.filetype, data: entries)
            }
        }
    }

	private func gatherLocalizedErrors(_ pattern: String) -> (Sourcefile) -> IO<[LocalizationError]> {
		return { sourcefile in
			IO {
				return gatherFrom(regex: pattern, sourcefile: sourcefile)
					.map { values in values.map {
						.missingSemicolon(path: sourcefile.path, linenumber: $0.lineNumber)
					}
				}.unsafeRun()
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
