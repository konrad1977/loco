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
          NSLocalizedString("Something", comment: "A comment")
          Text("SomeText")
          Label("Someother Text")
          String(localized: "More text")
        """

        let sourcefile = SourceFile(
          path: "/mocked",
          name: "File.swift",
          data: data[...],
          filetype: .swift
        )
        
        let result = builder.gatherFrom(regex: .querySourceCode, sourceFile: sourcefile).unsafeRun()
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].lineNumber, 1)
        XCTAssertEqual(result[1].lineNumber, 2)
        XCTAssertEqual(result[2].lineNumber, 4)

        XCTAssertEqual(result[0].keys[1], "\"Something\"")
        XCTAssertEqual(result[1].keys[1], "\"SomeText\"")
        XCTAssertEqual(result[2].keys[1], "\"More text\"")
    }
}
