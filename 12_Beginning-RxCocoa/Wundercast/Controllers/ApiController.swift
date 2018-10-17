/*
 * Copyright (c) 2014-2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON

class ApiController {

    /// The shared instance
    static var shared = ApiController()

    /// The api key to communicate with openweathermap.org
    /// Create you own on https://home.openweathermap.org/users/sign_up
    private let apiKey = "5b0afdc348787659e01e0b959f8d9175"

    /// API base URL
    let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!

    init() {
        Logging.URLRequests = { request in
            return true
        }
    }

    //MARK: - Api Calls

    func currentWeather(city: String) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("q", city)])
            .map { (json) -> Weather in
                return Weather(
                    cityName: json["name"].string ?? "Unknown",
                    temperature: json["main"]["temp"].int ?? -1000,
                    humidity: json["main"]["humidity"].int  ?? 0,
                    icon: iconNameToChar(icon: json["weather"][0]["icon"].string ?? "e")
                )
        }
    }

    //MARK: - Private Methods

    /**
     * Private method to build a request with RxCocoa
     */
    private func buildRequest(method: String = "GET", pathComponent: String, params: [(String, String)]) -> Observable<JSON> {

        let url = baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "appid", value: apiKey)
        let unitsQueryItem = URLQueryItem(name: "units", value: "metric")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!

        if method == "GET" {
            var queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            queryItems.append(keyQueryItem)
            queryItems.append(unitsQueryItem)
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems = [keyQueryItem, unitsQueryItem]

            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }

        request.url = urlComponents.url!
        request.httpMethod = method

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared

        return session.rx.data(request: request).map { try! JSON(data: $0) }
    }

}
