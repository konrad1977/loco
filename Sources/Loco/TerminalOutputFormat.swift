//
//  File.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-16.
//

import Foundation

protocol TerminalOutputFormat: CustomStringConvertible {
    var path: String { get }
}
