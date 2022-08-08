import XCTest
@testable import Loco

class RegexBuilderTesst: XCTestCase {

    func buildSourceRegex(_ list: [String]) -> String {
        return #"[^\w?]("# + list.joined(separator: "\\(|") + #")\s*?(\".*?\")"#
    }

    func testBuildRegex() {
        let result = buildSourceRegex([
                                        "\\.navigationTitle",
                                        "Label",
                                        "Text",
                                        "NSLocalizedString",
                                        "String\\(localized:"
                                      ]
        )
        let expected = #"[^\w?](\.navigationTitle\(|Label\(|Text\(|NSLocalizedString\(|String\(localized:)\s*?(\".*?\")"#
        print(result)
        print(expected)
        XCTAssertEqual(result, expected)
    }
}

