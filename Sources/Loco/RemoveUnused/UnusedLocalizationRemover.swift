import Foundation
import Funswift

struct UnusedLocalizationRemover {
    let args: [String]
    let dryRun: Bool
    
    init(args: [String], dryRun: Bool) {
        self.args = args
        self.dryRun = dryRun
    }
    
    func process(io: IO<([LocalizationGroup], [LocalizableData], [LocalizationError])>) -> IO<Void> {
        io.flatMap { groups, sourceFiles, errors in
            let coloredOutput = Parser(keyword: "--color", args: args).hasArgument()
            
            let unusedKeys = findUnusedKeys(groups: groups, sourceFiles: sourceFiles, coloredOutput: coloredOutput)
            
            if dryRun {
                return reportUnusedKeys(unusedKeys, coloredOutput: coloredOutput)
            } else {
                return removeUnusedKeys(unusedKeys, from: groups, coloredOutput: coloredOutput)
            }
        }
    }
    
    private func findUnusedKeys(groups: [LocalizationGroup], sourceFiles: [LocalizableData], coloredOutput: Bool) -> [(file: String, keys: [LocalizeEntry])] {
        var unusedByFile: [(file: String, keys: [LocalizeEntry])] = []
        
        // Include both directly matched keys (data) and all other strings found in code (restData)
        let allUsedKeys = Set(sourceFiles.flatMap { $0.data.map { $0.key } + $0.restData.map { $0.key } })
        
        for group in groups {
            for file in group.files {
                let unusedInFile = file.data.filter { entry in
                    !allUsedKeys.contains(entry.key) && !entry.key.isEmpty
                }
                
                if !unusedInFile.isEmpty {
                    unusedByFile.append((file: file.path, keys: unusedInFile))
                }
            }
        }
        
        return unusedByFile
    }
    
    private func reportUnusedKeys(_ unusedKeys: [(file: String, keys: [LocalizeEntry])], coloredOutput: Bool) -> IO<Void> {
        IO {
            if unusedKeys.isEmpty {
                let message = "✅ No unused localizations found."
                print(coloredOutput ? message.textColor(.infoColor) : message)
                return
            }
            
            let title = "\n🔍 DRY RUN - The following unused localizations would be removed:\n"
            print(coloredOutput ? title.textColor(.warningColor) : title)
            
            var totalCount = 0
            
            for (file, keys) in unusedKeys {
                let fileMsg = "  File: \(file)"
                print(coloredOutput ? fileMsg.textColor(.keyColor) : fileMsg)
                for key in keys {
                    print("    - Line \(key.lineNumber): \"\(key.key)\"")
                    totalCount += 1
                }
                print("")
            }
            
            let totalMsg = "Total unused localizations: \(totalCount)"
            print(coloredOutput ? totalMsg.textColor(.warningColor) : totalMsg)
            let instructionMsg = "\nTo actually remove these, run with --remove-unused flag (without --dry-run)"
            print(coloredOutput ? instructionMsg.textColor(.infoColor) : instructionMsg)
        }
    }
    
    private func removeUnusedKeys(_ unusedKeys: [(file: String, keys: [LocalizeEntry])], from groups: [LocalizationGroup], coloredOutput: Bool) -> IO<Void> {
        var removedCount = 0
        var updatedFiles = 0
        
        return IO {
            for (filePath, keysToRemove) in unusedKeys {
                let keysSet = Set(keysToRemove.map { $0.key })
                
                guard let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) else {
                    let warningMsg = "⚠️  Could not read file: \(filePath)"
                    print(coloredOutput ? warningMsg.textColor(.warningColor) : warningMsg)
                    continue
                }
                
                let lines = fileContent.components(separatedBy: .newlines)
                var newLines: [String] = []
                var removedInFile = 0
                
                for line in lines {
                    var shouldKeep = true
                    
                    for key in keysSet {
                        // Keys already contain quotes, so we need to handle that
                        let cleanKey = key.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        let pattern = "^\"\(NSRegularExpression.escapedPattern(for: cleanKey))\"\\s*="
                        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                           regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) != nil {
                            shouldKeep = false
                            removedInFile += 1
                            break
                        }
                    }
                    
                    if shouldKeep {
                        newLines.append(line)
                    }
                }
                
                if removedInFile > 0 {
                    let newContent = newLines.joined(separator: "\n")
                    
                    do {
                        try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
                        let successMsg = "✅ Removed \(removedInFile) unused localization(s) from: \(filePath)"
                        print(coloredOutput ? successMsg.textColor(.infoColor) : successMsg)
                        removedCount += removedInFile
                        updatedFiles += 1
                    } catch {
                        let errorMsg = "❌ Failed to update file: \(filePath)"
                        print(coloredOutput ? errorMsg.textColor(.errorColor) : errorMsg)
                        print("   Error: \(error)")
                    }
                }
            }
            
            if removedCount > 0 {
                let finalMsg = "\n🎉 Successfully removed \(removedCount) unused localization(s) from \(updatedFiles) file(s)!"
                print(coloredOutput ? finalMsg.textColor(.infoColor) : finalMsg)
            } else {
                let noChangesMsg = "✅ No unused localizations to remove."
                print(coloredOutput ? noChangesMsg.textColor(.infoColor) : noChangesMsg)
            }
        }
    }
}