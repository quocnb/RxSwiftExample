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

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!

    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        style()

        // MARK: - GEO SEARCH
        locationManager.delegate = self

        let geoInput = geoLocationButton.rx.tap.do(onNext: { _ in
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.requestLocation()
        })

        let currentLocation = locationManager.rx.didUpdateLocations.map { (locations) in
            return locations[0]
        }

        locationManager.rx.didGetLocationFail.subscribe(onNext: { error in
            print("Did fail with error", error.localizedDescription)
        }).disposed(by: rx.disposeBag)

        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }

        let geoSearch = geoLocation.flatMap { (location) in
            ApiController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }

        // MARK: - MAP VIEW
        mapView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        mapButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.mapView.isHidden = !self.mapView.isHidden
        }).disposed(by: rx.disposeBag)
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        let mapSearch = mapInput.flatMap { (coor) in
            return ApiController.shared.currentWeather(lat: coor.latitude, lon: coor.longitude).catchErrorJustReturn(ApiController.Weather.dummy)
        }
        // MARK: - TEXT SEARCH
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }

        let textSearch = searchInput
            .flatMap { text in
                return ApiController.shared.currentWeather(city: text ?? "Error")
                    .catchErrorJustReturn(ApiController.Weather.dummy)
            }

        let search = Observable.from([
            geoSearch,
            textSearch,
            mapSearch
        ])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.dummy)

        search.map { "\($0.temperature)° C" }
            .drive(tempLabel.rx.text)
            .disposed(by: rx.disposeBag)

        search.map { $0.icon }
            .drive(iconLabel.rx.text)
            .disposed(by: rx.disposeBag)

        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: rx.disposeBag)

        search.map { $0.cityName }
            .drive(cityNameLabel.rx.text)
            .disposed(by: rx.disposeBag)

        search.map {[$0.overlay()]}
            .drive(mapView.rx.overlays)
            .disposed(by: rx.disposeBag)

        let running = Observable.from([
            searchInput.map {_ in return true},
            geoInput.map {_ in return true},
            mapInput.map {_ in return true},
            search.map {_ in return false}.asObservable()
            ]).merge()
            .asDriver(onErrorJustReturn: false)

        running.drive(activityIndicator.rx.isAnimating)
            .disposed(by: rx.disposeBag)
        running.drive(iconLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
        running.drive(tempLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
        running.drive(cityNameLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
        running.drive(humidityLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        Appearance.applyBottomLine(to: searchCityName)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Style

    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ApiController.Weather.Overlay {
            let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
