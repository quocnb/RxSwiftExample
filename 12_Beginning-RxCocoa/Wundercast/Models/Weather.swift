//
//  Weather.swift
//  Wundercast
//
//  Created by Quoc Nguyen on 2018/10/10.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation

struct Weather {
    let cityName: String
    let temperature: Int
    let humidity: Int
    let icon: String

    static let empty = Weather(
        cityName: "N/A",
        temperature: -1000,
        humidity: 0,
        icon: iconNameToChar(icon: "e")
    )
}
