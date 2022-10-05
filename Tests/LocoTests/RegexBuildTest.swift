import XCTest
@testable import Loco

class RegexBuilderTesst: XCTestCase {

    func testBuildRegex() {
        let result = RegexPattern.buildSourceRegex([
                                        "\\.navigationTitle",
                                        "Label",
                                        "Text",
                                        "NSLocalizedString",
                                        "String\\(localized:"
                                      ]
        )
        let expected = #"[^\w?](\.navigationTitle\(|Label\(|Text\(|NSLocalizedString\(|String\(localized:)\s*?(\".*?\")"#
        XCTAssertEqual(result, expected)
    }
}
