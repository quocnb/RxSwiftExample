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

class ViewController: UIViewController {

    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        style()
//        normalProcess()
//        bindProcess()
        driveProcess()
    }

    func normalProcess() {
//        searchCityName.rx.text
        searchCityName.rx.controlEvent(UIControlEvents.editingDidEndOnExit).map {self.searchCityName.text}
            .filter {($0 ?? "").count > 0}
            .flatMap {
                return ApiController.shared.currentWeather(city: $0 ?? "Error")
                    .catchErrorJustReturn(Weather.empty)
            }.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] data in
                guard let `self` = self else {
                    return
                }
                self.tempLabel.text = "\(data.temperature)° C"
                self.iconLabel.text = data.icon
                self.humidityLabel.text = "\(data.humidity)%"
                self.cityNameLabel.text = data.cityName
            }).disposed(by: rx.disposeBag)
    }

    func bindProcess() {
//        let search = searchCityName.rx.text
        let search = searchCityName.rx.controlEvent(.editingDidEndOnExit).map {self.searchCityName.text}
            .filter { $0.notEmpty }
            .flatMapLatest {
                return ApiController.shared.currentWeather(city: $0 ?? "Error")
                    .catchErrorJustReturn(Weather.empty)
            }
            .share(replay: 1, scope: SubjectLifetimeScope.whileConnected)
            .observeOn(MainScheduler.instance)
        search.map {"\($0.temperature)°C"}.bind(to: self.tempLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {$0.icon}.bind(to: self.iconLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {$0.cityName}.bind(to: self.cityNameLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {"\($0.humidity)%"}.bind(to: self.humidityLabel.rx.text).disposed(by: rx.disposeBag)
    }

    func driveProcess() {
        let search = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable().map {self.searchCityName.text}
            .filter { $0.notEmpty }
            .flatMapLatest {
                return ApiController.shared.currentWeather(city: $0 ?? "Error").catchErrorJustReturn(Weather.empty)
            }.asDriver(onErrorJustReturn: Weather.empty)
        search.map {"\($0.temperature)°C"}.drive(self.tempLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {$0.icon}.drive(self.iconLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {$0.cityName}.drive(self.cityNameLabel.rx.text).disposed(by: rx.disposeBag)
        search.map {"\($0.humidity)%"}.drive(self.humidityLabel.rx.text).disposed(by: rx.disposeBag)
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

    private func updateViews(with weather: Weather) {
        DispatchQueue.main.async {
            self.tempLabel.text = "\(weather.temperature)° C"
            self.iconLabel.text = weather.icon
            self.humidityLabel.text = "\(weather.humidity)%"
            self.cityNameLabel.text = weather.cityName
        }
    }
}
