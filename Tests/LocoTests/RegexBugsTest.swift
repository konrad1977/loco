//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2023-03-20.
//

import Foundation
@testable import loco
import XCTest


class RegexBugsTest: XCTestCase {

    func testBugsRegex() {
        let data = """
        "absence.edit_details_instructions" : "absence.details_instructions"
        MyLocalizedString("messenger.revoke_access") : MyLocalizedString("messenger.promote")
        let key = isOn ? "news_pin_success" : "news_unpin_success"
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
        
        let source = SourceFile(
            path: "/mocked",
            name: "File.swift",
            data: String(data[...]),
            filetype: .swift
        )
        
        let builder = LocoDataBuilder()
        let result = builder.exctractUsing(
            regex: RegexPattern.allStrings,
            sourceFile: source
        )
        .unsafeRun()
        XCTAssertEqual(result.count, 0)
    }
}
