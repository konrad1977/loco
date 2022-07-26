import Foundation
import Funswift

runApp(args: CommandLine.arguments)

private func runApp(args: [String]) {
    
    TimeCalculator.run {
        LocoAnalyzer(args: args)
          .analyze(io:
                     LocoDataBuilder()
                     .sourceFiles(
                       from: FileManager.default.currentDirectoryPath,
                       filter: .custom(["build"])
                     )
          )
    }
      .flatMap(Rounding.decimals(2) >=> printTime)
      .unsafeRun()
}


func printTime(_ value: Double) -> IO<Void> {
    IO { print("Total time: " + "\(value)".textColor(.accentColor) + " seconds") }
}
