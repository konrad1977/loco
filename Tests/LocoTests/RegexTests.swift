import XCTest
@testable import Loco

class RegexTests: XCTestCase {

    var builder: LocoDataBuilder!

    override func setUp() {
        super.setUp()
        builder = LocoDataBuilder()
    }

    func testParseLocalePathData() {
        let path = "/SomePath/en-EN.lproj"
        let result = builder.fetchLocaleData(path)
        XCTAssertEqual(result, "en-EN")
    }

    func testSourceFile() {
        let data = """
          NSLocalizedString(
            "NSLocalizedString", comment: "A comment"
          )
          Text("Text")
          Label("Label")
          String(localized:
           "String.Localalized")
        """

        let sourcefile = SourceFile(
          path: "/mocked",
          name: "File.swift",
          data: data[...],
          filetype: .swift
        )
        
        let result = builder.gatherFrom(regex: .querySourceCode, sourceFile: sourcefile).unsafeRun()
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].lineNumber, 1)
        XCTAssertEqual(result[1].lineNumber, 4)
        XCTAssertEqual(result[2].lineNumber, 5)
        XCTAssertEqual(result[3].lineNumber, 6)

        XCTAssertEqual(result[0].keys[1], "\"NSLocalizedString\"")
        XCTAssertEqual(result[1].keys[1], "\"Text\"")
        XCTAssertEqual(result[2].keys[1], "\"Label\"")
        XCTAssertEqual(result[3].keys[1], "\"String.Localalized\"")
    }
}
