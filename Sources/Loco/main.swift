import Foundation
import Funswift

runApp(args: CommandLine.arguments)

private func runApp(args: [String]) {
    if let filePath = Parser(keyword: "-f", args: args).value() {
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

func printTime(_ value: Double) -> IO<Void> {
    IO { print("Total time: " + "\(value)".textColor(.accentColor) + " seconds") }
}
