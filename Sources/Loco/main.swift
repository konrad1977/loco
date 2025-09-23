import Foundation
import Funswift

runApp(args: CommandLine.arguments)

private func runApp(args: [String]) {
    let helpRequested = Parser(keyword: "--help", args: args).hasArgument() || 
                       Parser(keyword: "-h", args: args).hasArgument()
    
    if helpRequested {
        printHelp()
        return
    }
    
    let dryRun = Parser(keyword: "--dry-run", args: args).hasArgument()
    let removeUnused = Parser(keyword: "--remove-unused", args: args).hasArgument()
    
    if dryRun || removeUnused {
        removeUnusedLocalizations(args: args, dryRun: dryRun)
    } else if let filePath = Parser(keyword: "-f", args: args).value() {
        lintFile(file: filePath, args: args)
    } else {
        lintProject(args: args)
    }
}

private func lintProject(args: [String]) {
    TimeCalculator.run {
        LocoAnalyzer(args: args)
          .analyze(io:
            LocoDataBuilder()
            .sourceFiles(
              from: FileManager.default.currentDirectoryPath
            )
        )
    }
    .flatMap(Rounding.decimals(2) >=> printTime)
    .unsafeRun()
}

private func lintFile(file: String, args: [String]) {
    TimeCalculator.run {
        LocoAnalyzer(args: args)
          .analyze(io:
            LocoDataBuilder()
            .buildData(for: file)
        )
    }
    .flatMap(Rounding.decimals(2) >=> printTime)
    .unsafeRun()
}

private func removeUnusedLocalizations(args: [String], dryRun: Bool) {
    TimeCalculator.run {
        UnusedLocalizationRemover(args: args, dryRun: dryRun)
            .process(io:
                LocoDataBuilder()
                .sourceFiles(
                    from: FileManager.default.currentDirectoryPath
                )
            )
    }
    .flatMap(Rounding.decimals(2) >=> printTime)
    .unsafeRun()
}

private func printHelp() {
    print("""
    Loco - Localization Linter
    
    USAGE:
        loco [OPTIONS]
    
    OPTIONS:
        -h, --help           Show this help message and exit
        -f <path>            Lint a specific Swift file
        --color              Enable colored output
        --dry-run            Preview changes without modifying files (remove unused localizations)
        --remove-unused      Remove unused localizations from .strings files
    
    EXAMPLES:
        loco                              Lint entire project
        loco -f path/to/file.swift        Lint specific file
        loco --color                      Lint with colored output
        loco --dry-run                    Preview unused localizations
        loco --remove-unused              Remove unused localizations
        loco --remove-unused --dry-run   Preview removal without changes
    
    For more information, visit: https://github.com/konrad1977/loco
    """)
}

func printTime(_ value: Double) -> IO<Void> {
    IO { print("Total time: " + "\(value)".textColor(.accentColor) + " seconds") }
}
