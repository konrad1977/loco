import Foundation

enum TerminalText {

    // MARK: - Internal Types

    // MARK: - Terminal Styles

    enum FontStyle: String {
        case bold = "\u{001B}[0;1m"
        case dim = "\u{001B}[0;2m"
        case italic = "\u{001B}[0;3m"
        case underline = "\u{001B}[0;4m"
        case inverse = "\u{001B}[0;7m"
        case strike = "\u{001B}[0;9m"
        case hidden = "\u{001B}[0;8m"
    }

    enum Colors: Int {
        case warningColor = 3
        case errorColor = 203
        case keyColor = 36
        case infoColor = 2
        case accentColor = 35
        case barColor = 39
    }

    // MARK: Internal Properties

    static let resetStyle: String = "\u{001B}[0m"

    // MARK: - Internal Methods

    static func generateLineColor(textColor: Colors, backgroundColor: Colors) -> String {
        "\u{001B}[38;5;\(textColor.rawValue);48;5;\(backgroundColor.rawValue)m"
    }

    static func generateLineColor(textColor: Colors) -> String {
        "\u{001B}[38;5;\(textColor.rawValue);m"
    }

}

// MARK: - Extension String

extension String {

    @discardableResult
    func textColor(_ color: TerminalText.Colors) -> Self {
        TerminalText.generateLineColor(textColor: color) + self + TerminalText.resetStyle
    }

    @discardableResult
    func background(color: TerminalText.Colors, textColor: TerminalText.Colors) -> Self {
        TerminalText.generateLineColor(textColor: textColor, backgroundColor: color) + self + TerminalText.resetStyle
    }

    @discardableResult
    func fontStyle(_ style: TerminalText.FontStyle, endingStyle: Bool = true) -> Self {
        endingStyle
        ? style.rawValue + self + TerminalText.resetStyle
        : style.rawValue + self
    }

}
