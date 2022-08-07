//
//  TimeCalculator.swift
//  
//
//  Created by Mikael Konradsson on 2022-07-22.
//

import Foundation
import Funswift

enum TimeCalculator {

    static func run(block: @escaping () -> IO<Void>) -> IO<Double> {
        IO {
            let start = DispatchTime.now()
            block().unsafeRun()
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            return Double(nanoTime) / 1_000_000_000
        }
    }
}

enum Rounding {
    static func decimals(_ places: Double) -> (Double) -> IO<Double> {
        return { value in
            IO<Double> {
                let divisor = pow(10.0, Double(places))
                return (value * divisor).rounded() / divisor
            }
        }
    }
}
