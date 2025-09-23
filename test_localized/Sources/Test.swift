import Foundation

class TestLocalized {
    func test() {
        let text1: String = "key_somekey".localized
        let text2 = "another_key".localized
        let text3 = "third_key".localized()
    }
}