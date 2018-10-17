/*
 * Copyright (c) 2016 Razeware LLC
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

class CategoriesViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    var categories = BehaviorRelay<[EOCategory]>(value: [])
    let indicator = UIActivityIndicatorView(style: .gray)
    let downloadView = DownloadView()

    override func viewDidLoad() {
        super.viewDidLoad()
        startDownload()
        indicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let right = UIBarButtonItem(customView: indicator)
        self.navigationItem.rightBarButtonItem = right
        self.view.addSubview(downloadView)
        view.layoutIfNeeded()
    }

    func startDownload() {
        self.indicator.startAnimating()
        let eoCategories = EONET.categories
        let downloadedEvents = eoCategories.flatMap { categories in
            return Observable.from(categories.map { category in
                EONET.events(forLast: 360, category: category)
            })
        } .merge(maxConcurrent: 2)
        let updatedCategories = eoCategories.flatMap { categories in
            downloadedEvents.scan(categories) { updated, events in
                return updated.map { category in
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                }
            }
        }.do(onCompleted: { [weak self] in
            DispatchQueue.main.async {
                self?.indicator.stopAnimating()
                self?.downloadView.removeFromSuperview()
            }
        })
        eoCategories.flatMap { (categories) in
            return updatedCategories.scan(0, accumulator: { (count, categories) in
                return count + 1
            }).startWith(0).map({($0, categories.count)})
        }.subscribe(onNext: { [weak self] tuples in
            DispatchQueue.main.async {
                let progress = Float(tuples.0) / Float(tuples.1)
                self?.downloadView.progress.progress = progress
                self?.downloadView.label.text = String(format: "Downloading %d%%", Int(progress * 100))
            }
        }).disposed(by: rx.disposeBag)
        eoCategories.concat(updatedCategories)
            .bind(to: self.categories)
            .disposed(by: rx.disposeBag)
        self.categories.asObservable().subscribe(onNext: { [weak self](_) in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }).disposed(by: rx.disposeBag)
    }
}

extension CategoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator
            : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:
        IndexPath) {
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            let eventsController =
                storyboard!.instantiateViewController(withIdentifier: "events") as!
            EventsViewController
            eventsController.title = category.name
            eventsController.events.accept(category.events)
            navigationController!.pushViewController(eventsController, animated:
                true) }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
