//
//  ConsoleColor.swift
//  pinfo
//
//  Created by Mikael Konradsson on 2021-03-10.
//

import Foundation

enum TerminalFontStyle: String {
    case bold = "\u{001B}[0;1m"
    case dim = "\u{001B}[0;2m"
    case italic = "\u{001B}[0;3m"
    case underline = "\u{001B}[0;4m"
    case inverse = "\u{001B}[0;7m"
    case strike = "\u{001B}[0;9m"
    case hidden = "\u{001B}[0;8m"
}

enum TerminalColor: Int {
    case warningColor = 203
    case keyColor = 37
    case structColor = 38
    case enumColor = 204
    case interfaceColor = 214
    case functionColor = 248
    case fileColor = 231
    case white = 15
    case accentColor = 35
    case barColor = 39
}

func generateLineColor(textColor: TerminalColor, backgroundColor: TerminalColor) -> String {
    "\u{001B}[38;5;\(textColor.rawValue);48;5;\(backgroundColor.rawValue)m"
}

func generateLineColor(textColor: TerminalColor) -> String {
    "\u{001B}[38;5;\(textColor.rawValue);m"
}

private let resetStyle: String = "\u{001B}[0m"

extension String {

    @discardableResult
    func textColor(_ color: TerminalColor) -> Self {
        generateLineColor(textColor: color) + self + resetStyle
    }

    @discardableResult
    func background(color: TerminalColor, textColor: TerminalColor) -> Self {
        generateLineColor(textColor: textColor, backgroundColor: color) + self + resetStyle
    }

    @discardableResult
    func fontStyle(_ style: TerminalFontStyle, endingStyle: Bool = true) -> Self {
        endingStyle
            ? style.rawValue + self + resetStyle
            : style.rawValue + self
    }
}

enum Console {

    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        return formatter
    }()

    static func output(_ text: String, color: TerminalColor, lineWidth: Int) {
        guard text.count > 0
        else { return }

        let extraSpace = lineWidth - text.count
        let spacer = String(repeating: " ", count: extraSpace)
        print("\(text + spacer)".background(color: .barColor, textColor: color))
    }

    static func output(_ title: String, data: Int, color: TerminalColor, width: Int) {

        guard title.count > 0, data > 0, let dataStr = formatter.string(from: NSNumber(integerLiteral: data))
        else { return }

        let extraSpace = width - (title.count + dataStr.count)

        let space = String(repeating: " ", count: extraSpace)
        print(title + space + dataStr.textColor(color))
    }

    static func output(_ title: String, text: String, color: TerminalColor, width: Int) {

        guard title.count > 0
        else { return }

        let extraSpace = width - (title.count + text.count)

        let space = String(repeating: " ", count: extraSpace)
        print(title + space + text.textColor(color))
    }

    static func output(_ title: String, text: String, color: TerminalColor) {

        guard title.count > 0
        else { return }
        print(title + text.textColor(color))
    }

    static func output(text: String, color: TerminalColor) {

        guard text.count > 0
        else { return }
        print(text.textColor(color))
    }
}

