import Foundation
import Funswift

LocoAnalyzer()
    .analyze(io:
    LocoDataBuilder()
        .sourceFiles(
            from: FileManager.default.currentDirectoryPath,
            filter: .custom(["build"])
        )
).unsafeRun()






