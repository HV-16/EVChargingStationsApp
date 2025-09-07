//
//  Double+Extensions.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

extension Double {
    var cleanString: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(self)
        }
    }
}
