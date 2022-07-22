import Foundation
import Funswift

func printTime(_ value: Double) -> IO<Void> {
    IO { print("Total time: " + "\(value)".textColor(.accentColor) + " seconds") }
}

TimeCalculator.run {
    LocoAnalyzer()
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





