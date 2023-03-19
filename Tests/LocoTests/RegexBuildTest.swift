@testable import loco
import XCTest

class RegexBuilderTesst: XCTestCase {

    func testBuildRegex() {
        let result = RegexPattern.buildSourceRegex([
            "\\.navigationTitle",
            "Label",
            "Text",
            "NSLocalizedString",
            "String\\(localized:"
        ])
        let expected = #"^[^\n\/]*(\.navigationTitle\(|Label\(|Text\(|NSLocalizedString\(|String\(localized:)\s*?(\"\S+\")"#
        XCTAssertEqual(result, expected)
    }
}
