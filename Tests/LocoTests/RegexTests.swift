import XCTest
@testable import loco

class RegexTests: XCTestCase {

    var builder: LocoDataBuilder!
    var sourcefile: SourceFile!

    override func setUp() {
        super.setUp()
        builder = LocoDataBuilder()
        setupData()
    }
    
    private func setupData() {
        let data = """
          NSLocalizedString(
            "NSLocalizedString", comment: "A comment"
          )
          Text("")
          Text("Text")
          Label("Label")
          String(localized:
           "String.Localalized")
           let name = L10n.tr("Localization", "Part.name", fallback: "This is a fallback")
           // let name = L10n.tr("Localization", "Part.iscommented_out", fallback: "This is a fallback")
           // String(localized: "Hello world") 
        """
        
        sourcefile = SourceFile(
            path: "/mocked",
            name: "File.swift",
            data: String(data[...]),
            filetype: .swift
        )
    }

    func testParseLocalePathData() {
        let path = "/SomePath/en-EN.lproj"
        let result = builder.fetchLocaleData(path)
        XCTAssertEqual(result, "en-EN")
    }

    func testSourceFile() {
        let result = builder.exctractUsing(
            regex: .querySourceCode(regex: RegexPattern.sourceRegex),
            sourceFile: sourcefile
        )
        .unsafeRun()

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].lineNumber, 1)
        XCTAssertEqual(result[1].lineNumber, 5)
        XCTAssertEqual(result[2].lineNumber, 6)
        XCTAssertEqual(result[3].lineNumber, 7)

        XCTAssertEqual(result[0].keys[1], "\"NSLocalizedString\"")
        XCTAssertEqual(result[1].keys[1], "\"Text\"")
        XCTAssertEqual(result[2].keys[1], "\"Label\"")
        XCTAssertEqual(result[3].keys[1], "\"String.Localalized\"")
    }
    
    func testSwiftGenData() {
        let result = builder.exctractUsing(regex: .swiftgen, sourceFile: sourcefile).unsafeRun()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].lineNumber, 9)
        XCTAssertEqual(result[0].keys[0], "\"Part.name\"")
    }
}
